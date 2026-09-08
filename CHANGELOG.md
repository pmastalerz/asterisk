# Changelog

Notable changes to this packaging repository. Upstream Asterisk is pinned via `VERSION` / `ASTERISK_SHA256`.

## Unreleased

- Prefer binding `db` / `keys` / `sounds` instead of all of `/var/lib/asterisk` (keeps image `documentation/` visible)
- Seed `/var/lib/asterisk/documentation/` if someone still mounts an empty full varlib (Unraid Stasis crash)
## 0.2.0 — 2026-09-08

- SHA-256 verification of the Asterisk tarball (`ASTERISK_SHA256`)
- Faster builds: no bundled sound packs / `format_mp3`; strip binaries
- Native `amd64` + `arm64` release builders (no QEMU)
- `/healthcheck.sh`, Makefile, ShellCheck on PRs
- PR CI smokes published GHCR image (no compile on every PR)
- Image rebuild on `main` when `VERSION` / Dockerfile / `build/**` / `root/**` change
- Slimmer user-facing README; release policy in CONTRIBUTING

## 0.1.0 — 2026-09-08

- Initial public image, Unraid template, examples, CI smoke + GHCR publish
