const http = require("node:http");
const { spawn } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

function valueAfter(args, flag) {
  const index = args.indexOf(flag);
  if (index === -1 || !args[index + 1]) return undefined;
  return args[index + 1];
}

const args = process.argv.slice(2);
const memberEmail =
  valueAfter(args, "--member-email") ||
  process.env.DEV_MEMBER_EMAIL ||
  "mara@example.com";
const root = path.resolve(__dirname, "..");
const configPath = path.resolve(
  process.env.SERVER_CONFIG_PATH ||
    path.join(root, "dist", "development.server.json"),
);
let serverConfig;

try {
  serverConfig = JSON.parse(fs.readFileSync(configPath, "utf8"));
} catch (error) {
  console.error(
    `Unable to read server configuration ${configPath}: ${error.message}`,
  );
  process.exit(2);
}

const backendPort = Number(serverConfig.server?.listen_port);
const publicOrigin = new URL(serverConfig.server?.public_origin);
const publicPort = Number(
  publicOrigin.port || (publicOrigin.protocol === "https:" ? "443" : "80"),
);
const executable =
  process.env.ENQUIRY_CRM_EXECUTABLE ||
  path.join(root, "dist", "roc-htmx-playground");

if (!memberEmail.includes("@")) {
  console.error(`Invalid development member email: ${memberEmail}`);
  process.exit(2);
}

const backend = spawn(executable, [], {
  cwd: root,
  env: {
    ...process.env,
    SERVER_CONFIG_PATH: configPath,
  },
  stdio: "inherit",
});

let stopping = false;

const proxy = http.createServer((request, response) => {
  const headers = { ...request.headers };
  delete headers["tailscale-user-login"];
  headers["tailscale-user-login"] = memberEmail;
  headers.host = `127.0.0.1:${backendPort}`;

  const upstream = http.request(
    {
      host: "127.0.0.1",
      port: backendPort,
      method: request.method,
      path: request.url,
      headers,
    },
    (upstreamResponse) => {
      response.writeHead(upstreamResponse.statusCode, upstreamResponse.headers);
      upstreamResponse.pipe(response);
    },
  );

  upstream.on("error", (error) => {
    if (!response.headersSent) {
      response.writeHead(502, { "Content-Type": "text/plain; charset=utf-8" });
    }
    response.end(`Development backend unavailable: ${error.message}\n`);
  });
  request.pipe(upstream);
});

async function waitForBackend() {
  for (let attempt = 0; attempt < 200; attempt += 1) {
    if (backend.exitCode !== null) {
      throw new Error(`Development backend exited with ${backend.exitCode}`);
    }
    try {
      const health = await fetch(`http://127.0.0.1:${backendPort}/healthz`);
      if (health.status === 200) return;
    } catch {
      // The private listener is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error("Timed out waiting for the development backend");
}

async function verifyMember() {
  const response = await fetch(`http://127.0.0.1:${backendPort}/`, {
    headers: { "Tailscale-User-Login": memberEmail },
  });
  if (response.status !== 200) {
    throw new Error(
      `Development member ${memberEmail} is not an active workspace member`,
    );
  }
}

function stop(signal = "SIGTERM") {
  if (stopping) return;
  stopping = true;
  proxy.close();
  if (!backend.killed) backend.kill(signal);
}

process.on("SIGINT", () => stop("SIGINT"));
process.on("SIGTERM", () => stop("SIGTERM"));
backend.on("exit", (code, signal) => {
  if (!stopping) {
    console.error(
      `Development backend exited unexpectedly (${signal || `code ${code}`})`,
    );
    proxy.close();
    process.exitCode = code ?? (signal ? 1 : 0);
  }
});

waitForBackend()
  .then(verifyMember)
  .then(() => {
    proxy.listen(publicPort, "127.0.0.1", () => {
      console.log(`Development identity: ${memberEmail}`);
      console.log(`Listening on ${publicOrigin.toString()}`);
      console.log(`Private backend: http://127.0.0.1:${backendPort}`);
    });
  })
  .catch((error) => {
    console.error(error.message);
    stop();
    process.exitCode = 1;
  });
