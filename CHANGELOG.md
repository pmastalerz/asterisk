# Changelog

All notable changes to this packaging repository are documented here.
Upstream Asterisk releases are tracked via the `VERSION` / `ASTERISK_SHA256` files.

## Unreleased

- Verify official Asterisk tarball SHA-256 during image builds
- Skip bundled sound packs / MP3 fetch to speed compiles and shrink the image
- Strip binaries after `make install`
- Dedicated `/healthcheck.sh`
- Native `amd64` + `arm64` release builders (no QEMU)
- ShellCheck on PRs, Makefile helpers, changelog

## 0.1.0 — 2026-09-08

- Initial public packaging: Debian multi-stage image, Unraid template, examples
- CI smoke tests against GHCR; Release publishes multi-arch images
- Compile-gated rebuilds on `VERSION` / Dockerfile / `build/**` changes
