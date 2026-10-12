#!/bin/bash
set -euo pipefail

# Persistent add-on data dir. AudioMuse-AI keeps its embedded PostgreSQL
# database and temp audio under $HOME/.local/share/AudioMuse-AI.
DATA_DIR="/data"

mkdir -p "${DATA_DIR}"
chown -R audiomuse:audiomuse "${DATA_DIR}"

# Drop privileges and start the bundled stack (web UI + workers + embedded
# PostgreSQL) as the service user.
exec gosu audiomuse env HOME="${DATA_DIR}" audiomuse-ai start
