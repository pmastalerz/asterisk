# Changelog

All notable changes to this **packaging repository** are tracked here.
This file is maintained by [release-please](https://github.com/googleapis/release-please)
from [Conventional Commit](https://www.conventionalcommits.org/) PR titles —
please do not edit it by hand.

Upstream Asterisk is pinned via `VERSION` / `ASTERISK_SHA256`, tracked
independently of the packaging SemVer below.

<!-- release-please -->

## [0.3.1](https://github.com/pmastalerz/asterisk/compare/v0.3.0...v0.3.1) (2026-09-09)


### Bug Fixes

* **ci:** dependabot title prefix + smoke-test capability tolerance ([#16](https://github.com/pmastalerz/asterisk/issues/16)) ([20e85f3](https://github.com/pmastalerz/asterisk/commit/20e85f3156746be873d2c8964c2f7c4b31626088))
* **lint:** disable markdownlint MD060 (table-column-style) ([#20](https://github.com/pmastalerz/asterisk/issues/20)) ([c704f20](https://github.com/pmastalerz/asterisk/commit/c704f2093e8caecaf055d565b4b1f9b9f68a46c7))
* **release:** dispatch Release workflow for new tag from release-please ([#18](https://github.com/pmastalerz/asterisk/issues/18)) ([e2c05b6](https://github.com/pmastalerz/asterisk/commit/e2c05b64772863207fb6092a0b3c6014d4d8cf41))
* **release:** drop 'Append image info' step, emit run summary instead ([#21](https://github.com/pmastalerz/asterisk/issues/21)) ([beb9f1e](https://github.com/pmastalerz/asterisk/commit/beb9f1e9aad2e23263176bb34b428d4f16c29230))
* **scripts,scan:** correct upstream sha256 URL + trivy-action ref ([#22](https://github.com/pmastalerz/asterisk/issues/22)) ([d0e6669](https://github.com/pmastalerz/asterisk/commit/d0e66697fa41be23a63bd0b4ebc45711ec24fca4))

## [0.3.0](https://github.com/pmastalerz/asterisk/compare/v0.2.0...v0.3.0) (2026-09-08)


### ⚠ BREAKING CHANGES

* automate releases (release-please), harden supply chain, add runtime UX ([#13](https://github.com/pmastalerz/asterisk/issues/13))

### Features

* automate releases (release-please), harden supply chain, add runtime UX ([#13](https://github.com/pmastalerz/asterisk/issues/13)) ([b780850](https://github.com/pmastalerz/asterisk/commit/b78085057ab7d82a0b037f7b58ed905076de5c86))

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
