const assert = require("node:assert/strict");
const { execFileSync, spawn } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const artifacts = path.join(root, "test-results");
const database = path.join(artifacts, "business-card-smoke.db");
const serverConfig = path.join(
  artifacts,
  "business-card-smoke.server.json",
);
const executable =
  process.env.ENQUIRY_CRM_EXECUTABLE ||
  path.join(root, "dist", "roc-htmx-playground");
const assetPath =
  process.env.ENQUIRY_CRM_ASSET_PATH || path.join(root, "dist", "assets");
const publicOrigin = "http://127.0.0.1:8017";

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
      listen_port: 8018,
      timezone: "Australia/Melbourne",
    },
    features: {
      business_card_scanner: {
        enabled: true,
        provider: {
          type: "openrouter",
          api_key: "test-key-must-never-be-used",
          model: "openai/gpt-5.6-luna",
        },
      },
    },
  }),
);

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

async function waitForPage() {
  for (let attempt = 0; attempt < 150; attempt += 1) {
    if (server.exitCode !== null) {
      throw new Error(`Development proxy exited with ${server.exitCode}`);
    }
    try {
      const response = await fetch(`${publicOrigin}/people/new`);
      if (response.status === 200) return response.text();
    } catch {
      // The loopback server is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error("Timed out waiting for business-card smoke server");
}

function upload(
  grant,
  {
    prepared = true,
    bytes = [0x89, 0x50, 0x4e, 0x47],
    contentType = "image/png",
    filename = "not-a-jpeg.png",
  } = {},
) {
  const body = new FormData();
  body.set("scanGrant", grant);
  if (prepared) body.set("imagePrepared", "yes");
  body.set(
    "cardImage",
    new Blob([new Uint8Array(bytes)], {
      type: contentType,
    }),
    filename,
  );
  return fetch(`${publicOrigin}/people/business-card/scan`, {
    method: "POST",
    headers: { Origin: publicOrigin },
    body,
  });
}

function scalar(sql) {
  return execFileSync("sqlite3", [database, sql], {
    cwd: root,
    encoding: "utf8",
  }).trim();
}

async function stop() {
  if (server.exitCode !== null) return;
  await new Promise((resolve) => {
    server.once("exit", resolve);
    server.kill("SIGTERM");
  });
}

async function run() {
  try {
    const page = await waitForPage();
    assert.match(page, /Scan a business card/);
    const grant = page.match(
      /name="scanGrant" value="(grant-[a-f0-9]+)"/,
    )?.[1];
    assert.ok(grant, "The enabled scanner must issue an action grant");

    const rejected = await upload(grant);
    const rejectedBody = await rejected.text();
    assert.equal(rejected.status, 415, rejectedBody);
    assert.match(rejectedBody, /browser-generated JPEG image only/);
    assert.equal(
      scalar(
        "SELECT state || '|' || outcome_code || '|' || input_bytes FROM ai_runs;",
      ),
      "rejected|unsupported_image|4",
    );

    const replayed = await upload(grant);
    assert.equal(replayed.status, 409);
    assert.match(await replayed.text(), /expired or was already used/);
    assert.equal(scalar("SELECT COUNT(*) FROM ai_runs;"), "1");

    const replacementGrant = rejectedBody.match(
      /name="scanGrant" value="(grant-[a-f0-9]+)"/,
    )?.[1];
    assert.ok(replacementGrant, "A rejected scan must issue a fresh grant");
    const unprepared = await upload(replacementGrant, {
      prepared: false,
      bytes: [0xff, 0xd8, 0xff, 0xd9],
      contentType: "image/jpeg",
      filename: "unprepared.jpg",
    });
    assert.equal(unprepared.status, 422);
    assert.match(await unprepared.text(), /not privacy-processed/);
    assert.equal(
      scalar(
        "SELECT outcome_code FROM ai_runs ORDER BY submitted_at DESC, rowid DESC LIMIT 1;",
      ),
      "image_not_prepared",
    );
  } finally {
    await stop();
  }
}

run()
  .then(() => console.log("business-card scanner security: ok"))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
