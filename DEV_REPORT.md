# Development Report — v0.2 Audit to Publication-Ready v0.3

Date: 2026-10-25 · Platform tested: macOS (Apple Silicon), stock `/bin/bash` 3.2.57, zsh 5.9, python3 3.x.

## 1. Audit of v0.2 against the handoff requirements

| Requirement | v0.2 status | Evidence |
|---|---|---|
| Interactive installer (menu + confirmation) | Broken — crashed right after theme selection on stock macOS bash | `${MODE^}` (bash 4+ only) → `bad substitution` under `/bin/bash` 3.2, reproduced |
| Non-interactive mode | Present (`install.sh light\|dark`) | OK |
| Kali-style two-line prompt | Present, original code, honors interactive-shell guard | Reviewed line by line; renders correctly in zsh 5.9 |
| GNU + BSD `ls` colors | Present; GNU-only features degrade silently | Silent alias shadowing when user had own `ls` alias |
| Reversible uninstall, backups preserved | **Violated** — `uninstall.sh` rewrote `.zshrc` with no backup at all | Code review |
| Themes valid, in-range, distinct light/dark | Valid | Both `.itermcolors` parse as plists; all components within range; 16 ANSI colors + fg/bg/cursor/selection present; light `#F8F9FA`/`#1D2430`, dark `#171C26`/`#E6EDF5` |
| Profiles don't overwrite existing ones | OK — dynamic-profiles JSON with fixed GUIDs, idempotent | Verified regeneration stability |
| No sudo / no remote scripts / appearance only | OK | Nothing in scope violated this |
| MIT license + provenance | License present; provenance notes missing | Added `NOTICE.md` |
| Tests | None shipped | Gap — added `tests/run-tests.sh` |
| Changelog | None | Gap — added `CHANGELOG.md` |

Additional issues found: timestamp-only backup names could collide (two installs in one second overwrite each other); no preflight for missing repo files, missing `zsh`/`python3`, or absent iTerm2; no warning when the user's `.zshrc` already defines an `ls` alias or loads Starship/OMZ.

## 2. Changes made (all in this repo)

- `install.sh` — rewritten: bash-3.2-safe theme labeling, preflight checks (repo files, `python3`, `zsh` required; iTerm2 warn-only), unique backup names with collision loop, conflict warnings on the confirmation screen. Same managed-block format and markers as v0.2, so v0.2 installs upgrade cleanly.
- `uninstall.sh` — rewritten: always backs up `.zshrc` before removing the managed block (collision-safe name), reports each removed/kept item, safe no-op when nothing is installed.
- `prompt/kali.zsh`, `colors/ls-colors.zsh`, `themes/*`, `make_profiles.py` — unchanged after audit confirmed they met requirements (original, in-range, idempotent).
- `README.md` — requirements, non-interactive usage, uninstall behavior, test instructions, disclaimer with links.
- `NOTICE.md`, `CHANGELOG.md`, this report — added.

## 3. Testing

`tests/run-tests.sh` — 30 checks, all run inside isolated temporary `HOME` directories; the developer's real `~/.zshrc` and DynamicProfiles were never used as test fixtures. **Result: 30 passed, 0 failed, 0 skipped** on macOS/arm64 with stock bash 3.2.

Handoff scenario coverage: clean install (light & dark) · reinstall without duplicates · dark→light and light→dark switching · existing Oh My Zsh preserved · existing Starship preserved (managed block appended after it) · uninstall removes only managed config, keeps user content including post-install edits, and is a safe repeat no-op · interrupted/failed install leaves `.zshrc` byte-identical · `HOME` containing spaces/parentheses · missing GNU coreutils falls back to BSD `ls -G` (verified with restricted `PATH`) · repeated install/uninstall cycles · prompt renders in oddly named directories and never touches non-interactive shells · invalid/redundant arguments rejected (exit 2) · interactive menu driven end-to-end through a real pty (`expect`).

## 4. Verified vs. not verified — stated honestly

Verified by execution: everything in section 3, plist/JSON validity, GUID stability, bash/zsh syntax checks on stock system shells.

Not verified (no claim made either way):
- **Visual fidelity inside iTerm2**: palettes and prompt were validated structurally and by rendering the prompt string in zsh; how they *look* on screen in a real iTerm2 window requires human eyes.
- **iTerm2 loading the dynamic profiles**: the JSON is schema-consistent with what iTerm2's Dynamic Profiles expect (same shape as pre-existing community profiles) but was not observed being loaded by a running iTerm2 instance during automated tests.
- **Other macOS versions / Intel Macs / bash 4+ shells**: only tested on one Apple Silicon host with the system bash; the scripts avoid version-specific constructs, but that is inference, not execution evidence.
- **Long third-party prompt frameworks beyond OMZ/Starship** (e.g. powerlevel10k): untested coexistence.

## 5. Remaining risks / follow-ups

- iTerm2 may drop unknown keys from dynamic-profile JSON on rewrite; harmless here but worth one manual smoke test before publishing the release tag.
- Consider a GitHub Actions matrix (macos-latest, bash + zsh) once the repo is published.

## 6. Addendum — v0.3 acceptance & Zed terminal compatibility (v0.3.1 work)

**Root cause (Zed shows light-mode colors on its dark background):** the prompt uses fixed 24-bit hex colors chosen per palette (`%F{#006BD6}` etc.), not terminal-palette ANSI indexes, and the managed `.zshrc` block exported `KALI_ITERM2_THEME=<mode>` unconditionally — so every terminal running the user's zsh got the iTerm2-installed palette regardless of its own appearance. (Zed renders its terminal background from the editor theme; `ls` colors use ANSI indexes and adapt, which is why only the prompt looked wrong.)

**Investigation evidence:** Zed source `crates/terminal/src/terminal.rs::insert_zed_terminal_env` unconditionally inserts `TERM_PROGRAM=zed`, `ZED_TERM=true`, `COLORTERM=truecolor`, `TERM=xterm-256color` (overwrite-on-inherit), and exposes **no** light/dark appearance variable; official docs confirm `terminal.env` injects arbitrary per-session env. iTerm2 sets `TERM_PROGRAM=Apple_Terminal`. `COLORFGBG` is not set by Zed and unreliable in iTerm2 — automatic detection rejected in favor of an explicit setting (README "Per-terminal theme").

**Change:** one line in the managed block (`export KALI_ITERM2_THEME="${KALI_ITERM2_THEME:-<mode>}"`) so a terminal-provided value wins per session; Zed config lives outside this package. No prompt/ls-colors/install/uninstall behavior changes. Suite extended to **34 checks (all passing)**: override precedence, default fallback, `LS_COLORS` follows session theme, invalid value falls back to light.

**Remaining manual verification (GUI — cannot be automated here):**
1. Install light; in iTerm2 set the Kali Light profile default; confirm prompt/ls colors visually.
2. Same for dark.
3. Confirm Kali Light/Dark appear in iTerm2 → Settings → Profiles after install (Dynamic Profile loading).
4. Apply the README Zed snippet; open a new Zed terminal: dark prompt colors while iTerm2 stays light; remove snippet restores inherited default.
5. Confirm OpenCode's own theme is unaffected in both terminals.
