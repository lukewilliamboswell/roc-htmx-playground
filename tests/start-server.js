const { execFileSync, spawn } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const artifacts = path.join(root, "test-results");
const database = path.join(artifacts, "playwright.db");
const executable = path.join(root, "dist", "roc-htmx-playground");

fs.mkdirSync(artifacts, { recursive: true });
fs.rmSync(database, { force: true });

for (const sqlFile of ["db/init.sql", "db/test-fixtures.sql"]) {
  execFileSync("sqlite3", [database, `.read ${sqlFile}`], {
    cwd: root,
    stdio: "inherit",
  });
}

execFileSync("roc", ["scripts/tasks.roc", "build"], {
  cwd: root,
  stdio: "inherit",
});

const server = spawn(executable, [], {
  cwd: root,
  env: {
    ...process.env,
    ASSET_PATH: path.join(root, "dist", "assets"),
    DB_PATH: database,
    PORT: "8010",
    TZ: "Australia/Melbourne",
  },
  stdio: "inherit",
});

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
