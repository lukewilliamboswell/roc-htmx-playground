const assert = require("node:assert/strict");
const { execFileSync, spawn } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const artifacts = path.join(root, "test-results");
const database = path.join(artifacts, "dev-auth.db");
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

function start(memberEmail, publicPort, backendPort) {
  return spawn(
    process.execPath,
    [
      path.join(root, "scripts", "dev-server.js"),
      "--member-email",
      memberEmail,
    ],
    {
      cwd: root,
      env: {
        ...process.env,
        DEV_PUBLIC_PORT: String(publicPort),
        DEV_BACKEND_PORT: String(backendPort),
        ENQUIRY_CRM_ASSET_PATH: assetPath,
        ENQUIRY_CRM_DATABASE: database,
        ENQUIRY_CRM_EXECUTABLE: executable,
      },
      stdio: "inherit",
    },
  );
}

async function waitFor(server, origin) {
  for (let attempt = 0; attempt < 150; attempt += 1) {
    if (server.exitCode !== null) {
      throw new Error(`Development proxy exited with ${server.exitCode}`);
    }
    try {
      const response = await fetch(origin);
      if (response.status === 200) return response;
    } catch {
      // The proxy is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error("Timed out waiting for development proxy");
}

async function stop(server) {
  if (server.exitCode !== null) return;
  await new Promise((resolve) => {
    server.once("exit", resolve);
    server.kill("SIGTERM");
  });
}

async function run() {
  const maraOrigin = "http://127.0.0.1:8013";
  const mara = start("mara@example.com", 8013, 8014);
  const maraResponse = await waitFor(mara, maraOrigin);
  const maraBody = await maraResponse.text();
  assert.match(maraBody, /Mara Singh/);
  assert.match(maraBody, /Dev mode/);

  const spoofed = await fetch(maraOrigin, {
    headers: { "Tailscale-User-Login": "theo@example.com" },
  });
  const spoofedBody = await spoofed.text();
  assert.match(spoofedBody, /Mara Singh/);
  assert.doesNotMatch(spoofedBody, /Theo Nguyen/);

  const forwardedPost = await fetch(`${maraOrigin}/companies/preview`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Origin: maraOrigin,
    },
    body: "name=",
  });
  assert.notEqual(forwardedPost.status, 502);
  await stop(mara);

  const theoOrigin = "http://127.0.0.1:8015";
  const theo = start("theo@example.com", 8015, 8016);
  const theoResponse = await waitFor(theo, theoOrigin);
  const theoBody = await theoResponse.text();
  assert.match(theoBody, /Theo Nguyen/);
  assert.match(theoBody, /Dev mode/);

  const preserved = await fetch(`${theoOrigin}/companies`);
  assert.match(await preserved.text(), /Acme Studio/);
  await stop(theo);
}

run()
  .then(() => console.log("development proxy authentication: ok"))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
