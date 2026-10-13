# hassio-addons

Home Assistant OS add-on store for self-hosted music tools around
[Navidrome](https://www.navidrome.org), targeting **ARM64 (Raspberry Pi 5)**.

## Add-ons

### AudioMuse-AI
Sonic analysis, clustering and smart playlists for Navidrome (native aarch64
build with embedded PostgreSQL). Web UI on port 8000. Point it at your
Navidrome via the Setup Wizard, then pair it with the
[AudioMuse-AI Navidrome plugin](https://github.com/NeptuneHub/AudioMuse-AI-NV-plugin)
for Instant Mix in all Subsonic clients.

### Maloja
Self-hosted music scrobble database with listening statistics and charts —
a Spotify Wrapped-style year-in-review, fully local ([krateng/maloja](https://github.com/krateng/maloja)).
Web UI on port 42010 (host port configurable in the add-on's Network
settings). Before first start, set the admin password on the add-on's
Configuration tab — it refuses to start without one.

## Install

1. Settings → Add-ons → Add-on Store → ⋮ → Manage add-on repositories → add
   `https://github.com/betaminos/hassio-addons`.
2. Install the add-on you want, configure, start.

## Wiring AudioMuse-AI to Navidrome

1. Start the AudioMuse-AI add-on and open `http://<pi-ip>:8000`.
2. Run the Setup Wizard: point it at your Navidrome instance (URL and
   credentials), then start the first analysis of your library.
3. Pair it with the
   [AudioMuse-AI Navidrome plugin](https://github.com/NeptuneHub/AudioMuse-AI-NV-plugin)
   (download `audiomuseai.ndp` from the upstream releases and add it in
   Navidrome) to get Instant Mix and similar songs in all Subsonic clients.

## Wiring Maloja to Navidrome

1. Start the Maloja add-on and open `http://<pi-ip>:42010`.
2. In Maloja's settings, create an API key (one per scrobbler is recommended).
3. In Navidrome, set `ListenBrainz.BaseURL` to
   `http://<pi-ip>:42010/apis/listenbrainz/1/` (env: `ND_LISTENBRAINZ_BASEURL`).
4. In Navidrome: user profile → Personal → enable *Scrobble to ListenBrainz*
   and paste the Maloja API key as the token.

Optional: add free Last.fm/Spotify API keys in Maloja's settings to get artist
images in the UI. To backfill history, drop a Last.fm/Spotify/ListenBrainz
export or another Maloja export into the import folder in the add-on data
directory (`/data`).

## Third-party licenses

- **AudioMuse-AI** © NeptuneHub —
  [AGPL-3.0](https://github.com/NeptuneHub/AudioMuse-AI/blob/main/LICENSE).
  Source: https://github.com/NeptuneHub/AudioMuse-AI (this image embeds an
  unmodified build of tag `v3.6.3`).
- **Maloja** © krateng —
  [GPL-3.0](https://github.com/krateng/maloja/blob/master/LICENSE).
  Source: https://github.com/krateng/maloja (this image embeds an unmodified
  copy of the official `krateng/maloja:3.2.7` Docker image).

## Packaging files disclosure

The packaging files in this repository (Dockerfiles, `run.sh`, workflows, JSON
configs) were written by an LLM at my direction; I reviewed, adjusted, and
tested them. I make no copyright claim over them — treat them as public
domain, reuse freely, no attribution required.
