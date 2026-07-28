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
            "The request could not reach the server. Check your connection and try again.";
        feedback.replaceChildren(message);
    });
})();
