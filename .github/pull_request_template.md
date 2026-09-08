<!--
  PR title MUST be a Conventional Commit (see CONTRIBUTING.md).
  Examples:
    feat: add ASTERISK_TERMINAL_OPTS
    fix(entrypoint): honor PUID=0
    feat!: rename /etc/asterisk mount layout   (breaking → MAJOR)
    docs: clarify Unraid host-network note
    chore(deps): bump docker/build-push-action to v7.1.0

  The PR Title workflow will block this PR if the title is not conventional.
-->

## Summary

<!-- What changed and why -->

## Checklist

- [ ] PR title follows Conventional Commits (release-please reads it)
- [ ] Docs / README updated if behavior or tags changed
- [ ] `VERSION` and `ASTERISK_SHA256` **bumped together** if upstream Asterisk changes
- [ ] Local smoke test run when feasible (`./scripts/smoke-test.sh <image>`)
- [ ] For breaking changes: title carries `!` or body has `BREAKING CHANGE:` footer
