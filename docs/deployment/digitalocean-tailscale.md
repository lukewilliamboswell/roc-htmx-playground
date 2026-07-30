# DigitalOcean + Tailscale deployment

This is the supported production shape for Enquiry CRM:

```text
Tailnet identity
    -> Tailscale client and tailnet policy
    -> Tailscale Serve (HTTPS and identity headers)
    -> 127.0.0.1:8000
    -> Enquiry CRM systemd service
    -> /var/lib/enquiry-crm/enquiry-crm.sqlite
```

The application does not implement a second OAuth flow. A person authenticates
with the identity provider configured for the tailnet. Tailscale Serve supplies
the verified login in `Tailscale-User-Login`, and the application permits that
login only when the normalized email belongs to an active, pre-provisioned CRM
member.

This design relies on three boundaries:

1. the application listens only on loopback;
2. the production service has an HTTPS `PUBLIC_ORIGIN`, which requires
   Tailscale identity; and
3. only Tailscale Serve can reach the application port.

Do not use Tailscale Funnel with this authentication mode. Funnel is public,
and Tailscale identity headers are only populated for tailnet users.

## Before production

The upgrade procedure below creates a verified local SQLite backup. Also
establish off-host retention, monitoring, and a tested restore procedure before
treating the database as production data. DigitalOcean snapshots are useful
disaster recovery, but they are not a substitute for application-level
database backups.

## 1. Create and secure the droplet

Create an Ubuntu 24.04 LTS amd64 droplet with an SSH key and optional
DigitalOcean backups. Log in as root, patch it, and create the operator account:

```sh
apt update
apt upgrade -y
apt install -y curl sqlite3 unattended-upgrades
adduser deploy
usermod -aG sudo deploy
install -d -o deploy -g deploy -m 0700 /home/deploy/.ssh
install -o deploy -g deploy -m 0600 \
  /root/.ssh/authorized_keys \
  /home/deploy/.ssh/authorized_keys
```

These commands copy only the public keys that DigitalOcean placed in root's
`authorized_keys`; they do not copy a private SSH key from the operator's
computer. The named account keeps routine work unprivileged and makes privilege
escalation explicit even though `deploy` can administer the machine with
`sudo`.

Verify `ssh deploy@DROPLET_IP` in a second terminal before disabling direct
root login:

```sh
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
sudo sshd -t
sudo systemctl restart ssh
```

## 2. Establish the tailnet

There is no separate network-creation form. If the organisation does not
already have a tailnet:

