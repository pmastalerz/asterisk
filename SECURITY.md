# Security policy

## Reporting a vulnerability in this packaging

If you find a security issue **in this repository's packaging** —
Dockerfile, entrypoint, seed scripts, GitHub Actions workflows, or the
build/verify supply chain — please report it privately via
[GitHub Security Advisories](https://github.com/pmastalerz/asterisk/security/advisories/new)
instead of opening a public issue.

We aim to acknowledge within 5 business days and to publish a fix as a
patch release (`vX.Y.Z+1`) once the root cause is confirmed.

### Not in scope

- **Asterisk itself** — report upstream to the Asterisk project
  ([security advisories](https://docs.asterisk.org/Deployment/Asterisk-Security-Vulnerabilities/)).
  We pin an official release, verify its SHA-256, and rebuild when
  upstream ships a security release (bump of `VERSION` +
  `ASTERISK_SHA256`).
- **Debian packages** in the base image (libc, openssl, curl, …) —
  tracked by the Debian security team at
  [security-tracker.debian.org](https://security-tracker.debian.org).
  We can't patch these ourselves. To reduce exposure, every build runs
  `apt-get upgrade` against the current bookworm-security snapshot, so
  freshly built images ship the latest patched packages.

## Supported versions

Only the current `main` line receives updates. Moving tags (`:latest`,
`:22.11.0`, `:22.11.0_debian-bookworm`) always reflect the current
`main`. Immutable tags (`vX.Y.Z`, `sha-…`) are point-in-time artifacts
and do not receive backports.

## Supply chain guarantees

Every published image carries:

- **SHA-256 verification** of the upstream Asterisk tarball — the
  Dockerfile rejects any tarball whose hash does not match the pinned
  value in `ASTERISK_SHA256`.
- **[SLSA](https://slsa.dev/) build provenance** attested via GitHub
  OIDC + [Sigstore](https://www.sigstore.dev/) and pushed alongside
  the image manifest. Verify with:

  ```bash
  gh attestation verify \
    oci://ghcr.io/pmastalerz/asterisk:<tag> \
    --repo pmastalerz/asterisk
  ```

- **SBOM** attached to the image manifest.
- **Automated dependency updates** for GitHub Actions and Docker base
  images via Dependabot; daily upstream Asterisk release discovery.

## What we scan

CI scans **this repository's own files** (Dockerfile, workflows, YAML,
shell scripts) with:

- `hadolint` — Dockerfile best-practices
- `actionlint` — GitHub Actions workflows
- `yamllint` / `markdownlint` — YAML / Markdown style
- `shellcheck` — shell scripts
- `trivy config` — misconfigurations across all of the above

We intentionally do **not** scan the built image for OS-package CVEs.
Those are Debian's responsibility; we consume upstream fixes via
`apt-get upgrade` at build time.
