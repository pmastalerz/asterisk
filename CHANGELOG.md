# Changelog

Notable changes to this packaging repository. Upstream Asterisk is pinned via `VERSION` / `ASTERISK_SHA256`.

## Unreleased

- Treat `root/**` as an image publish trigger so packaging stays aligned with `main`
- Slim user-facing README; move release policy into CONTRIBUTING

## 0.1.1 — 2026-09-08

- SHA-256 verification of the Asterisk tarball
- Faster builds: no bundled sound packs / `format_mp3`; strip binaries
- Native `amd64` + `arm64` release builders
- `/healthcheck.sh`, Makefile, ShellCheck on PRs

## 0.1.0 — 2026-09-08

- Initial public image, Unraid template, examples, CI smoke + GHCR publish
