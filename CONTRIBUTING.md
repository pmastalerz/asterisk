# Contributing

Thanks for taking an interest in this project.

## Ways to help

- Report bugs and rough edges via [GitHub Issues](https://github.com/pmastalerz/asterisk/issues)
- Improve docs, examples, or Unraid packaging
- Propose menuselect / packaging changes that keep the image general-purpose

## Development workflow

1. Fork the repo and create a branch from `main`
2. Make focused changes (prefer one concern per PR)
3. Test locally when possible:

   ```bash
   # Fast: smoke against the published image
   docker pull ghcr.io/pmastalerz/asterisk:latest
   ./scripts/smoke-test.sh ghcr.io/pmastalerz/asterisk:latest

   # Full rebuild only when changing Dockerfile / menuselect / VERSION
   export ASTERISK_VERSION="$(cat VERSION)"
   docker build \
     --build-arg ASTERISK_VERSION="$ASTERISK_VERSION" \
     --build-arg VERSION=dev \
     --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     -t asterisk:dev .
   ./scripts/smoke-test.sh asterisk:dev
   ```

4. Open a pull request against `main`

CI on PRs pulls `ghcr.io/pmastalerz/asterisk:latest` and runs smoke tests (no compile).
Image rebuilds happen in the Release workflow after merge when image sources change.
Required checks must pass before merge.

## Scope guidelines

| In scope | Out of scope (unless discussed) |
| --- | --- |
| Packaging, entrypoint, defaults, docs | Full PBX feature forks of Asterisk |
| Documented menuselect profile tweaks | DAHDI / telephony hardware stacks |
| Example configs under `examples/` | Bundling production secrets or real credentials |

Bump `VERSION` only when targeting a published tarball from [downloads.asterisk.org](https://downloads.asterisk.org/pub/telephony/asterisk/).

## Code of conduct

Be respectful. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

Contributions are accepted under the [GPL-2.0](LICENSE) license (same as Asterisk).
