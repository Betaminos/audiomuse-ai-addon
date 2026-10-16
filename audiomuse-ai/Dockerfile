#syntax=docker/dockerfile:1
###############################################################################
# HAOS add-on wrapping AudioMuse-AI's official native aarch64 build.
#
# The native .deb bundles the whole stack (embedded PostgreSQL, web UI and
# workers), verified on Debian 12 bookworm — the same base image used here.
# Nothing is compiled; the ARM64 build happens in CI and the Pi only pulls
# the finished image.
###############################################################################

FROM debian:bookworm-slim

ARG AUDIOMUSE_VERSION=3.6.4
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gosu \
# Official native build (see https://github.com/NeptuneHub/AudioMuse-AI —
# "Native Deployment", Linux aarch64 .deb)
    && curl -fsSL -o /tmp/audiomuse.deb \
        "https://github.com/NeptuneHub/AudioMuse-AI/releases/download/v${AUDIOMUSE_VERSION}/AudioMuse-AI-aarch64-linux.deb" \
    && apt-get install -y --no-install-recommends /tmp/audiomuse.deb \
    && rm -f /tmp/audiomuse.deb \
# AGPL-3.0 compliance: ship the license text alongside the binary
    && install -d /usr/share/doc/audiomuse-ai \
    && curl -fsSL -o /usr/share/doc/audiomuse-ai/LICENSE \
        "https://raw.githubusercontent.com/NeptuneHub/AudioMuse-AI/v${AUDIOMUSE_VERSION}/LICENSE" \
    && rm -rf /var/lib/apt/lists/* \
# The native build refuses to run as root; the service account runs with
# HOME=/data (the add-on's persistent volume).
    && useradd --no-create-home --home-dir /data audiomuse

COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 8000
CMD ["/run.sh"]
