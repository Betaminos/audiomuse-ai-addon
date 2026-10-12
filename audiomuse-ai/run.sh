#!/bin/bash
set -euo pipefail

# Persistent add-on data dir. AudioMuse-AI keeps its embedded PostgreSQL
# database and temp audio under $HOME/.local/share/AudioMuse-AI.
DATA_DIR="/data"
STATE_DIR="${XDG_STATE_HOME:-${DATA_DIR}/.local/state}"
LOG_DIR="${STATE_DIR}/AudioMuse-AI/logs"
APP_LOG="${LOG_DIR}/audiomuse.log"
CRASH_LOG="${LOG_DIR}/supervisor-crash.log"

# The native build writes virtually all of its output to APP_LOG — newest
# line first, atomically rewriting the file about once per second while
# anything is logged. Two problems for a Pi on an SD card: the HA log view
# would otherwise stay empty, and the constant rewrites hammer the card.
# config.json therefore points XDG_STATE_HOME at the RAM-backed tmpfs, so
# this script mirrors the log from memory into the container console while
# nothing touches the SD card except the (append-only) console output.
mkdir -p "${LOG_DIR}"
chown -R audiomuse:audiomuse "${DATA_DIR}" "${LOG_DIR}"
gosu audiomuse touch "${APP_LOG}" "${CRASH_LOG}"

LAST_TS="$(head -n 1 "${APP_LOG}" | cut -c1-23)"
[ -n "${LAST_TS}" ] || LAST_TS="0000-00-00 00:00:00,000"

# --- WORKAROUND: own the PostgreSQL lifecycle -----------------------------
# The arm64 native build starts embedded PostgreSQL via `pg_ctl -w start`
# with the output captured in a pipe nobody drains. Without `-l`, pg_ctl
# leaves the postmaster attached to that pipe (`2>&1`), so when pg_ctl
# exits after the server becomes ready, the postmaster KEEPS the pipe open
# and the supervisor's subprocess.run() waits for EOF forever — the boot
# hangs right after "=== AudioMuse-AI starting ===" with PostgreSQL fully
# up. PostgreSQL must therefore already be running when the app starts:
# the app then skips its own pg_ctl call entirely.

# Vendored PostgreSQL that ships inside the native build
PG_ROOT="/opt/AudioMuse-AI/_internal/pgsql"
PG_BIN="${PG_ROOT}/bin"
PG_LIB_PATH="${PG_ROOT}/lib:${PG_ROOT}/lib/postgresql"
APP_DIR="${DATA_DIR}/.local/share/AudioMuse-AI"
PGDATA="${APP_DIR}/pgdata"

# 1. Neutralize the app's orphan reaper for this boot: nothing survives a
#    container stop anyway, and the reaper would otherwise terminate the
#    database started below ("reaped ... referencing our data dir").
rm -f "${APP_DIR}/supervisor_pids.json"

# 2. Initialize the cluster on first run (mirrors upstream's own initdb
#    flags and config overrides)
if [ ! -f "${PGDATA}/audiomuse_initialized" ]; then
    gosu audiomuse env HOME="${DATA_DIR}" LD_LIBRARY_PATH="${PG_LIB_PATH}" \
        "${PG_BIN}/initdb" -D "${PGDATA}" -U postgres --auth=trust \
        -E UTF8 --locale=C
    printf "\n# --- AudioMuse-AI embedded overrides ---\nunix_socket_directories = '%s'\nlisten_addresses = ''\n" \
        "${PGDATA}" >> "${PGDATA}/postgresql.conf"
    gosu audiomuse sh -c "echo ok > '${PGDATA}/audiomuse_initialized'"
fi

# 3. Start PostgreSQL ourselves — with -l, so its output goes to a file
#    instead of an undrained pipe.
if ! gosu audiomuse env HOME="${DATA_DIR}" LD_LIBRARY_PATH="${PG_LIB_PATH}" \
        "${PG_BIN}/pg_ctl" -D "${PGDATA}" status >/dev/null 2>&1; then
    rm -f "${PGDATA}/postmaster.pid"
    gosu audiomuse env HOME="${DATA_DIR}" LD_LIBRARY_PATH="${PG_LIB_PATH}" \
        "${PG_BIN}/pg_ctl" -D "${PGDATA}" -w -t 60 \
        -l "${LOG_DIR}/postgres.log" start
fi

# Run the bundled stack (web UI + workers) as the service user.
# PYTHONUNBUFFERED makes the launcher's own status lines
# ("AudioMuse-AI is running at ...", startup failures) appear immediately
# instead of sitting in Python's block buffer.
gosu audiomuse env HOME="${DATA_DIR}" PYTHONUNBUFFERED=1 \
    audiomuse-ai start &
APP_PID=$!

term() { kill -TERM "${APP_PID}" 2>/dev/null || true; }
trap term INT TERM

# Poll the newest-first log file and echo anything new to stdout. Lines are
# matched by their leading timestamp so restarts, duplicates and multi-line
# records are handled; `tac` restores oldest-first reading order.
(
  while true; do
    NEW="$(awk -v t="${LAST_TS}" '
      substr($0, 1, 23) ~ /^[0-9][0-9][0-9][0-9]-/ { cur = substr($0, 1, 23) > t }
      cur { print }
    ' "${APP_LOG}")"
    if [ -n "${NEW}" ]; then
      printf '%s\n' "${NEW}" | tac
      LAST_TS="$(head -n 1 "${APP_LOG}" | cut -c1-23)"
    fi
    sleep 2
  done
) &

# supervisor-crash.log is append-only, so a plain tail -F suffices.
tail -F "${CRASH_LOG}" 2>/dev/null &

RC=0
wait "${APP_PID}" || RC=$?
echo "AudioMuse-AI exited with code ${RC}"
exit "${RC}"
