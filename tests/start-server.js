const { execFileSync, spawn } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const artifacts = path.join(root, "test-results");
const database = path.join(artifacts, "playwright.db");
const executable =
  process.env.ENQUIRY_CRM_EXECUTABLE ||
  path.join(root, "dist", "roc-htmx-playground");
const assetPath =
  process.env.ENQUIRY_CRM_ASSET_PATH || path.join(root, "dist", "assets");

fs.mkdirSync(artifacts, { recursive: true });
fs.rmSync(database, { force: true });

for (const sqlFile of [
  "db/migrations/001_initial.sql",
  "db/migrations/002_remove_legacy_auth_and_demos.sql",
  "db/test-fixtures.sql",
]) {
  execFileSync("sqlite3", [database, `.read ${sqlFile}`], {
    cwd: root,
    stdio: "inherit",
  });
}

if (!process.env.ENQUIRY_CRM_SKIP_BUILD) {
  execFileSync("roc", ["scripts/tasks.roc", "build"], {
    cwd: root,
    stdio: "inherit",
  });
}

const server = spawn(
  process.execPath,
  [
    path.join(root, "scripts", "dev-server.js"),
    "--member-email",
    "mara@example.com",
  ],
  {
    cwd: root,
    env: {
      ...process.env,
      DEV_PUBLIC_PORT: "8010",
      DEV_BACKEND_PORT: "8012",
      ENQUIRY_CRM_ASSET_PATH: assetPath,
      ENQUIRY_CRM_DATABASE: database,
      ENQUIRY_CRM_EXECUTABLE: executable,
      TZ: "Australia/Melbourne",
    },
    stdio: "inherit",
  },
);

function stop(signal) {
  if (!server.killed) {
    server.kill(signal);
  }
}

process.on("SIGINT", () => stop("SIGINT"));
process.on("SIGTERM", () => stop("SIGTERM"));
server.on("exit", (code, signal) => {
  process.exitCode = code ?? (signal ? 1 : 0);
});
