#syntax=docker/dockerfile:1
###############################################################################
# HAOS add-on wrapping the pre-compiled upstream Rewind image.
#
# Upstream: https://github.com/BernardoGiordano/rewind (GPL-3.0)
# Base image: bernardogiordano/rewind on Docker Hub — node:22-alpine with the
# built app in /app/dist. The author publishes only a multi-arch `:latest`
# tag (no versioned tags), so the image is pinned by digest for
# reproducibility, Renovate tracking, and rollback.
#
# Update flow: Renovate opens a PR with the new digest whenever :latest is
# republished. Merge → CI bumps the packaging suffix and republishes.
# Rollback: revert the digest to the previous value and rebuild.
#
# Before the very first build, verify the digest is still current:
#   docker buildx imagetools inspect bernardogiordano/rewind:latest
# (the value below was current on 2026-10-15)
###############################################################################

ARG REWIND_IMAGE=bernardogiordano/rewind:latest@sha256:6d02f9edd8a6908270b99e90baa419e9df190bbd39fb38aae55411f3039db6cb
FROM ${REWIND_IMAGE}

# jq is used by run.sh to read the Supervisor-provided add-on options.
# GPL-3.0 compliance: ship the license text alongside the app
# (same pattern as AudioMuse-AI).
RUN apk add --no-cache jq curl \
    && mkdir -p /usr/share/doc/rewind \
    && curl -fsSL -o /usr/share/doc/rewind/LICENSE \
       "https://raw.githubusercontent.com/BernardoGiordano/rewind/master/LICENSE" \
    && apk del curl

COPY run.sh /run.sh
RUN chmod +x /run.sh

# EXPOSE is documentation only — the Supervisor routes traffic via the
# `ports` mapping in config.json. Rewind always listens on 4000 inside the
# container (PORT env is set there).
EXPOSE 4000

# The base image has no ENTRYPOINT (its CMD runs node directly), so a plain
# CMD override is enough — no s6/PID-1 problem like Maloja. run.sh execs
# node, keeping PID semantics for clean SIGTERM shutdown.
CMD ["/run.sh"]
