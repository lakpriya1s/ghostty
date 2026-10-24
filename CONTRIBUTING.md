# Contributing to KinTerm

Thanks for helping. KinTerm is a fork of [Ghostty](https://github.com/ghostty-org/ghostty)
that adds agent faces to the tabs, so contributions fall into two kinds:

- **Agent tabs, faces, the Claude Code hook, the Setup Assistant, the website:** that's
  KinTerm, and this repo is the right place.
- **The terminal itself** (emulation, rendering, fonts, config options): that's Ghostty.
  Please report or fix it [upstream](https://github.com/ghostty-org/ghostty), and
  KinTerm picks it up with the next merge.

## Issues

- **Bugs:** open an issue with your macOS version, the KinTerm version (KinTerm › About
  KinTerm) and the steps to reproduce. A screenshot of the tab bar helps a lot.
- **Ideas:** open an issue describing what you're trying to do. New face sets and
  support for other agents are especially welcome.

## Pull requests

1. Fork the repo and branch from `main`.
2. Build and run your change (see [Build from source](README.md#build-from-source)).
   [scope/HANDOFF.md](scope/HANDOFF.md) explains how the agent tabs fit into the code.
3. Keep the change focused, and keep Ghostty's own files as they are where you can, so
   upstream merges stay easy.
4. Run the formatters before you push:
   - Swift: `swiftlint lint --strict --fix`
   - Zig: `zig fmt .`
   - Shell: `shellcheck` on any script you touched
5. Open the pull request and say what changed, why, and how you tested it. Screenshots
   or a short recording for anything visual, please.

Using AI tools to write code is fine. You're responsible for understanding and testing
what you submit.

## Code of conduct

Be kind and constructive. Harassment or personal attacks aren't welcome here, in
issues, pull requests or anywhere else in the project.
