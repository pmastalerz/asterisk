# asterisk

[![CI](https://github.com/pmastalerz/asterisk/actions/workflows/ci.yml/badge.svg)](https://github.com/pmastalerz/asterisk/actions/workflows/ci.yml)
[![Release](https://github.com/pmastalerz/asterisk/actions/workflows/release.yml/badge.svg)](https://github.com/pmastalerz/asterisk/actions/workflows/release.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-pmastalerz%2Fasterisk-blue)](https://github.com/pmastalerz/asterisk/pkgs/container/asterisk)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)

Universal **Asterisk LTS** Docker image built **from official sources**, with **Unraid** packaging (OCI labels + Dockerman template).

General-purpose Asterisk container. Dialplans and endpoints live in your config volume — not in image defaults.

```bash
docker pull ghcr.io/pmastalerz/asterisk:latest
```

## Config vs rebuild

For normal use you only need:

1. **Bind-mounted config** under `/etc/asterisk` (and optionally data/log/spool)
2. **Env** — `PUID` / `PGID` / `TZ` / optional `ASTERISK_ARGS`

You do **not** rebuild the image to add endpoints, dialplan, or passwords.

| Change | How |
| --- | --- |
| Extensions, PJSIP, dialplan, RTP range | Edit files in the config volume |
| Timezone / file ownership | `TZ`, `PUID`, `PGID` |
| Extra `asterisk` CLI flags | `ASTERISK_ARGS` (e.g. `-g`) |
| New Asterisk release | Bump `VERSION` → **rebuild** |
| Extra compile-time modules | Edit `build/menuselect-config.sh` → **rebuild** |
| DAHDI / telephony hardware | Out of scope (or extend menuselect) |

Build profile: **PJSIP**, **SRTP**, **WebSocket** hooks, common audio codecs (**G.722**, ulaw/alaw, speex when available), portable binaries (no `BUILD_NATIVE`). Video (VP8/H.264) is typically **passthrough** via endpoint `allow=`. See [`examples/softphone-vpn/`](examples/softphone-vpn/).

ODBC / database modules are disabled by default so container logs stay clean.

## What you get

1. **Reproducible source build** — official `asterisk-VERSION.tar.gz` from [downloads.asterisk.org](https://downloads.asterisk.org/pub/telephony/asterisk/)
2. **Documented menuselect** — [`build/menuselect-config.sh`](build/menuselect-config.sh)
3. **Slim Debian runtime** — multi-stage image, healthcheck, `PUID`/`PGID`/`TZ`
4. **Unraid** — Dockerman labels + [`unraid/my-asterisk.xml`](unraid/my-asterisk.xml)
5. **Safe first-run seed** — overlays + Asterisk samples only where files are missing
6. **Examples** — [`examples/`](examples/) to copy into appdata
7. **CI** — image build + smoke tests on every PR; releases publish to GHCR

## Image tags

| Tag | Meaning |
| --- | --- |
| `latest` | Latest successful build from `main` |
| `sha-<commit>` | Immutable build for a specific commit |
| `vX.Y.Z` | Git release tag |
| `22.11.0` etc. | Upstream Asterisk version (from `VERSION`) |

```bash
docker pull ghcr.io/pmastalerz/asterisk:latest
docker pull ghcr.io/pmastalerz/asterisk:22.11.0
```

## Quick start

```bash
docker pull ghcr.io/pmastalerz/asterisk:latest
mkdir -p config data log spool
docker run -d --name asterisk --network host \
  -e PUID=1000 -e PGID=1000 -e TZ=Europe/Warsaw \
  -v "$PWD/config:/etc/asterisk" \
  -v "$PWD/data:/var/lib/asterisk" \
  -v "$PWD/log:/var/log/asterisk" \
  -v "$PWD/spool:/var/spool/asterisk" \
  ghcr.io/pmastalerz/asterisk:latest
```

Or with Compose (see [`docker-compose.yml`](docker-compose.yml)):

```bash
cp -n .env.example .env
mkdir -p config data log spool
# Point compose at the published image, or build locally (below)
docker compose up -d
```

CLI:

```bash
docker exec -it asterisk asterisk -rvvv
```

## Network notes

### Host network (often easiest on Unraid)

```yaml
network_mode: host
```

### Bridge network

Publish signalling (`5060/udp`, usually `5060/tcp`) and your RTP range from `rtp.conf` (default overlay: `10000–20000/udp`). Set `external_media_address` / `external_signaling_address` in PJSIP when NAT requires it.

## Build locally

```bash
export ASTERISK_VERSION="$(cat VERSION)"

docker build \
  --build-arg ASTERISK_VERSION="$ASTERISK_VERSION" \
  --build-arg VERSION=dev \
  --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -t asterisk:dev .

./scripts/smoke-test.sh asterisk:dev
```

Optional: `ASTERISK_JOBS=4` build-arg to cap compile parallelism.

## Environment

| Variable | Default | Description |
| --- | --- | --- |
| `PUID` / `PGID` | `1000` / `1000` | Ownership for bind-mounted paths (Unraid often `99` / `100`) |
| `TZ` | `Europe/Warsaw` | Timezone |
| `ASTERISK_ARGS` | _(empty)_ | Extra flags inserted after `asterisk` (e.g. `-g`) |
| `VERSION` | set at build | Image label / startup log |
| `ASTERISK_VERSION` | set at build | Upstream Asterisk version |

## Unraid

1. Pull `ghcr.io/pmastalerz/asterisk:latest` (or build on the host)
2. Docker → Add Container (or install the user template)
3. Prefer **Host** network unless you need bridge + port maps
4. Map appdata paths as in the template
5. Set `PUID` / `PGID` / `TZ`
6. Configure Asterisk under the `/etc/asterisk` appdata path

Copy [`unraid/my-asterisk.xml`](unraid/my-asterisk.xml) to `/boot/config/plugins/dockerMan/templates-user/`.

## Layout

```text
.
├── Dockerfile
├── VERSION
├── build/menuselect-config.sh
├── scripts/smoke-test.sh
├── examples/
├── root/
│   ├── entrypoint.sh
│   ├── app/seed-config.sh
│   └── defaults/asterisk/
├── docker-compose.yml
├── .env.example
├── unraid/my-asterisk.xml
└── .github/workflows/
```

### What gets seeded

On first start (empty config volume):

1. Overlays from `/defaults/asterisk` (paths, logging, RTP, module noloads)
2. Remaining missing files from Asterisk’s sample tree (`/etc/asterisk.default`)

## Customizing the build

- Bump Asterisk: edit `VERSION` (must exist on [downloads.asterisk.org](https://downloads.asterisk.org/pub/telephony/asterisk/))
- Modules: edit `build/menuselect-config.sh`
- Packaging overlays: edit `root/defaults/asterisk/`

## CI / releases

- **Pull requests** — [`.github/workflows/ci.yml`](.github/workflows/ci.yml) builds the image and runs [`scripts/smoke-test.sh`](scripts/smoke-test.sh). Required status checks gate merges on `main`.
- **`main` / tags `v*`** — [`.github/workflows/release.yml`](.github/workflows/release.yml) re-tests, pushes multi-arch images to GHCR, and creates a GitHub Release for version tags.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Security reports: [SECURITY.md](SECURITY.md).

## License

Packaging and scripts in this repository are licensed under [GPL-2.0](LICENSE), consistent with Asterisk.

## Credits

- [Asterisk](https://www.asterisk.org/) / [Sangoma](https://www.sangoma.com/) — PBX sources
