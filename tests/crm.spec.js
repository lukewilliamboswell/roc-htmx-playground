const { test, expect } = require("@playwright/test");

async function loginAsMara(page) {
  await page.goto("/login");
  await page.getByLabel("Username").fill("Mara Singh");
  await page.getByRole("button", { name: "Login", exact: true }).click();
  await expect(page.getByText("Mara Singh", { exact: true })).toBeVisible();
}

test.describe("CRM journeys", () => {
  test("preserves a company display name and provides submitted search", async ({
    page,
  }) => {
    await loginAsMara(page);
    await page.goto("/companies/new");

    await page
      .getByLabel("Company name")
      .fill("Playwright Mixed CASE Company");
    await page
      .getByRole("button", { name: "Check and save company", exact: true })
      .click();

    await expect(
      page.getByRole("heading", {
        name: "Playwright Mixed CASE Company",
        exact: true,
      }),
    ).toBeVisible();

    await page.goto("/companies");
    await page.getByLabel("Search companies").fill("Mixed CASE");
    await page.getByRole("button", { name: "Search", exact: true }).click();
    await expect(
      page.getByRole("link", {
        name: "Playwright Mixed CASE Company",
        exact: true,
      }),
    ).toBeVisible();
  });

  test("previews canonical company-name matches before creating", async ({
    page,
  }) => {
    await loginAsMara(page);
    await page.goto("/companies/new");

    await page.getByLabel("Company name").fill("Acme Studios Pty Ltd");
    await page
      .getByRole("button", { name: "Check and save company", exact: true })
      .click();

    await expect(
      page.getByRole("heading", {
        name: "Check possible duplicates",
        exact: true,
      }),
    ).toBeVisible();
    await expect(
      page.getByText("Possible match: Similar company name"),
    ).toBeVisible();
    await expect(
      page.getByRole("button", {
        name: "Create as a separate company",
        exact: true,
      }),
    ).toBeVisible();
  });

  test("maintains primary contacts and exposes task responsibility", async ({
    page,
  }) => {
    await loginAsMara(page);
    await page.goto("/people/new");

    await page.getByLabel("Name", { exact: true }).fill("Ada Playwright");
    await page.getByLabel("Company", { exact: true }).selectOption("company-acme");
    await page
      .getByLabel("Email", { exact: true })
      .fill("ada.playwright@example.com");
    await page
      .getByRole("button", { name: "Check and save person", exact: true })
      .click();

    await expect(
      page.getByRole("heading", { name: "Ada Playwright", exact: true }),
    ).toBeVisible();

    let emailSection = page.locator("section").filter({
      has: page.getByRole("heading", {
        name: "Email addresses",
        exact: true,
      }),
    });
    await emailSection.getByLabel("Label", { exact: true }).fill("Personal");
    await emailSection
      .getByLabel("Value", { exact: true })
      .fill("ada.secondary@example.com");
    await emailSection
      .getByRole("button", { name: "Add", exact: true })
      .click();

    emailSection = page.locator("section").filter({
      has: page.getByRole("heading", {
        name: "Email addresses",
        exact: true,
      }),
    });
    let secondaryEmail = emailSection
      .getByRole("listitem")
      .filter({ hasText: "ada.secondary@example.com" });
    await secondaryEmail
      .getByRole("button", { name: "Make primary", exact: true })
      .click();

    emailSection = page.locator("section").filter({
      has: page.getByRole("heading", {
        name: "Email addresses",
        exact: true,
      }),
    });
    secondaryEmail = emailSection
      .getByRole("listitem")
      .filter({ hasText: "ada.secondary@example.com" });
    await expect(secondaryEmail).toContainText("Primary");

    const taskSection = page.locator("section").filter({
      has: page.getByRole("heading", { name: "Open tasks", exact: true }),
    });
    await taskSection
      .getByLabel("Subject", { exact: true })
      .fill("Confirm browser journey");
    await taskSection.getByLabel(/^Due in /).fill("2026-07-29T10:00");
    await taskSection
      .getByLabel("Assignee", { exact: true })
      .selectOption({ label: "Theo Nguyen" });
    await taskSection
      .getByLabel("Task type", { exact: true })
      .selectOption({ label: "Follow up" });
    await taskSection
      .getByLabel("Context", { exact: true })
      .fill("Verify the CRM browser workflow");
    await taskSection
      .getByRole("button", { name: "Schedule task", exact: true })
      .click();

    const task = page
      .getByRole("listitem")
      .filter({ hasText: "Confirm browser journey" });
    await expect(task).toContainText("Assignee: Theo Nguyen");
    await expect(task).toContainText("Type: Follow up");
    await expect(task).toContainText(
      "Context: Verify the CRM browser workflow",
    );
  });
});
