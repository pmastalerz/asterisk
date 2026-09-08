# Changelog

All notable changes to this **packaging repository** are tracked here.
This file is maintained by [release-please](https://github.com/googleapis/release-please)
from [Conventional Commit](https://www.conventionalcommits.org/) PR titles —
please do not edit it by hand.

Upstream Asterisk is pinned via `VERSION` / `ASTERISK_SHA256`, tracked
independently of the packaging SemVer below.

<!-- release-please -->

## [0.2.0](https://github.com/pmastalerz/asterisk/releases/tag/v0.2.0) — 2026-09-08

### Features

- SHA-256 verification of the Asterisk tarball (`ASTERISK_SHA256`)
- Faster builds: no bundled sound packs / `format_mp3`; strip binaries
- Native `amd64` + `arm64` release builders (no QEMU)
- `/healthcheck.sh`, Makefile, ShellCheck on PRs
- PR CI smokes published GHCR image (no compile on every PR)
- Image rebuild on `main` when `VERSION` / Dockerfile / `build/**` / `root/**` change
- Slimmer user-facing README; release policy in CONTRIBUTING

## [0.1.0](https://github.com/pmastalerz/asterisk/releases/tag/v0.1.0) — 2026-09-08

### Features

- Initial public image, Unraid template, examples, CI smoke + GHCR publish
