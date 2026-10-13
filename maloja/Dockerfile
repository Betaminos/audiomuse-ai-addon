#syntax=docker/dockerfile:1
###############################################################################
# HAOS add-on wrapping the official multi-arch Maloja image.
#
# Upstream: https://github.com/krateng/maloja (GPL-3.0)
# Base image: krateng/maloja on Docker Hub — Alpine + s6-overlay, Python venv,
# runs Maloja as user `abc` via its svc-python service. Nothing is compiled
# here; this layer only adds jq (for reading the add-on options) plus an
# entrypoint that hands control to the upstream s6 init.
#
# To move to a new Maloja release: bump MALOJA_VERSION, update config.json's
# "version" upstream part, push — CI bumps the packaging suffix and publishes.
###############################################################################

ARG MALOJA_VERSION=3.2.7
FROM krateng/maloja:${MALOJA_VERSION}

# jq is used by run.sh to read the Supervisor-provided add-on options.
RUN apk add --no-cache jq

COPY run.sh /run.sh
RUN chmod +x /run.sh

# Persistent add-on data (scrobble database, settings, custom images) lives
# in the Home Assistant add-on volume.
ENV MALOJA_DATA_DIRECTORY=/data

EXPOSE 42010
CMD ["/run.sh"]
