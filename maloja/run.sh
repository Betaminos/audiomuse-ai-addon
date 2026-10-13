#!/bin/bash
set -euo pipefail

# The Supervisor writes the add-on's configured options to /data/options.json.
# The password is deliberately not baked anywhere in the repo or image — it is
# set in the add-on Configuration UI and only ever exists in your HAOS config
# and this runtime file. Without it, admin mode would be unprotected, so the
# add-on refuses to start instead.
PASSWORD=""
if [ -f /data/options.json ]; then
    PASSWORD="$(jq -r '.password // empty' /data/options.json 2>/dev/null || true)"
fi
if [ -z "${PASSWORD}" ]; then
    echo "ERROR: Set the admin password on the add-on's Configuration tab, then start again."
    exit 1
fi
export MALOJA_FORCE_PASSWORD="${PASSWORD}"

# Run Maloja directly — exactly the command the upstream s6 service
# (svc-python) would execute. s6-overlay is deliberately bypassed: the HAOS
# Supervisor starts add-on containers with Docker's default init, so /init
# would never be PID 1, and s6-overlay v3 aborts with
# "s6-overlay-suexec: fatal: can only run as pid 1". Running as root is the
# same effective setup as the upstream default (PUID=0/PGID=0 make `abc`
# root there anyway), and /data is the root-owned add-on volume.
# exec keeps this process's PID for Python, so Supervisor stop signals
# (SIGTERM) reach Maloja directly and shut it down cleanly.
exec /venv/bin/python -m maloja run
