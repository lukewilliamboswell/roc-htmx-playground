const { test, expect } = require("@playwright/test");

async function loginAsMara(page) {
  await page.goto("/login");
  await page.getByLabel("Username").fill("Mara Singh");
  await page.getByRole("button", { name: "Login", exact: true }).click();
  await expect(page.getByText("Mara Singh", { exact: true })).toBeVisible();
}

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

  test("keeps BigTask navigation bounded and restorable", async ({ page }) => {
    await loginAsMara(page);
    await page.goto("/bigTask");

    await page.evaluate(() => {
      const marker = document.createElement("div");
      marker.id = "client-only-marker";
      document.body.appendChild(marker);
    });

    await page.getByRole("link", { name: "Reference", exact: true }).click();

    await expect(page).toHaveURL(/sortBy=ReferenceID/);
    await expect(page.locator("#client-only-marker")).toBeAttached();
    await expect(
      page.getByRole("columnheader", { name: "Reference" }),
    ).toHaveAttribute("aria-sort", "ascending");

    await page.getByRole("link", { name: "Next", exact: true }).click();

    await expect(page).toHaveURL(/page=2/);
    await expect(page.getByText("Page 2 of 4 · 100 total rows")).toBeVisible();
    await expect(page.locator("#client-only-marker")).toBeAttached();

    await page.goBack();

    await expect(page).toHaveURL(/page=1/);
    await expect(page.getByText("Page 1 of 4 · 100 total rows")).toBeVisible();
    await expect(page.locator("#client-only-marker")).toBeAttached();

    await page.reload();

    await expect(page.getByRole("heading", { name: "Big Task Table" }))
      .toBeVisible();
    await expect(page.getByText("Page 1 of 4 · 100 total rows")).toBeVisible();
  });
});
