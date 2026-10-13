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

# Hand over to the upstream s6-overlay init, which starts Maloja as user
# `abc` via the svc-python service. exec is important: /init must remain
# PID 1 so container stop signals reach s6 and shut Maloja down cleanly.
# Environment exported above is inherited by /init and therefore available
# to the service (this is exactly how the upstream image handles PUID/PGID).
exec /init
