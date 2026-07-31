const { execFileSync, spawn } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const artifacts = path.join(root, "test-results");
const database = path.join(artifacts, "playwright.db");
const serverConfig = path.join(artifacts, "playwright.server.json");
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
  "db/migrations/003_ai_foundation.sql",
  "db/test-fixtures.sql",
]) {
  execFileSync("sqlite3", [database, `.read ${sqlFile}`], {
    cwd: root,
    stdio: "inherit",
  });
}

fs.writeFileSync(
  serverConfig,
  JSON.stringify(
    {
      version: 1,
      server: {
        database_path: database,
        assets_path: assetPath,
        public_origin: "http://127.0.0.1:8010",
        listen_port: 8012,
        timezone: "Australia/Melbourne",
      },
      features: {
        business_card_scanner: {
          enabled: false,
          provider: null,
        },
      },
    },
    null,
    2,
  ),
);

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
      SERVER_CONFIG_PATH: serverConfig,
      ENQUIRY_CRM_EXECUTABLE: executable,
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
