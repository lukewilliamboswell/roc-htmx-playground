const { test, expect } = require("@playwright/test");

test.describe("HTMX interactions", () => {
  test("keeps live-search results aligned with the newest input", async ({
    page,
  }) => {
    const requestedFilters = [];

    await page.route("**/task/search", async (route) => {
      const form = new URLSearchParams(route.request().postData() || "");
      const filter = form.get("filterTasks") || "";
      requestedFilters.push(filter);

      await new Promise((resolve) =>
        setTimeout(resolve, filter === "first" ? 500 : 20),
      );

      await route.fulfill({
        status: 200,
        contentType: "text/html",
        body: `<div id="todo-list"><p>Results for ${filter}</p></div>`,
      });
    });

    await page.goto("/task");
    const search = page.getByLabel("Filter tasks");

    await search.fill("first");
    await expect
      .poll(() => requestedFilters.includes("first"))
      .toBe(true);

    await search.fill("latest");
    await expect(page.getByText("Results for latest")).toBeVisible();

    await page.waitForTimeout(600);
    await expect(page.getByText("Results for latest")).toBeVisible();
    await expect(page.getByText("Results for first")).toHaveCount(0);
  });
});
