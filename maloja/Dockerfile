#syntax=docker/dockerfile:1
###############################################################################
# HAOS add-on wrapping the official multi-arch Maloja image.
#
# Upstream: https://github.com/krateng/maloja (GPL-3.0)
# Base image: krateng/maloja on Docker Hub — Alpine + s6-overlay, Python venv
# with the app in /venv. Nothing is compiled here; this layer only adds jq
# (for reading the add-on options) and replaces the upstream s6 boot with a
# plain entrypoint — see run.sh for why s6 cannot be used under HAOS.
#
# To move to a new Maloja release: bump MALOJA_VERSION, update config.json's
# "version" upstream part, push — CI bumps the packaging suffix and publishes.
###############################################################################

ARG MALOJA_VERSION=3.2.9
FROM krateng/maloja:${MALOJA_VERSION}

# jq is used by run.sh to read the Supervisor-provided add-on options.
RUN apk add --no-cache jq

COPY run.sh /run.sh
RUN chmod +x /run.sh

# Persistent add-on data (scrobble database, settings, custom images) lives
# in the Home Assistant add-on volume.
ENV MALOJA_DATA_DIRECTORY=/data

# EXPOSE is documentation only — it publishes nothing. The Supervisor routes
# traffic via the `ports` mapping in config.json, whose host side is what the
# add-on's Network section in the GUI edits. Maloja always listens on 42010
# inside the container, so this stays fixed either way.
EXPOSE 42010

# CRITICAL: override the base image's ENTRYPOINT (which is /init from
# s6-overlay). The HAOS Supervisor starts add-on containers with Docker's
# default init enabled, so /init would run as a child of PID 1 and
# s6-overlay v3 refuses to boot with:
#   "s6-overlay-suexec: fatal: can only run as pid 1"
# Overriding ENTRYPOINT boots run.sh directly, which starts Maloja itself.
# Use ENTRYPOINT, not CMD — the inherited ENTRYPOINT /init would swallow the
# CMD as arguments and run.sh would never execute.
ENTRYPOINT ["/run.sh"]
