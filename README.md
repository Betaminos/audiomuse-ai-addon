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
a Spotify Wrapped-style year-in-review, fully local
([krateng/maloja](https://github.com/krateng/maloja)). Web UI on port 42010
(host port configurable in the add-on's Network settings). Before first
start, set the admin password on the add-on's Configuration tab — it refuses
to start without one.

### Rewind

Spotify Wrapped–style listening stats for Navidrome (BernardoGiordano/rewind)
— stories-style yearly recap, top songs/artists/albums/genres, listening
clock, streaks, with music streamed from Navidrome during the slides. Reads
the live Navidrome database directly from the share (read-only). Web UI on
port 42000. Requires the Navidrome add-on on this instance with its data
folder in `/share/navidrome` (`data_folder: /share/navidrome`), so the live
`navidrome.db` is available.

## Install

1. Settings → Add-ons → Add-on Store → ⋮ → Manage add-on repositories → add
   `https://github.com/betaminos/hassio-addons`.
2. Install the add-on you want, configure, start.

## Wiring AudioMuse-AI to Navidrome

1. Start the AudioMuse-AI add-on and open `http://<pi-ip>:8000`.
2. Run the Setup Wizard: point it at your Navidrome instance (URL and
   credentials), then start the first analysis of your library.
3. Pair it with the AudioMuse-AI Navidrome plugin (download `audiomuseai.ndp`
   from the upstream releases and add it in Navidrome) to get Instant Mix
   and similar songs in all Subsonic clients.

## Wiring Maloja to Navidrome

1. Start the Maloja add-on and open `http://<pi-ip>:42010`.
2. In Maloja's settings, create an API key (one per scrobber is recommended).
3. In Navidrome, set `ListenBrainz.BaseURL` to
   `http://<pi-ip>:42010/apis/listenbrainz/1/`
   (env: `ND_LISTENBRAINZ_BASEURL`).
4. In Navidrome: user profile → Personal → enable *Scrobble to ListenBrainz*
   and paste the Maloja API key as the token.

Optional: add free Last.fm/Spotify API keys in Maloja's settings to get artist
images in the UI. To backfill history, drop a Last.fm/Spotify/ListenBrainz
export or another Maloja export into the import folder in the add-on data
directory (`/data`).

## Wiring Rewind to Navidrome

1. Make sure the Navidrome add-on runs with `data_folder: /share/navidrome`
   (the live database then lives at `/share/navidrome/navidrome.db`).
2. On the Rewind add-on's Configuration tab, set `navidrome_url` to your
   Navidrome address (e.g. `http://<pi-ip>:4533`) — needed for cover art,
   music in the slideshows, and manual scrobbles.
3. Start the add-on and open `http://<pi-ip>:42000`.
4. Log in with any Navidrome user (multi-user mode), or set both
   `navidrome_user` and `navidrome_api_key` in the Configuration tab to pin
   Rewind to a single user.

## Update automation

Upstream releases are tracked by a self-hosted
[Renovate](https://github.com/renovatebot/renovate) (AGPL-3.0) instance that
runs as a scheduled GitHub Actions workflow *inside this repository* — no
third-party app is installed, and it accesses the repo only through a
least-privilege, repository-scoped token. When AudioMuse-AI or Maloja
publishes a release, Renovate opens a pull request bumping the version pins
in the affected add-on's `Dockerfile` and `config.json`; merging it triggers
CI to rebuild and publish the image. Renovate itself is build tooling only —
it is not part of any published add-on image or add-on data.

## Third-party licenses

- **AudioMuse-AI** © NeptuneHub —
  [AGPL-3.0](https://github.com/NeptuneHub/AudioMuse-AI/blob/main/LICENSE).
  Source: https://github.com/NeptuneHub/AudioMuse-AI (this image embeds an
  unmodified build of the upstream release pinned in the add-on's
  `config.json`).
- **Maloja** © krateng —
  [GPL-3.0](https://github.com/krateng/maloja/blob/master/LICENSE).
  Source: https://github.com/krateng/maloja (this image embeds an unmodified
  copy of the official `krateng/maloja` Docker image, at the upstream
  release pinned in the add-on's `config.json`).
- **Rewind** © Bernardo Giordano —
  [GPL-3.0](https://github.com/BernardoGiordano/rewind/blob/master/LICENSE).
  Source: https://github.com/BernardoGiordano/rewind (this image embeds an
  unmodified copy of the official `bernardogiordano/rewind` Docker image,
  at the digest pinned in the add-on's `Dockerfile`).

## Packaging files disclosure

The packaging files in this repository (Dockerfiles, `run.sh`, workflows,
Renovate configuration, JSON configs) were written by an LLM at my direction;
I reviewed, adjusted, and tested them. I make no copyright claim over them —
treat them as public domain, reuse freely, no attribution required.
