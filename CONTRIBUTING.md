# Contributing

## Development

1. Branch from `main`
2. Prefer focused PRs
3. Local checks:

   ```bash
   make shellcheck
   make smoke-published   # uses GHCR; no local compile
   make build && make smoke   # only when changing the image build
   ```

PR CI runs ShellCheck and smokes `ghcr.io/pmastalerz/asterisk:latest` (no Asterisk compile).

## When the image is rebuilt

After merge to `main`, **Release** publishes a new multi-arch image when any of these change:

- `VERSION` / `ASTERISK_SHA256`
- `Dockerfile` / `.dockerignore`
- `build/**`
- `root/**` (entrypoint, defaults, healthcheck)

Anything else (docs, examples, most of `.github/`) only re-runs smoke against the published image.

Manual publish: **Actions → Release → Run workflow**.

Git tags `v*` always rebuild and create a GitHub Release.

### New Asterisk upstream version

1. Set `VERSION`
2. Set `ASTERISK_SHA256` from  
   `https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-VERSION.sha256`
3. Open PR → merge → Release compiles and pushes `latest` + the version tag

### Same Asterisk version, packaging / Dockerfile tweak

Change `root/**`, `Dockerfile`, or `build/**`, merge — Release rebuilds and updates `latest` (and the existing version tag such as `22.11.0`).

## Scope

| In scope | Out of scope (unless discussed) |
| --- | --- |
| Packaging, entrypoint, defaults, docs | Forking Asterisk feature sets |
| Menuselect profile tweaks | DAHDI / telephony hardware stacks |
| Examples under `examples/` | Shipping real credentials |

## License

Contributions under [GPL-2.0](LICENSE). Be respectful ([CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)).
