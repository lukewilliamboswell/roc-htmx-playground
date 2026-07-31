const assert = require("node:assert/strict");
const { execFileSync, spawn } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const artifacts = path.join(root, "test-results");
const database = path.join(artifacts, "tailscale-auth.db");
const executable =
  process.env.ENQUIRY_CRM_EXECUTABLE ||
  path.join(root, "dist", "roc-htmx-playground");
const assetPath =
  process.env.ENQUIRY_CRM_ASSET_PATH || path.join(root, "dist", "assets");
const localOrigin = "http://127.0.0.1:8011";
const publicOrigin = "https://crm.tailnet-example.ts.net";
const serverConfig = path.join(artifacts, "tailscale-auth.server.json");

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
  JSON.stringify({
    version: 1,
    server: {
      database_path: database,
      assets_path: assetPath,
      public_origin: publicOrigin,
      listen_port: 8011,
      timezone: "Australia/Melbourne",
    },
    features: {
      business_card_scanner: { enabled: false, provider: null },
    },
  }),
);

const server = spawn(executable, [], {
  cwd: root,
  env: {
    ...process.env,
    SERVER_CONFIG_PATH: serverConfig,
  },
  stdio: "inherit",
});

async function waitUntilReady() {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    if (server.exitCode !== null) {
      throw new Error(`Tailscale-mode server exited with ${server.exitCode}`);
    }
    try {
      const response = await fetch(`${localOrigin}/healthz`);
      if (response.status === 200) return;
    } catch {
      // The listener may not be ready yet.
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error("Timed out waiting for the Tailscale-mode server");
}

async function run() {
  await waitUntilReady();

  const health = await fetch(`${localOrigin}/healthz`);
  assert.equal(health.status, 200);
  assert.equal(await health.text(), "ok\n");

  const missingIdentity = await fetch(`${localOrigin}/companies`);
  assert.equal(missingIdentity.status, 403);

  const unknownIdentity = await fetch(`${localOrigin}/companies`, {
    headers: { "Tailscale-User-Login": "unknown@example.com" },
  });
  assert.equal(unknownIdentity.status, 403);

  const member = await fetch(`${localOrigin}/companies`, {
    headers: { "Tailscale-User-Login": "MARA@EXAMPLE.COM" },
  });
  assert.equal(member.status, 200);
  const memberBody = await member.text();
  assert.match(memberBody, /Mara Singh/);
  assert.doesNotMatch(memberBody, /dev mode/i);
  assert.doesNotMatch(memberBody, />Logout</);

  const loginRoute = await fetch(`${localOrigin}/login`, {
    headers: { "Tailscale-User-Login": "mara@example.com" },
  });
  assert.equal(loginRoute.status, 404);
  const loginRouteBody = await loginRoute.text();
  assert.match(loginRouteBody, /Mara Singh/);
  assert.doesNotMatch(loginRouteBody, />Login</);
  assert.doesNotMatch(loginRouteBody, />Register</);

  const unknownRouteWithoutIdentity = await fetch(
    `${localOrigin}/definitely-missing`,
  );
  assert.equal(unknownRouteWithoutIdentity.status, 403);

  const unknownRouteForMember = await fetch(
    `${localOrigin}/definitely-missing`,
    {
      headers: { "Tailscale-User-Login": "mara@example.com" },
    },
  );
  assert.equal(unknownRouteForMember.status, 404);
  const unknownRouteBody = await unknownRouteForMember.text();
  assert.match(unknownRouteBody, /Mara Singh/);
  assert.doesNotMatch(unknownRouteBody, />Login</);
  assert.doesNotMatch(unknownRouteBody, />Register</);

  const spoofedOrigin = await fetch(`${localOrigin}/companies/preview`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Origin: "https://attacker.example",
      "Tailscale-User-Login": "mara@example.com",
    },
    body: "name=",
  });
  assert.equal(spoofedOrigin.status, 403);
}

run()
  .then(() => {
    console.log("tailscale authentication: ok");
  })
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => {
    server.kill("SIGTERM");
  });
