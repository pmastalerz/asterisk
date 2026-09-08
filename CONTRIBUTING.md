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
   make smoke-published   # fast — uses GHCR
   make shellcheck
   make build && make smoke   # only when changing VERSION / Dockerfile / menuselect
   ```

4. Open a pull request against `main`

CI on PRs runs ShellCheck and smokes the published image (no compile).
A full image rebuild runs on `main` only when `VERSION`, `ASTERISK_SHA256`, `Dockerfile`,
`.dockerignore`, or `build/**` change (or on version tags / manual Release dispatch).

When bumping Asterisk, update both `VERSION` and `ASTERISK_SHA256` (from
`https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-VERSION.sha256`).

## Scope guidelines

| In scope | Out of scope (unless discussed) |
| --- | --- |
| Packaging, entrypoint, defaults, docs | Full PBX feature forks of Asterisk |
| Documented menuselect profile tweaks | DAHDI / telephony hardware stacks |
| Example configs under `examples/` | Bundling production secrets or real credentials |

## Code of conduct

Be respectful. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

Contributions are accepted under the [GPL-2.0](LICENSE) license (same as Asterisk).
