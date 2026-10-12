# audiomuse-ai-addon

Home Assistant OS add-on packaging [AudioMuse-AI](https://github.com/NeptuneHub/AudioMuse-AI)
for **ARM64 (Raspberry Pi 5)**. Uses the official native `aarch64` Linux build,
which bundles the entire stack (embedded PostgreSQL, web UI, workers) — no
external database, no compilation, and no music-folder mounts: it reads your
library through Navidrome's API.

## Install

1. Add this repository in HA: **Settings → Add-ons → Add-on Store → ⋮ →
   Manage add-on repositories**.
2. Install **AudioMuse-AI** and start it.
3. Open `http://<pi-ip>:8000`, run the Setup Wizard (point it at your
   Navidrome), and start the first analysis.
4. Pair it with the
   [AudioMuse-AI Navidrome plugin](https://github.com/NeptuneHub/AudioMuse-AI-NV-plugin)
   for Instant Mix and similar songs in all Subsonic clients.

## Third-party licenses

- **AudioMuse-AI** © NeptuneHub —
  [AGPL-3.0](https://github.com/NeptuneHub/AudioMuse-AI/blob/main/LICENSE).
  Source: <https://github.com/NeptuneHub/AudioMuse-AI> (this image embeds an
  unmodified build of tag `v3.6.3`).
- **AudioMuse-AI Navidrome plugin** © NeptuneHub — AGPL-3.0. Not distributed by
  this repository; users download `audiomuseai.ndp` from the upstream releases.

## Packaging files disclosure

The packaging files in this repository (Dockerfile, `run.sh`, workflow, JSON
configs) were written by an LLM at my direction; I reviewed, adjusted, and
tested them. I make no copyright claim over them — treat them as public
domain, reuse freely, no attribution required.
