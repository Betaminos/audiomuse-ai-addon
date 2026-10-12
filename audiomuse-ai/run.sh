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

# Run the bundled stack (web UI + workers + embedded PostgreSQL) as the
# service user. PYTHONUNBUFFERED makes the launcher's own status lines
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
