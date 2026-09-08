# Security Policy

## Supported versions

Security fixes are applied to the current `main` branch and published GHCR images
built from it (`latest` and version tags).

## Reporting a vulnerability

Please **do not** open a public issue for security-sensitive reports.

Instead, use [GitHub Security Advisories](https://github.com/pmastalerz/asterisk/security/advisories/new)
for this repository, or contact the maintainer privately via GitHub.

Include:

- Affected image tag / commit if known
- Description of the issue and impact
- Reproduction steps or proof-of-concept (if safe to share)

We will acknowledge the report and work on a fix as quickly as practical.

## Scope notes

This project packages [Asterisk](https://www.asterisk.org/) from official sources.
Vulnerabilities in upstream Asterisk itself should also be reported to the Asterisk
project; we will bump `VERSION` / rebuild when fixed releases are available.
