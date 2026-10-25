# Changelog

All notable changes to Kali-iTerm2 are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Per-terminal theme selection: a session can set `KALI_ITERM2_THEME=light|dark`
  in its environment (e.g. Zed's `terminal.env`) to override the installed
  default for that terminal only; documented in the README with a Zed example.
- Four regression tests for the override path (override wins, fallback to
  installed default, `LS_COLORS` follows session theme, invalid value falls
  back safely to light).
- A regression test locking Kali Light's bold-bright directory blue to a
  readable contrast floor and pinning Kali Dark's bright blue against change.
- Optional `~/.hushlogin` tip in the README to hide macOS's non-Kali
  `Last login:` line (documented only; never automated by the installer).
- Regression tests: Kali Light pins "Use Bright Bold" off while Kali Dark
  keeps the iTerm2 default, and the light prompt must carry all three tones
  (cyan structure / blue identity / dark path) while the dark prompt stays
  byte-identical (suite: 37 checks).

### Changed

- The managed `.zshrc` block now writes
  `export KALI_ITERM2_THEME="${KALI_ITERM2_THEME:-<mode>}"` instead of an
  unconditional assignment, so explicit per-session requests are respected.
- **Kali Light profile disables iTerm2's "Use Bright Bold" explicitly.**
  Bold text renders with the normal palette entries, so directories
  (`di=01;34`) display the saturated azure ANSI blue `#006BD6` at bold
  weight — matching Kali — instead of any bright variant, immune to
  inherited user settings. Kali Dark keeps iTerm2's default behavior.
- **Kali Light prompt structure is now cyan/aqua (`#009BC9`)** for `┌──`,
  brackets and `└─`, while username/host stay strong blue (`#006BD6`) and
  the path stays dark bold — Kali's three-tone prompt instead of one
  uniform blue. Dark theme prompt colors are unchanged.

### Fixed

- **Kali Light directories rendered pale lavender in iTerm2.** iTerm2 renders
  bold text with the *bright* palette entry ("Use Bright Bold", on by default),
  so `di=01;34` displayed bright blue (ANSI 12, `#0080FF`, contrast 3.6:1 on
  the light background) instead of the saturated Kali blue. The Kali Light
  theme's bright blue is now `#0059B3` (contrast 6.5:1, WCAG AA), and the
  profile-level "Use Bright Bold" fix above makes directories render the
  azure ANSI 4 blue outright. ANSI blue and every other palette entry are
  unchanged, and the Kali Dark palette is untouched. Regression tests lock
  the contrast floor, the bold-bold setting, and the dark palette's bright
  blue.

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
