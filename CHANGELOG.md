# Changelog

All notable changes to Kali-iTerm2 are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.0] - 2026-10-25

Publication-readiness release. Behavior of the v0.2 installer is preserved;
this release fixes defects that blocked safe public use and adds verification.

### Fixed

- **Crash on stock macOS Bash**: `install.sh` used a Bash 4-only parameter
  expansion (`${MODE^}`) immediately after theme selection, aborting every
  interactive install with `bad substitution` on `/bin/bash` 3.2 (the version
  macOS ships). Replaced with a portable `case` mapping.
- **Uninstall left no backup**: `uninstall.sh` rewrote `~/.zshrc` in place with
  no backup. It now always writes a timestamped, collision-safe backup
  (`~/.zshrc.kali-iterm2.uninstall.<timestamp>.bak`) before touching the file,
  and reports every item it removes or keeps.
- **Backup name collisions**: installer backups derived only from a timestamp;
  repeated runs within the same second could overwrite each other. A numeric
  suffix collision loop guarantees unique names.

### Added

- **Preflight checks**: `install.sh` now verifies repository files are present,
  requires `zsh` and `python3`, and warns (without failing) when iTerm2 is not
  installed. A failed preflight exits before anything is written.
- **Conflict warnings**: the confirmation screen now warns when your existing
  `.zshrc` defines its own `ls` alias or loads Starship / Oh My Zsh, so prompt
  and color precedence choices are informed rather than silent.
- **Test suite** (`tests/run-tests.sh`): 30 automated checks covering clean
  installs, theme switching, reinstall idempotency, uninstall reversibility,
  interrupted installs, `HOME` paths with spaces, GNU/BSD `ls` fallback, prompt
  rendering (including the interactive-shell guard), argument validation, and
  an interactive pty run of the menu. Every scenario runs inside an isolated
  temporary `HOME`; your real configuration is never touched.
- **Documentation**: this changelog, `NOTICE.md` provenance notes, a
  requirements section in the README, and a development report.

## [0.2.0]

- Interactive installer with theme menu and confirmation screen; non-interactive
  `install.sh light|dark` mode.
- Kali-style two-line zsh prompt (light/dark palettes) and colored `ls` setup
  with GNU coreutils/`gls` support.
- Two iTerm2 dynamic profiles generated from validated `.itermcolors` themes.
- Managed `.zshrc` block with marked begin/end for safe re-installation and
  removal; MIT license.

[0.3.0]: #