1. Open [Tailscale Get Started](https://tailscale.com/start) and sign in with
   the identity provider that should own the deployment. The first sign-in
   creates the tailnet. A company-domain identity is appropriate for an
   organisation; a public email identity creates a personal tailnet.
2. Choose **Business use** or **Personal use** when prompted, install Tailscale
   on the operator's computer, and authenticate it with the same account.
3. Open the [admin console](https://login.tailscale.com/admin). MagicDNS is
   enabled by default; keep it enabled. Optionally give the tailnet a clearer
   display name under **Settings > General**.
4. Open **Users** and invite every person who should use the CRM. Users outside
   the tailnet's identity-provider domain can be invited by email or with a
   one-time invitation link.

If an appropriate organisational tailnet already exists, use it instead of
creating another one and complete only the user and policy steps.

Before joining the server, open **Access controls** in the admin console and
define `tag:enquiry-crm-app`. This example grants CRM HTTPS to explicit users
and requires administrators to reauthenticate for SSH:

```json
{
  "groups": {
    "group:crm-users": [
      "owner@example.com",
      "colleague@example.com"
    ]
  },
  "tagOwners": {
    "tag:enquiry-crm-app": ["autogroup:admin"]
  },
  "grants": [
    {
      "src": ["group:crm-users"],
      "dst": ["tag:enquiry-crm-app"],
      "ip": ["tcp:443"]
    },
    {
      "src": ["autogroup:admin"],
      "dst": ["tag:enquiry-crm-app"],
      "ip": ["tcp:22"]
    }
  ],
  "ssh": [
    {
      "action": "check",
      "src": ["autogroup:admin"],
      "dst": ["tag:enquiry-crm-app"],
      "users": ["deploy"],
      "checkPeriod": "12h"
    }
  ]
}
```

Adjust the users and groups to match the tailnet. Grants are deny-by-default,
and Tailscale SSH needs both the TCP 22 grant and the `ssh` rule.

Install and join Tailscale:

```sh
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --advertise-tags=tag:enquiry-crm-app
```

Confirm the machine tag and key-expiry status in the Tailscale admin console.
From a second tailnet device, verify Tailscale SSH before closing public SSH:

```sh
tailscale status
ssh deploy@DROPLET_MAGICDNS_NAME
```

Then close the host firewall:

```sh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0
sudo ufw enable
```

Use a DigitalOcean Cloud Firewall as a second layer: allow inbound UDP 41641,
allow outbound traffic, and do not expose TCP 22, 80, 443, or 8000.

## 3. Create a release

Run the **Release** workflow manually. It:

1. runs the Roc checks and integration tests;
2. derives an immutable release ID from the commit's UTC timestamp and
   12-character Git SHA, such as `20260730T063147Z-296cd4791967`;
3. builds `enquiry-crm-RELEASE_ID-x64-linux.tar.gz`;
4. extracts the archive and installs it into the production filesystem layout
   on an Ubuntu 24.04 runner;
5. runs the admin, systemd, Playwright, and Tailscale-authentication tests
   against the extracted release;
6. rehearses the documented backup, activation, migration, and restart
   sequence; and
7. creates `release-RELEASE_ID` and publishes the archive only after all checks
   pass.

The commit timestamp makes release IDs chronologically readable, while the SHA
identifies the source exactly. Rebuilding the same commit derives the same ID.

To build the same release locally:

```sh
RELEASE_ID="$(ci/release_id.sh)" roc scripts/tasks.roc release
```

The Roc compiler cross-builds the x64 Linux executables, so this command also
works on macOS.

## 4. First installation

Download the release archive and `SHA256SUMS`, then copy them to the server:

```sh
scp enquiry-crm-RELEASE_ID-x64-linux.tar.gz SHA256SUMS \
  deploy@DROPLET_MAGICDNS_NAME:
ssh deploy@DROPLET_MAGICDNS_NAME
```

Replace `RELEASE_ID` in these commands with the ID in the downloaded archive
name.

Verify the archive before extracting it:

```sh
sha256sum --check SHA256SUMS
tar -xzf enquiry-crm-RELEASE_ID-x64-linux.tar.gz
```

Create the dedicated runtime account and filesystem layout:

```sh
sudo adduser \
  --system \
  --group \
  --home /var/lib/enquiry-crm \
  --no-create-home \
  enquiry-crm

sudo install -d -o root -g root -m 0755 /opt/enquiry-crm/releases
sudo install -d -o root -g root -m 0755 /etc/enquiry-crm
sudo install -d -o enquiry-crm -g enquiry-crm -m 0700 /var/lib/enquiry-crm

sudo mv enquiry-crm-RELEASE_ID-x64-linux /opt/enquiry-crm/releases/RELEASE_ID
sudo chown -R root:root /opt/enquiry-crm/releases/RELEASE_ID
sudo ln -s /opt/enquiry-crm/releases/RELEASE_ID /opt/enquiry-crm/current
```

Install the release's systemd unit and production configuration:

```sh
sudo install -o root -g root -m 0600 \
  /opt/enquiry-crm/current/deploy/enquiry-crm.env.example \
  /etc/enquiry-crm/enquiry-crm.env
sudo install -o root -g root -m 0644 \
  /opt/enquiry-crm/current/deploy/enquiry-crm.service \
  /etc/systemd/system/enquiry-crm.service
sudo systemctl daemon-reload
sudoedit /etc/enquiry-crm/enquiry-crm.env
```

Set `PUBLIC_ORIGIN` to the exact HTTPS MagicDNS origin and set `TZ` to the
workspace timezone. The example already selects the production database,
release assets, and loopback port 8000. An HTTPS origin makes the application
require Tailscale authentication; the only development-authentication form is
an HTTP origin on `127.0.0.1`.

Bootstrap the database and its first member:

```sh
sudo -u enquiry-crm /opt/enquiry-crm/current/bin/enquiry-crm-admin bootstrap \
  --db /var/lib/enquiry-crm/enquiry-crm.sqlite \
  --workspace-name "Example Company" \
  --currency AUD \
  --timezone Australia/Melbourne \
  --member-name "Owner Name" \
  --member-email owner@example.com

sudo -u enquiry-crm /opt/enquiry-crm/current/bin/enquiry-crm-admin schema check \
  --db /var/lib/enquiry-crm/enquiry-crm.sqlite
```

The member email must match the identity supplied in
`Tailscale-User-Login`; matching is case-insensitive.

Start and verify the service:

```sh
sudo systemctl enable --now enquiry-crm
sudo systemctl status enquiry-crm
curl --fail http://127.0.0.1:8000/healthz
```

The service refuses to start when the configured database is missing, has the
wrong schema version, or has a workspace timezone different from `TZ`.

## 5. Enable private HTTPS

Enable HTTPS certificates for the tailnet, then configure the persistent
reverse proxy:

```sh
sudo tailscale serve --bg http://127.0.0.1:8000
tailscale serve status
```

Open `https://DROPLET_MAGICDNS_NAME` from a device logged into the tailnet:

- an active CRM member is signed in automatically;
- a tailnet login absent from the CRM member list receives HTTP 403; and
- tagged source devices without user identity headers receive HTTP 403.

Tailscale Serve removes incoming copies of its identity headers before adding
trusted values. The application additionally rejects multiple, missing,
malformed, inactive, and unknown identities.

To disable the proxy:

```sh
sudo tailscale serve --https=443 off
```

## 6. Member administration

Manage access with the installed admin command rather than editing SQLite:

```sh
sudo -u enquiry-crm /opt/enquiry-crm/current/bin/enquiry-crm-admin members list \
  --db /var/lib/enquiry-crm/enquiry-crm.sqlite

sudo -u enquiry-crm /opt/enquiry-crm/current/bin/enquiry-crm-admin members add \
  --db /var/lib/enquiry-crm/enquiry-crm.sqlite \
  --name "Colleague Name" \
  --email colleague@example.com

sudo -u enquiry-crm /opt/enquiry-crm/current/bin/enquiry-crm-admin members deactivate \
  --db /var/lib/enquiry-crm/enquiry-crm.sqlite \
  --email colleague@example.com

sudo -u enquiry-crm /opt/enquiry-crm/current/bin/enquiry-crm-admin members activate \
  --db /var/lib/enquiry-crm/enquiry-crm.sqlite \
  --email colleague@example.com
```

The tool refuses to deactivate the final active member.

## 7. Upgrade

Upload and verify the new archive, extract it, and place it beside the current
release while the application is still running:

```sh
sha256sum --check SHA256SUMS
tar -xzf enquiry-crm-RELEASE_ID-x64-linux.tar.gz
sudo mv enquiry-crm-RELEASE_ID-x64-linux /opt/enquiry-crm/releases/RELEASE_ID
sudo chown -R root:root /opt/enquiry-crm/releases/RELEASE_ID
```

Stop the application before taking the backup. Uptime is less important than a
simple, unambiguous database state:

```sh
sudo systemctl stop enquiry-crm

backup_path="/var/backups/enquiry-crm/enquiry-crm-$(date -u +%Y%m%dT%H%M%SZ).sqlite"
sudo install -d -o root -g root -m 0700 /var/backups/enquiry-crm
sudo sqlite3 /var/lib/enquiry-crm/enquiry-crm.sqlite ".backup '$backup_path'"
test "$(sudo sqlite3 "$backup_path" 'PRAGMA integrity_check;')" = "ok"
```

Do not continue unless the integrity check prints `ok`. Activate the release
with a temporary symlink and atomic rename:

```sh
sudo ln -s \
  /opt/enquiry-crm/releases/RELEASE_ID \
  /opt/enquiry-crm/.current-RELEASE_ID
sudo mv -Tf /opt/enquiry-crm/.current-RELEASE_ID /opt/enquiry-crm/current

sudo install -o root -g root -m 0644 \
  /opt/enquiry-crm/current/deploy/enquiry-crm.service \
  /etc/systemd/system/enquiry-crm.service
sudo systemctl daemon-reload

sudo -u enquiry-crm /opt/enquiry-crm/current/bin/enquiry-crm-admin migrate \
  --db /var/lib/enquiry-crm/enquiry-crm.sqlite
sudo -u enquiry-crm /opt/enquiry-crm/current/bin/enquiry-crm-admin schema check \
  --db /var/lib/enquiry-crm/enquiry-crm.sqlite

sudo systemctl start enquiry-crm
sudo systemctl status enquiry-crm
curl --fail http://127.0.0.1:8000/healthz
sed -n '1p' /opt/enquiry-crm/current/RELEASE_ID
```

If activation, migration, schema validation, startup, or the health check
fails, leave the service stopped and preserve the database backup and both
release directories for diagnosis.

## 8. Rollback

Application and database rollback are separate operations:

- If the migration did not change the schema, stop the service, point
  `/opt/enquiry-crm/current` back to the previous release with the same
  temporary-link-and-rename sequence, install that release's systemd unit, run
  its schema check, and start it.
- If the schema changed incompatibly, stop the service, preserve the failed
  database for diagnosis, restore the verified pre-upgrade backup with owner
  `enquiry-crm:enquiry-crm` and mode `0600`, activate the previous release,
  run its schema check, and start it.

Never start an older application against a migrated database unless the
release notes explicitly confirm compatibility.

## Source references

- [Tailscale Serve and identity headers](https://tailscale.com/docs/features/tailscale-serve)
- [Tailscale Serve CLI](https://tailscale.com/docs/reference/tailscale-cli/serve)
- [Tailnet policy syntax](https://tailscale.com/docs/reference/syntax/policy-file)
- [Grant syntax](https://tailscale.com/docs/reference/syntax/grants)
- [Device tags](https://tailscale.com/docs/features/tags)
- [HTTPS certificates](https://tailscale.com/docs/how-to/set-up-https-certificates)
