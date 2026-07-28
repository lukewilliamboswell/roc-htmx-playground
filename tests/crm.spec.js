const { test, expect } = require("@playwright/test");

async function loginAsMara(page) {
  await page.goto("/login");
  await page.getByLabel("Username").fill("Mara Singh");
  await page.getByRole("button", { name: "Login", exact: true }).click();
  await expect(page.getByText("Mara Singh", { exact: true })).toBeVisible();
}

async function expectNoDocumentOverflow(page) {
  const widths = await page.evaluate(() => ({
    client: document.documentElement.clientWidth,
    scroll: document.documentElement.scrollWidth,
  }));
  expect(widths.scroll).toBeLessThanOrEqual(widths.client);
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

    await page.getByLabel("Search companies").fill("No matching company");
    await page.getByRole("button", { name: "Search", exact: true }).click();
    await expect(
      page.getByText(
        "No companies match “No matching company”. Clear the search to see every company.",
      ),
    ).toBeVisible();
    await page.getByRole("link", { name: "Clear search", exact: true }).click();
    await expect(page).toHaveURL("/companies");
    await expect(
      page.getByRole("link", {
        name: "Playwright Mixed CASE Company",
        exact: true,
      }),
    ).toBeVisible();

    await page.goto("/people");
    await page.getByLabel("Search people").fill("No matching person");
    await page.getByRole("button", { name: "Search", exact: true }).click();
    await expect(
      page.getByText(
        "No people match “No matching person”. Clear the search to see every person.",
      ),
    ).toBeVisible();
    await page.getByRole("link", { name: "Clear search", exact: true }).click();
    await expect(page).toHaveURL("/people");
    await expect(
      page.getByText(
        "No people have been recorded yet. Use New person to capture the first relationship.",
      ),
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

  test("preserves CRM form values and focuses server validation", async ({
    page,
  }) => {
    await loginAsMara(page);
    await page.goto("/companies/new");

    await page
      .getByLabel("Website", { exact: true })
      .fill("https://preserved.example");
    const companyName = page.locator("#name");
    const companySubmit = page.getByRole("button", {
      name: "Check and save company",
      exact: true,
    });
    await expect(companyName).toHaveAttribute("required", "");
    await companySubmit.click();
    await expect(companyName).toBeFocused();
    await expect(page).toHaveURL("/companies/new");

    await companyName.evaluate((input) => {
      input.form.noValidate = true;
    });
    await companySubmit.click();

    const companyError = page.getByRole("alert");
    await expect(companyError).toHaveText("Enter a company name.");
    await expect(companyError).toBeFocused();
    await expect(page.getByLabel("Website", { exact: true })).toHaveValue(
      "https://preserved.example",
    );

    await page.goto("/people/new?company=company-acme");
    await page
      .getByLabel("Role or title", { exact: true })
      .fill("Preserved role");
    await page.getByLabel("Company", { exact: true }).selectOption("");
    await expect(
      page.getByText(
        "Only a name is required. Add an email or phone when known to make follow-up and duplicate checking more reliable.",
      ),
    ).toBeVisible();
    const personName = page.locator("#name");
    const personSubmit = page.getByRole("button", {
      name: "Check and save person",
      exact: true,
    });
    await expect(personName).toHaveAttribute("required", "");
    await personSubmit.click();
    await expect(personName).toBeFocused();
    await expect(page).toHaveURL("/people/new?company=company-acme");

    await personName.evaluate((input) => {
      input.form.noValidate = true;
    });
    await personSubmit.click();

    const personError = page.getByRole("alert");
    await expect(personError).toHaveText("Enter a person's name.");
    await expect(personError).toBeFocused();
    await expect(page.getByLabel("Role or title", { exact: true })).toHaveValue(
      "Preserved role",
    );
    await expect(page.getByLabel("Company", { exact: true })).toHaveValue("");
    await expect(
      page.getByRole("link", { name: "Cancel", exact: true }),
    ).toHaveAttribute("href", "/companies/company-acme");
  });

  test("provides native secondary exits from CRM forms", async ({
    browser,
  }) => {
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();

    await loginAsMara(page);
    await page.goto("/companies/new");
    const newCompanyForm = page.locator("form");
    await expect(
      newCompanyForm.getByRole("button", {
        name: "Check and save company",
        exact: true,
      }),
    ).toBeVisible();
    await newCompanyForm
      .getByRole("link", { name: "Cancel", exact: true })
      .click();
    await expect(page).toHaveURL("/companies");

    await page.goto("/companies/company-acme/edit");
    const editCompanyForm = page.locator("form");
    await expect(
      editCompanyForm.getByRole("button", {
        name: "Save company",
        exact: true,
      }),
    ).toBeVisible();
    await editCompanyForm
      .getByRole("link", { name: "Cancel", exact: true })
      .click();
    await expect(page).toHaveURL("/companies/company-acme");

    await page.goto("/people/new");
    await page
      .locator("form")
      .getByRole("link", { name: "Cancel", exact: true })
      .click();
    await expect(page).toHaveURL("/people");

    await page.goto("/people/new?company=company-acme");
    await expect(
      page.getByRole("link", { name: "← Acme Studio", exact: true }),
    ).toHaveAttribute("href", "/companies/company-acme");
    await page
      .locator("form")
      .filter({
        has: page.getByRole("button", {
          name: "Check and save person",
          exact: true,
        }),
      })
      .getByRole("link", { name: "Cancel", exact: true })
      .click();
    await expect(page).toHaveURL("/companies/company-acme");

    await context.close();
  });

  test("keeps core CRM views within a small viewport", async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: 375, height: 812 },
    });
    const page = await context.newPage();

    await loginAsMara(page);
    await page.goto("/companies");
    await expectNoDocumentOverflow(page);
    await expect(
      page.getByRole("link", { name: "New company", exact: true }),
    ).toBeVisible();

    const tableRegion = page.locator("div.overflow-x-auto");
    await expect(tableRegion).toBeVisible();
    const tableWidths = await tableRegion.evaluate((region) => ({
      client: region.clientWidth,
      scroll: region.scrollWidth,
    }));
    expect(tableWidths.scroll).toBeGreaterThanOrEqual(tableWidths.client);

    await page.goto("/people/new");
    await expectNoDocumentOverflow(page);
    await expect(
      page.getByRole("button", {
        name: "Check and save person",
        exact: true,
      }),
    ).toBeVisible();
    await expect(
      page.getByRole("link", { name: "Cancel", exact: true }),
    ).toBeVisible();

    await page.goto("/companies/company-acme");
    await expectNoDocumentOverflow(page);
    await expect(
      page.getByRole("heading", { name: "Open tasks", exact: true }),
    ).toBeVisible();
    await expect(
      page.getByRole("button", { name: "Schedule task", exact: true }),
    ).toBeVisible();

    await context.close();
  });

  test("maintains primary contacts and exposes task responsibility", async ({
    page,
  }) => {
    await loginAsMara(page);
    await page.goto("/people/new");

    await page
      .getByRole("textbox", { name: "Name", exact: true })
      .fill("Ada Playwright");
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
    const phoneSection = page.locator("section").filter({
      has: page.getByRole("heading", {
        name: "Phone numbers",
        exact: true,
      }),
    });
    await expect(
      emailSection.getByLabel("Label", { exact: true }),
    ).toHaveAttribute("id", "person-email-label");
    await expect(
      phoneSection.getByLabel("Label", { exact: true }),
    ).toHaveAttribute("id", "person-phone-label");
    await phoneSection.locator('label[for="person-phone-value"]').click();
    await expect(phoneSection.locator("#person-phone-value")).toBeFocused();

    await emailSection.getByLabel("Label", { exact: true }).fill("Personal");
    const emailValue = emailSection.getByRole("textbox", {
      name: "Value",
      exact: true,
    });
    const addEmail = emailSection.getByRole("button", {
      name: "Add",
      exact: true,
    });
    await expect(emailValue).toHaveAttribute("required", "");
    await addEmail.click();
    await expect(emailValue).toBeFocused();
    await emailValue.fill("ada.secondary@example.com");
    await addEmail.click();

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
    const taskSubject = taskSection.getByRole("textbox", {
      name: "Subject",
      exact: true,
    });
    const taskDue = taskSection.getByLabel(/^Due in /);
    const scheduleTask = taskSection.getByRole("button", {
      name: "Schedule task",
      exact: true,
    });
    await expect(taskSubject).toHaveAttribute("required", "");
    await expect(taskDue).toHaveAttribute("required", "");
    await scheduleTask.click();
    await expect(taskSubject).toBeFocused();
    await taskSubject.fill("Confirm browser journey");
    await scheduleTask.click();
    await expect(taskDue).toBeFocused();
    await taskDue.fill("2026-07-29T10:00");
    await taskSection
      .getByLabel("Assignee", { exact: true })
      .selectOption({ label: "Theo Nguyen" });
    await taskSection
      .getByLabel("Task type", { exact: true })
      .selectOption({ label: "Follow up" });
    await taskSection
      .getByLabel("Context", { exact: true })
      .fill("Verify the CRM browser workflow");
    await scheduleTask.click();

    const task = page
      .getByRole("listitem")
      .filter({ hasText: "Confirm browser journey" });
    await expect(task).toContainText("Assignee: Theo Nguyen");
    await expect(task).toContainText("Type: Follow up");
    await expect(task).toContainText(
      "Context: Verify the CRM browser workflow",
    );

    const relationshipUrl = page.url();
    const completionPattern = "**/people/*/tasks/*/complete";
    const complete = task.getByRole("button", {
      name: "Complete",
      exact: true,
    });

    await page.route(completionPattern, async (route) => {
      await route.abort("failed");
    });
    await complete.click();

    await expect(
      page
        .getByRole("alert")
        .getByText(
          "The request could not reach the server. Check your connection and try again.",
        ),
    ).toBeVisible();
    await expect(task).toBeVisible();
    await expect(page).toHaveURL(relationshipUrl);
    await page.unroute(completionPattern);

    await page.route(completionPattern, async (route) => {
      await route.fulfill({
        status: 500,
        contentType: "text/html",
        body: `
          <html>
            <body>
              <section id="request-error" role="alert">
                Completion failed. Try again.
              </section>
            </body>
          </html>
        `,
      });
    });
    await complete.click();

    await expect(
      page.getByRole("alert").getByText("Completion failed. Try again."),
    ).toBeVisible();
    await expect(task).toBeVisible();
    await expect(page).toHaveURL(relationshipUrl);
    await page.unroute(completionPattern);

    let completionRequests = 0;
    await page.route(completionPattern, async (route) => {
      completionRequests += 1;
      await new Promise((resolve) => setTimeout(resolve, 250));
      await route.continue();
    });

    await complete.evaluate((button) => {
      button.click();
      button.click();
    });

    await expect(task).not.toBeVisible();
    await expect(page).toHaveURL(relationshipUrl);
    await expect(page.locator("#related-open-tasks-heading")).toBeFocused();
    expect(completionRequests).toBe(1);
  });

  test("completes related work in context without JavaScript", async ({
    browser,
  }) => {
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();

    await loginAsMara(page);
    await page.goto("/people/new");
    await page
      .getByRole("textbox", { name: "Name", exact: true })
      .fill("No Script Follow-up");
    await page
      .getByRole("button", { name: "Check and save person", exact: true })
      .click();

    const taskSection = page.locator("section").filter({
      has: page.getByRole("heading", { name: "Open tasks", exact: true }),
    });
    await taskSection
      .getByRole("textbox", { name: "Subject", exact: true })
      .fill("Native completion");
    await taskSection.getByLabel(/^Due in /).fill("2026-07-29T11:00");
    await taskSection
      .getByRole("button", { name: "Schedule task", exact: true })
      .click();

    const relationshipUrl = page.url();
    const task = page
      .getByRole("listitem")
      .filter({ hasText: "Native completion" });
    await task
      .getByRole("button", { name: "Complete", exact: true })
      .click();

    await expect(page).toHaveURL(relationshipUrl);
    await expect(
      page.getByRole("heading", { name: "No Script Follow-up", exact: true }),
    ).toBeVisible();
    await expect(task).not.toBeVisible();

    await context.close();
  });
});
