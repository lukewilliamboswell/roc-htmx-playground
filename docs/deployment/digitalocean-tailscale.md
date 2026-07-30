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
2. the production service uses `AUTH_MODE=tailscale`; and
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
apt install -y curl rsync sqlite3 unattended-upgrades
adduser deploy
usermod -aG sudo deploy
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy/
```

Verify `ssh deploy@DROPLET_IP` in a second terminal before changing SSH:

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

Create the tailnet with the identity provider appropriate for the organisation,
invite the intended users, and enable MagicDNS. Define
`tag:enquiry-crm-app` before joining the server. This example grants CRM HTTPS
to explicit users and requires administrators to reauthenticate for SSH:

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

Update `VERSION` and commit it. The file contains the release version in
`MAJOR.MINOR.PATCH` form, for example `0.2.0`.

Run the **Release** workflow manually. It:

1. runs the Roc checks and integration tests;
2. builds `enquiry-crm-VERSION-x64-linux.tar.gz`;
3. extracts the archive and installs it into the production filesystem layout
   on an Ubuntu 24.04 runner;
4. runs the admin, systemd, Playwright, and Tailscale-authentication tests
   against the extracted release;
5. rehearses the documented backup, activation, migration, and restart
   sequence; and
6. creates `vVERSION` and publishes the archive only after all checks pass.

To build the same release locally:

```sh
RELEASE_VERSION="$(sed -n '1p' VERSION)" roc scripts/tasks.roc release
```

The Roc compiler cross-builds the x64 Linux executables, so this command also
works on macOS.

## 4. First installation

Download the release archive and `SHA256SUMS`, then copy them to the server:

```sh
scp enquiry-crm-0.1.0-x64-linux.tar.gz SHA256SUMS \
  deploy@DROPLET_MAGICDNS_NAME:
ssh deploy@DROPLET_MAGICDNS_NAME
```

Verify the archive before extracting it:

```sh
sha256sum --check SHA256SUMS
tar -xzf enquiry-crm-0.1.0-x64-linux.tar.gz
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

sudo mv enquiry-crm-0.1.0-x64-linux /opt/enquiry-crm/releases/0.1.0
sudo chown -R root:root /opt/enquiry-crm/releases/0.1.0
sudo ln -s /opt/enquiry-crm/releases/0.1.0 /opt/enquiry-crm/current
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
release assets, Tailscale authentication, and loopback port 8000.

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
tar -xzf enquiry-crm-0.2.0-x64-linux.tar.gz
sudo mv enquiry-crm-0.2.0-x64-linux /opt/enquiry-crm/releases/0.2.0
sudo chown -R root:root /opt/enquiry-crm/releases/0.2.0
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
sudo ln -s /opt/enquiry-crm/releases/0.2.0 /opt/enquiry-crm/.current-0.2.0
sudo mv -Tf /opt/enquiry-crm/.current-0.2.0 /opt/enquiry-crm/current

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
sed -n '1p' /opt/enquiry-crm/current/RELEASE_VERSION
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
