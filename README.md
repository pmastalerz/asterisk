# asterisk

[![CI](https://github.com/pmastalerz/asterisk/actions/workflows/ci.yml/badge.svg)](https://github.com/pmastalerz/asterisk/actions/workflows/ci.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-pmastalerz%2Fasterisk-blue)](https://github.com/pmastalerz/asterisk/pkgs/container/asterisk)
[![Asterisk](https://img.shields.io/badge/Asterisk-22.11.0-orange)](VERSION)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)

Asterisk LTS as a Docker image, built from [official sources](https://downloads.asterisk.org/pub/telephony/asterisk/), with Unraid-friendly packaging.

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
| `latest` | Current image from `main` |
| `22.11.0` | Upstream Asterisk version (`VERSION`) |
| `sha-…` | Immutable build for a git commit |
| `vX.Y.Z` | GitHub release tag |

## Configuration

Put your dialplan / PJSIP / RTP settings in the bind-mounted `/etc/asterisk` volume. You do **not** rebuild the image to add endpoints or passwords.

| Variable | Default | Purpose |
| --- | --- | --- |
| `PUID` / `PGID` | `1000` / `1000` | File ownership (Unraid often `99` / `100`) |
| `TZ` | `Europe/Warsaw` | Timezone |
| `ASTERISK_ARGS` | _(empty)_ | Extra `asterisk` flags (e.g. `-g`) |

On first start, missing files under `/etc/asterisk` are seeded from overlays + Asterisk samples. If you still bind the whole `/var/lib/asterisk`, the entrypoint also seeds `documentation/` from the image so Stasis can start.

**Network:** host mode is simplest for SIP + RTP. On bridge, publish `5060/udp` (and usually `5060/tcp`) plus your RTP range from `rtp.conf` (default overlay: `10000–20000/udp`).

**Profile:** PJSIP, SRTP, WebSocket hooks, G.722 / ulaw / alaw (speex when available). Bundled sound packs are not included — mount sounds under `/var/lib/asterisk/sounds` if you need them. Example softphone config: [`examples/softphone-vpn/`](examples/softphone-vpn/).

## Unraid

1. Pull `ghcr.io/pmastalerz/asterisk:latest`
2. Add container from [`unraid/my-asterisk.xml`](unraid/my-asterisk.xml) (copy to `/boot/config/plugins/dockerMan/templates-user/`)
3. Prefer **host** network; set `PUID` / `PGID` / `TZ`
4. Map **config** + **db** / **keys** / **sounds** (not the whole `lib` tree)
5. Edit dialplan/PJSIP under the `/etc/asterisk` appdata path

## Build from source

```bash
make build    # compiles Asterisk (slow)
make smoke
```

Upstream pin: `VERSION` + `ASTERISK_SHA256`. Module profile: [`build/menuselect-config.sh`](build/menuselect-config.sh).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Security: [SECURITY.md](SECURITY.md). Changelog: [CHANGELOG.md](CHANGELOG.md).

## License

[GPL-2.0](LICENSE) (same family as Asterisk).

Asterisk is a trademark of [Sangoma](https://www.sangoma.com/) / [Asterisk.org](https://www.asterisk.org/).
