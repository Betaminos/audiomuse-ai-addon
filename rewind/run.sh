#!/bin/sh
set -eu

# The Supervisor writes the add-on's configured options to /data/options.json.
NAVIDROME_URL="$(jq -r '.navidrome_url' /data/options.json)"
DB_PATH="$(jq -r '.db_path' /data/options.json)"
NAVIDROME_USER="$(jq -r '.navidrome_user // empty' /data/options.json)"
NAVIDROME_API_KEY="$(jq -r '.navidrome_api_key // empty' /data/options.json)"

# Refuse to start if the live database is not there — much clearer than
# Rewind failing on its first query (same guard pattern as the Maloja
# password check).
if [ ! -f "$DB_PATH" ]; then
    echo "ERROR: $DB_PATH not found."
    echo "The Navidrome add-on must use data_folder /share/navidrome so that"
    echo "navidrome.db is visible in the share. Fix that, then start again."
    exit 1
fi
export NAVIDROME_URL DB_PATH NAVIDROME_USER NAVIDROME_API_KEY

# Session secret: use the configured one, else generate once and persist it
# in the add-on's private /data (survives restarts, never in the repo).
SESSION_SECRET="$(jq -r '.session_secret // empty' /data/options.json)"
if [ -z "$SESSION_SECRET" ]; then
    SECRET_FILE=/data/.rewind_session_secret
    if [ ! -s "$SECRET_FILE" ]; then
        tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 40 > "$SECRET_FILE"
        chmod 600 "$SECRET_FILE"
    fi
    SESSION_SECRET="$(cat "$SECRET_FILE")"
fi
export SESSION_SECRET

# Run Rewind — exactly the command the upstream image runs.
# exec keeps this process's PID for Node, so Supervisor stop signals
# (SIGTERM) reach Rewind directly and shut it down cleanly.
cd /app
exec node dist/server/server.js
