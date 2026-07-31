const assert = require("node:assert/strict");
const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const artifacts = path.join(root, "test-results");
const database = path.join(artifacts, "migration-v1.db");
const webExecutable =
  process.env.ENQUIRY_CRM_EXECUTABLE ||
  path.join(root, "dist", "roc-htmx-playground");
const adminExecutable =
  process.env.ENQUIRY_CRM_ADMIN_EXECUTABLE ||
  path.join(path.dirname(webExecutable), "enquiry-crm-admin");

fs.mkdirSync(artifacts, { recursive: true });
fs.rmSync(database, { force: true });
for (const sqlFile of [
  "db/migrations/001_initial.sql",
  "db/test-fixtures.sql",
]) {
  execFileSync("sqlite3", [database, `.read ${sqlFile}`], {
    cwd: root,
    stdio: "inherit",
  });
}

execFileSync(adminExecutable, ["migrate", "--db", database], {
  cwd: root,
  stdio: "inherit",
});

const scalar = (sql) =>
  execFileSync("sqlite3", [database, sql], {
    cwd: root,
    encoding: "utf8",
  }).trim();

assert.equal(scalar("PRAGMA user_version;"), "2");
assert.equal(
  scalar("SELECT name FROM companies WHERE company_id = 'company-acme';"),
  "Acme Studio",
);
assert.equal(
  scalar(
    "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name IN ('TaskHeirachy', 'sessions', 'users', 'tasks', 'BigTask');",
  ),
  "0",
);

console.log("schema v1 to v2 migration: ok");
