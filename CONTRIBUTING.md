# Contributing

## Development

1. Branch from `main`
2. Prefer focused PRs
3. Local checks:

   ```bash
   make shellcheck
   make smoke-published        # uses GHCR; no local compile
   make build && make smoke    # only when changing the image build
   ```

PR CI runs ShellCheck, hadolint, actionlint, yamllint, markdownlint and smokes
`ghcr.io/pmastalerz/asterisk:latest` (no Asterisk compile). If the published
image isn't available yet (first-ever run on a fork), CI falls back to a local
amd64 build for the smoke test.

## Conventional Commits

**All PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/).**
The repo squash-merges, so the PR title becomes the commit on `main`, and
[release-please](https://github.com/googleapis/release-please) derives the next
packaging version + changelog from those messages.

Common types:

| Type       | Effect on packaging SemVer | Notes                                   |
| ---------- | -------------------------- | --------------------------------------- |
| `feat:`    | MINOR bump                 | User-visible additive change            |
| `fix:`     | PATCH bump                 | Bug fix                                 |
| `perf:`    | PATCH bump                 | Performance improvement                 |
| `docs:`    | PATCH bump                 | Docs-only (shows in changelog)          |
| `refactor:`| No bump                    | Hidden from changelog                   |
| `test:`    | No bump                    | Hidden from changelog                   |
| `chore:`   | No bump                    | Hidden (used for deps too)              |
| `build:`   | PATCH bump                 | Build system / image inputs             |
| `ci:`      | PATCH bump                 | CI-only                                 |
| `revert:`  | PATCH bump                 | Reverts a prior commit                  |

Add `!` after the type (or a `BREAKING CHANGE:` footer) for MAJOR bumps:

```text
feat!: drop full-varlib mount seed path

BREAKING CHANGE: users bind-mounting all of /var/lib/asterisk must now mount only db/keys/sounds.
```

The `PR Title` workflow blocks PRs with non-conventional titles.

## Versioning strategy

Two independent version numbers live in this repo:

| Version                       | Where                              | What it means                           |
| ----------------------------- | ---------------------------------- | --------------------------------------- |
| **Upstream Asterisk**         | `VERSION` + `ASTERISK_SHA256`      | Which tarball the image compiles        |
| **Packaging (this repo)**     | `.release-please-manifest.json` + git tag `vX.Y.Z` | Entrypoint, seed scripts, Dockerfile, docs, Unraid template |

They evolve independently, exactly like a Linux distro packaging a program.

### When the image gets rebuilt

After merge to `main`, the **Release** workflow publishes a new multi-arch image
when any of these paths change:

- `VERSION` / `ASTERISK_SHA256`
- `Dockerfile` / `.dockerignore`
- `build/**`
- `root/**` (entrypoint, defaults, healthcheck)

Anything else (docs, examples, most of `.github/`) only re-runs smoke against
the published image.

### Cutting a packaging release

You don't tag by hand. release-please opens a **Release PR** on every push to
`main` and keeps it up-to-date. When you merge that PR, release-please tags
`vX.Y.Z` and creates the GitHub Release. The `release.yml` workflow reacts to
the tag by building/pushing the image and appending pull instructions to the
release body.

### Same Asterisk version, packaging tweak

- Change `root/**`, `Dockerfile`, `build/**`
- Merge the PR (Conventional Commit title) → `:latest` and `:22.11.0` get
  rebuilt automatically
- release-please queues a new packaging bump in its Release PR; merge that when
  you want to cut `vX.Y.Z`

### New upstream Asterisk version

Two ways:

1. **Automatic** — the `Discover upstream Asterisk` workflow runs daily and
   opens a `feat: bump Asterisk to X.Y.Z` PR when a new release appears.
2. **Manual** — bump `VERSION` and `ASTERISK_SHA256` yourself; open a PR with
   a `feat:` (or `fix:` for a security patch) title.

Merging either triggers a rebuild + a new packaging bump.

## Scope

| In scope                              | Out of scope (unless discussed)     |
| ------------------------------------- | ----------------------------------- |
| Packaging, entrypoint, defaults, docs | Forking Asterisk feature sets       |
| Menuselect profile tweaks             | DAHDI / telephony hardware stacks   |
| Examples under `examples/`            | Shipping real credentials           |

## License

Contributions under [GPL-2.0](LICENSE). Be respectful ([CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)).
