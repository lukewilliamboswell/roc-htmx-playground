(function () {
    "use strict";

    function feedbackFor(event) {
        var detail = event.detail;
        var context = detail && detail.ctx;
        var source = context && context.sourceElement;
        var targetId = source && source.getAttribute("data-network-error-target");

        return targetId ? document.getElementById(targetId) : null;
    }

    function busyRegionFor(event) {
        var detail = event.detail;
        var context = detail && detail.ctx;
        var source = context && context.sourceElement;
        var targetId = source && source.getAttribute("data-busy-target");

        return targetId ? document.getElementById(targetId) : null;
    }

    document.addEventListener("htmx:before:request", function (event) {
        var feedback = feedbackFor(event);
        var previous = feedback && feedback.querySelector("[data-transport-error]");
        var busyRegion = busyRegionFor(event);

        if (previous) {
            previous.remove();
        }
        if (busyRegion) {
            busyRegion.setAttribute("aria-busy", "true");
        }
    });

    document.addEventListener("htmx:finally:request", function (event) {
        var busyRegion = busyRegionFor(event);
        if (busyRegion) {
            busyRegion.setAttribute("aria-busy", "false");
        }

        var detail = event.detail;
        var context = detail && detail.ctx;
        var source = context && context.sourceElement;
        var scannerForm =
            source && source.closest("[data-business-card-form]");
        var scannerSubmit =
            scannerForm &&
            scannerForm.querySelector("[data-business-card-submit]");

        if (scannerSubmit) {
            scannerSubmit.disabled = false;
            scannerSubmit.textContent = "Extract contact details";
        }
    });

    document.addEventListener("htmx:error", function (event) {
        var feedback = feedbackFor(event);
        if (!feedback) {
            return;
        }

        var message = document.createElement("p");
        message.className = "request-transport-error";
        message.setAttribute("role", "alert");
        message.setAttribute("data-transport-error", "");
        message.textContent =
            "We could not confirm whether the change completed. Check the current record before trying again.";
        feedback.replaceChildren(message);
    });

    document.addEventListener("htmx:after:swap", function (event) {
        var detail = event.detail;
        var context = detail && detail.ctx;
        var source = context && context.sourceElement;
        var response = context && context.response;
        var targetId = source && source.getAttribute("data-focus-after-swap");

        if (!targetId || (response && response.status >= 400)) {
            return;
        }

        var target = document.getElementById(targetId);
        if (target) {
            target.focus();
        }
    });

    var businessCardPreviewUrl = null;

    function scannerStatus(form, message, isError) {
        var status = form
            .closest("section")
            .querySelector("#business-card-client-status");

        if (!status) {
            return;
        }

        status.textContent = message;
        status.classList.toggle("business-card-client-error", Boolean(isError));
    }

    function canvasBlob(canvas, quality) {
        return new Promise(function (resolve, reject) {
            canvas.toBlob(
                function (blob) {
                    if (blob) {
                        resolve(blob);
                    } else {
                        reject(new Error("Could not encode the image."));
                    }
                },
                "image/jpeg",
                quality,
            );
        });
    }

    async function normalizedBusinessCard(file) {
        if (file.size > 20 * 1024 * 1024) {
            throw new Error("Choose an image smaller than 20 MiB.");
        }

        var bitmap = await createImageBitmap(file, {
            imageOrientation: "from-image",
        });

        try {
            var scale = Math.min(
                1,
                2200 / Math.max(bitmap.width, bitmap.height),
            );
            var quality = 0.88;
            var blob = null;

            for (var attempt = 0; attempt < 6; attempt += 1) {
                var width = Math.max(1, Math.round(bitmap.width * scale));
                var height = Math.max(1, Math.round(bitmap.height * scale));
                var canvas = document.createElement("canvas");
                var context = canvas.getContext("2d", { alpha: false });

                canvas.width = width;
                canvas.height = height;
                if (!context) {
                    throw new Error("Could not prepare the image.");
                }

                context.fillStyle = "#ffffff";
                context.fillRect(0, 0, width, height);
                context.imageSmoothingEnabled = true;
                context.imageSmoothingQuality = "high";
                context.drawImage(bitmap, 0, 0, width, height);
                blob = await canvasBlob(canvas, quality);

                if (blob.size <= 6 * 1024 * 1024) {
                    return blob;
                }

                quality = Math.max(0.65, quality - 0.07);
                scale *= 0.85;
            }

            throw new Error(
                "The image is still too large after processing. Try a closer photo.",
            );
        } finally {
            bitmap.close();
        }
    }

    document.addEventListener("change", function (event) {
        var input = event.target.closest("[data-business-card-input]");
        if (!input || !input.files || !input.files[0]) {
            return;
        }

        var preview = input
            .closest("section")
            .querySelector("[data-business-card-preview]");
        if (!preview) {
            return;
        }

        if (businessCardPreviewUrl) {
            URL.revokeObjectURL(businessCardPreviewUrl);
        }
        businessCardPreviewUrl = URL.createObjectURL(input.files[0]);
        preview.src = businessCardPreviewUrl;
        preview.hidden = false;
    });

    document.addEventListener(
        "submit",
        function (event) {
            var form = event.target.closest("[data-business-card-form]");
            if (!form || form.dataset.businessCardPrepared === "yes") {
                if (form) {
                    delete form.dataset.businessCardPrepared;
                }
                return;
            }

            event.preventDefault();
            event.stopImmediatePropagation();

            var input = form.querySelector("[data-business-card-input]");
            var submit = form.querySelector("[data-business-card-submit]");
            var file = input && input.files && input.files[0];

            if (!file) {
                scannerStatus(form, "Take or choose a business-card image.", true);
                return;
            }

            if (submit) {
                submit.disabled = true;
                submit.textContent = "Preparing image…";
            }
            scannerStatus(form, "Preparing image…", false);

            normalizedBusinessCard(file)
                .then(function (blob) {
                    var transfer = new DataTransfer();
                    var prepared = form.querySelector(
                        "[data-business-card-prepared]",
                    );
                    transfer.items.add(
                        new File([blob], "business-card.jpg", {
                            type: "image/jpeg",
                        }),
                    );
                    input.files = transfer.files;
                    if (prepared) {
                        prepared.value = "yes";
                    }
                    form.dataset.businessCardPrepared = "yes";
                    scannerStatus(form, "Extracting contact details…", false);
                    if (submit) {
                        submit.textContent = "Extracting…";
                    }
                    form.requestSubmit();
                })
                .catch(function (error) {
                    scannerStatus(
                        form,
                        error instanceof Error
                            ? error.message
                            : "Could not prepare the image.",
                        true,
                    );
                    if (submit) {
                        submit.disabled = false;
                        submit.textContent = "Extract contact details";
                    }
                });
        },
        true,
    );
})();
