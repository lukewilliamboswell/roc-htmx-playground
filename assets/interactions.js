(function () {
    "use strict";

    function feedbackFor(event) {
        var detail = event.detail;
        var context = detail && detail.ctx;
        var source = context && context.sourceElement;
        var targetId = source && source.getAttribute("data-network-error-target");

        return targetId ? document.getElementById(targetId) : null;
    }

    document.addEventListener("htmx:before:request", function (event) {
        var feedback = feedbackFor(event);
        var previous = feedback && feedback.querySelector("[data-transport-error]");

        if (previous) {
            previous.remove();
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
            target.focus({ preventScroll: true });
        }
    });
})();
