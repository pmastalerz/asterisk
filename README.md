# asterisk

[![CI](https://github.com/pmastalerz/asterisk/actions/workflows/ci.yml/badge.svg)](https://github.com/pmastalerz/asterisk/actions/workflows/ci.yml)
[![Lint](https://github.com/pmastalerz/asterisk/actions/workflows/lint.yml/badge.svg)](https://github.com/pmastalerz/asterisk/actions/workflows/lint.yml)
[![Release](https://github.com/pmastalerz/asterisk/actions/workflows/release.yml/badge.svg)](https://github.com/pmastalerz/asterisk/actions/workflows/release.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-pmastalerz%2Fasterisk-blue)](https://github.com/pmastalerz/asterisk/pkgs/container/asterisk)
[![Asterisk](https://img.shields.io/badge/Asterisk-22.11.0-orange)](VERSION)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)

Asterisk LTS as a Docker image, built from [official sources](https://downloads.asterisk.org/pub/telephony/asterisk/), with Unraid-friendly packaging, SHA-256-verified tarballs, Sigstore build provenance, and automated upstream release discovery.

```bash
docker pull ghcr.io/pmastalerz/asterisk:latest
```

## Quick start

```bash
mkdir -p config db keys sounds log spool
docker run -d --name asterisk --network host \
  -e PUID=1000 -e PGID=1000 -e TZ=Europe/Warsaw \
  -v "$PWD/config:/etc/asterisk" \
  -v "$PWD/db:/var/lib/asterisk/db" \
  -v "$PWD/keys:/var/lib/asterisk/keys" \
  -v "$PWD/sounds:/var/lib/asterisk/sounds" \
  -v "$PWD/log:/var/log/asterisk" \
  -v "$PWD/spool:/var/spool/asterisk" \
  ghcr.io/pmastalerz/asterisk:latest

docker exec -it asterisk asterisk -rvvv
```

Do **not** bind-mount the entire `/var/lib/asterisk` — that hides image files such as `documentation/` and Asterisk will exit on start. Persist only mutable subdirs (`db`, `keys`, `sounds`).

Compose: copy [`.env.example`](.env.example) → `.env`, then `docker compose up -d`.

## Tags

| Tag | Meaning |
| --- | --- |
| `latest` | Current image from `main` (moves) |
| `22.11.0` | Upstream Asterisk version, moves with `main` |
| `22.11.0_debian-bookworm` | Same image with explicit distro suffix (future-compatible) |
| `22`, `22.11` | Rolling packaging-SemVer aliases |
| `sha-…` | Immutable build for a git commit |
| `vX.Y.Z` | GitHub release tag (immutable packaging release) |

Every pushed image carries [OCI build provenance](https://docs.github.com/en/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds) signed via Sigstore. Verify with:

```bash
gh attestation verify \
  oci://ghcr.io/pmastalerz/asterisk:latest \
  --repo pmastalerz/asterisk
```

## Configuration

Put your dialplan / PJSIP / RTP settings in the bind-mounted `/etc/asterisk` volume. You do **not** rebuild the image to add endpoints or passwords.

| Variable                  | Default             | Purpose |
| ------------------------- | ------------------- | --- |
| `PUID` / `PGID`           | `1000` / `1000`     | File ownership (Unraid often `99` / `100`) |
| `TZ`                      | `Europe/Warsaw`     | Timezone |
| `ASTERISK_ARGS`           | _(empty)_           | Extra `asterisk` flags appended after the executable (e.g. `-g`) |
| `ASTERISK_TERMINAL_OPTS`  | _(unset → keep `-W`)_ | Replaces the `-W` token in CMD. `""` drops it, `"-B"` for dark backgrounds, `"-n"` disables colors |

Asterisk runs as the `asterisk` user (uid/gid = `PUID`/`PGID`); the entrypoint drops root via `-U asterisk -p` in CMD.

On first start, missing files under `/etc/asterisk` are seeded from overlays + Asterisk samples. If you bind the whole `/var/lib/asterisk`, the entrypoint also seeds `documentation/` from the image so Stasis can start.

### `*.conf.template` rendering (envsubst)

Every runtime image ships `gettext-base`. Drop `*.conf.template` files into your bind-mounted `/etc/asterisk/` and the entrypoint renders them via `envsubst` on start:

```ini
; /etc/asterisk/pjsip.conf.template
[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060
external_media_address=${EXTERNAL_IP}
external_signaling_address=${EXTERNAL_IP}
```

```bash
docker run -d -e EXTERNAL_IP=203.0.113.42 …
```

`envsubst` only substitutes plain `${VAR}` / `$VAR` — no bash parameter expansion.

### Networking

Host mode is simplest for SIP + RTP. On bridge, publish `5060/udp` (and usually `5060/tcp`) plus your RTP range from `rtp.conf` (default overlay: `10000–20000/udp`).

**Profile:** PJSIP, SRTP, WebSocket hooks, G.722 / ulaw / alaw (speex when available). Bundled sound packs are not included — mount sounds under `/var/lib/asterisk/sounds` if you need them. Example softphone config: [`examples/softphone-vpn/`](examples/softphone-vpn/).

## Unraid

1. Pull `ghcr.io/pmastalerz/asterisk:latest`
2. Add container from [`unraid/my-asterisk.xml`](unraid/my-asterisk.xml) (copy to `/boot/config/plugins/dockerMan/templates-user/`)
3. Prefer **host** network; set `PUID` / `PGID` / `TZ`
4. Map **config** + **db** / **keys** / **sounds** (not the whole `lib` tree)
5. Edit dialplan/PJSIP under the `/etc/asterisk` appdata path

## Build from source

```bash
cp .env.example .env
make build    # compiles Asterisk (slow)
make smoke
```

Upstream pin: `VERSION` + `ASTERISK_SHA256`. Module profile: [`build/menuselect-config.sh`](build/menuselect-config.sh). The Dockerfile requires **both** as build-args (no defaults) so you can't silently ship a stale version.

A daily `Discover upstream Asterisk` workflow watches downloads.asterisk.org for new 22.x releases and opens a PR bumping both files automatically.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — Conventional Commits are enforced (release-please auto-manages the packaging version + [CHANGELOG.md](CHANGELOG.md)). Security: [SECURITY.md](SECURITY.md).

## License

[GPL-2.0](LICENSE) (same family as Asterisk).

Asterisk is a trademark of [Sangoma](https://www.sangoma.com/) / [Asterisk.org](https://www.asterisk.org/).
