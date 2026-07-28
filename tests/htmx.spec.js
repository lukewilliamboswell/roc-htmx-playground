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

    await page.route("**/task?*", async (route) => {
      const filter =
        new URL(route.request().url()).searchParams.get("filterTasks") || "";
      requestedFilters.push(filter);

      await new Promise((resolve) =>
        setTimeout(resolve, filter === "first" ? 500 : 20),
      );

      await route.fulfill({
        status: 200,
        contentType: "text/html",
        body: `<html><body><div id="todo-list"><p>Results for ${filter}</p></div></body></html>`,
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
    await expect(page).toHaveURL("/task?filterTasks=latest");

    await page.waitForTimeout(600);
    await expect(page.getByText("Results for latest")).toBeVisible();
    await expect(page.getByText("Results for first")).toHaveCount(0);

    await page.unroute("**/task?*");
    await page.reload();

    await expect(page.getByLabel("Filter tasks")).toHaveValue("latest");
    await expect(page.getByText("No tasks to show.")).toBeVisible();
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

  test("retains navigation and filter behavior without JavaScript", async ({
    browser,
  }) => {
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();

    await page.goto("/task");
    await page.getByLabel("Filter tasks").fill("council");
    await page.getByLabel("Filter tasks").press("Enter");

    await expect(page).toHaveURL("/task?filterTasks=council");
    await expect(page.getByText("Confirm the council permit")).toBeVisible();
    await expect(
      page.getByText("Launch the neighbourhood garden"),
    ).toHaveCount(0);

    await loginAsMara(page);
    await page.goto("/bigTask");
    await page.getByRole("link", { name: "Reference", exact: true }).click();

    await expect(page).toHaveURL(/sortBy=ReferenceID/);
    await expect(
      page.getByRole("columnheader", { name: "Reference" }),
    ).toHaveAttribute("aria-sort", "ascending");

    await context.close();
  });

  test("keeps inline validation associated and focused", async ({ page }) => {
    await loginAsMara(page);
    await page.goto("/bigTask");

    const editor = page.locator("#big-task-0-customerId-control");

    await editor.fill("not-a-number");

    const error = page.getByText(
      "Must be a number between 0 and 100,000.",
      { exact: true },
    );
    await expect(error).toBeVisible();
    await expect(editor).toBeFocused();
    await expect(editor).toHaveAttribute("aria-invalid", "true");

    const errorId = await editor.getAttribute("aria-describedby");
    expect(errorId).toBeTruthy();
    await expect(page.locator(`#${errorId}`)).toHaveText(
      "Must be a number between 0 and 100,000.",
    );
    await expect(page.locator(`#${errorId}`)).toHaveAttribute(
      "aria-live",
      "polite",
    );

    await editor.fill("789");

    await expect(editor).toBeFocused();
    await expect(editor).toHaveAttribute("aria-invalid", "false");
    await expect(page.locator(`#${errorId}`)).toBeEmpty();
  });

  test("rejects a stale autosave from another tab without overwriting", async ({
    page,
  }) => {
    await loginAsMara(page);
    const secondPage = await page.context().newPage();

    await Promise.all([page.goto("/bigTask"), secondPage.goto("/bigTask")]);

    const firstEditor = page.locator("#big-task-0-customerId-control");
    const secondEditor = secondPage.locator("#big-task-0-customerId-control");

    await firstEditor.fill("789");
    await expect(
      firstEditor.locator("xpath=../input[@name='version']"),
    ).toHaveValue("2");

    await secondEditor.fill("790");
    await expect(
      secondPage.getByText(
        "This field changed elsewhere. Review your value and edit again to retry.",
        { exact: true },
      ),
    ).toBeVisible();
    await expect(secondEditor).toHaveValue("790");

    await page.reload();
    await expect(page.locator("#big-task-0-customerId-control")).toHaveValue(
      "789",
    );

    await secondPage.close();
  });
});
