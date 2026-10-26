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

Items 1 (with the caveat below), 3 and 4 were confirmed by the user in real terminals; item 2/5 remain user-side.

## 7. Addendum — Kali Light directory color fix (release validation round)

**Symptom:** directories listed pale lavender in iTerm2 Kali Light; correct saturated blue in Zed dark.

**Root cause:** `LS_COLORS` colors directories with bold + ANSI blue (`di=01;34`). iTerm2's "Use Bright Bold" (on by default, not overridden by our profiles) renders bold text with the *bright* palette entry, so directories actually displayed Kali Light's bright blue (ANSI 12 = `#0080FF`, contrast only 3.6:1 on `#F8F9FA`) — a thin, washed-out lavender-adjacent blue at small sizes. Zed was never affected because it renders ANSI indexes through its own editor-theme palette. Verified against the live environment: managed `.zshrc` block intact and last among `LS_COLORS` setters; fresh shells receive our ANSI values (the user's older manual truecolor blocks in `.zshrc` are overridden); dynamic profile JSON matched the theme plist exactly — ruling out settings overrides, stale profiles, and shell-config conflicts.

**Correction (smallest change):** Kali Light `Ansi 12 Color` `#0080FF` → `#0059B3` in `themes/kali-light.itermcolors` only — contrast 6.5:1 (WCAG AA). No code changes: prompt, `ls-colors.zsh`, installer and profile generator untouched; Kali Dark palette explicitly unchanged (protected by test). Live dynamic profile JSON regenerated via `make_profiles.py`.

**Contrast audit on light background (unchanged entries):** archives 4.45:1, executables 4.12:1, symlinks 4.18:1, default text 14.8:1 — all ≥ 3:1 non-text floor; only the bold-bright directory blue was below par.

**Testing:** suite extended to **35 checks (all passing)**; new regression test asserts Kali Light bright-blue contrast ≥ 4.5:1 against its background and pins Kali Dark's bright blue at `#8BC8FF`. Restoration scenarios re-verified in isolated HOMEs only (single block on reinstall, OMZ/Starship preserved, post-install edits survive uninstall, backup kept, no-op repeat uninstall, 3× cycles).

**Visual validation status:** escape-sequence and palette-level verification complete (`gls --color=always` emits `di=01;34`, profile maps ANSI 4→`#006BD6`, ANSI 12→`#0059B3`). **Rendered-pixel confirmation in iTerm2 of the corrected color has NOT been performed** — this environment cannot view images, and scripted screenshotting of the user's iTerm2 was blocked (Apple events timing out). A rendered before/after swatch exists at `/tmp/kali-light-swatch.png` for the user; final sign-off requires one `gls --color=always -la` glance in a new Kali Light tab.

**Provenance:** palette value change only; no third-party code introduced; LICENSE and NOTICE unchanged.

## 8. Addendum — visual fidelity pass (Kali Light)

**Symptom after §7:** directories still read pale lavender/periwinkle in the user's rendered iTerm2, and the prompt reads uniformly blue where real Kali shows cyan structure + blue identity + dark path.

**Root causes:**
1. Directory hue depended on *which* blue survived iTerm2's bold handling. Any inherited "Use Bright Bold" state (user preset, older profile copy, or a session that loaded before §7 regenerated the JSON) routes `di=01;34` through ANSI 12 — a different blue than Kali's azure ANSI 4. The palette-only fix was correct but fragile: fidelity hinged on one setting we did not control per-profile.
2. The prompt used a single accent (`#006BD6`) for structure *and* identity; real Kali separates them (aqua frame, blue user/host, dark bold path).

**Corrections (light theme only; smallest changes):**
- `themes/kali-light.itermcolors`: added profile-level `Use Bright Bold = false`. Bold now renders with normal palette entries → directories are azure `#006BD6` at bold weight regardless of inherited settings; archives/executables shift to their slightly *darker* normal reds/greens (contrast improves); dark profile untouched (keeps iTerm2 default, Zed unaffected).
- `prompt/kali.zsh`: new light-theme frame color `#009BC9` (cyan/aqua) for `┌──`, brackets, `└─`; identity stays `#006BD6`, path stays `#1D2430`. Dark branch sets frame = accent so dark output is byte-identical to before.
- README: optional `~/.hushlogin` tip (documented only) for the non-Kali `Last login:` line.

**Live state:** dynamic profile JSON regenerated — Kali Light now carries `Use Bright Bold: false`; requires a **new tab** (and, once, Settings → Profiles → Set Default if not yet done) to take visual effect.

**Testing:** suite extended to **37 checks, all passing**: bold-bold pinning per theme, three-tone light prompt assertion, dark prompt byte-unchanged assertion; previous contrast-floor and Zed palette pins still pass. Restoration/install safety untouched (isolated HOMEs only).

**Gap:** rendered-pixel confirmation remains user-side (no image capability in this environment). Validation is one new Kali Light tab: `gls --color=always -la` in `/tmp/kali-iterm2-visual-test` — expect azure bold dirs, red archives, green executables, teal symlinks, aqua prompt frame.

## 9. Addendum — optional Zed integration (installer convenience step)

**Feature.** After the iTerm2 theme is installed, the interactive installer
detects Zed (`~/Applications/Zed.app`, `/Applications/Zed.app`, or `zed` on
PATH; `KALI_ITERM2_ZED_INSTALLED=yes|no` is an internal test seam) and offers
an independent Light/Dark/Skip choice for its integrated terminal. Only
`terminal.env.KALI_ITERM2_THEME` is ever written. Non-interactive installs do
nothing unless `--zed light|dark` is passed. The Zed editor theme, OpenCode
and every other setting are out of scope and untouched.

**JSONC strategy.** New stdlib-only `zed_settings.py` (~200 lines, no new
dependencies) performs *surgical* text edits: a length-preserving mask blanks
comments and value strings (keys stay visible), the key/`terminal`/`env` path
is located structurally, and exactly one insertion/replacement is spliced in.
Every proposed result must re-parse as JSONC or nothing is written (exit 3 →
installer prints the manual snippet instead of risking data loss). Existing
overrides with a different value are never replaced silently: interactive
asks for confirmation; non-interactive leaves them and shows the snippet.
Files that do not parse at all are refused untouched.

**Uninstall.** Removes only the `KALI_ITERM2_THEME` key when its value is
`light|dark` (our own footprint), after a timestamped collision-safe backup,
and only if the resulting file still parses — unrelated settings, comments
and post-install user edits survive byte-identical. No key → no write, no
backup churn. Empty `env`/`terminal` containers are deliberately left in
place (valid JSON; removing them could delete user content).

**Testing.** Suite extended from 37 to **48 checks, all passing**, covering
every handoff-listed scenario: not installed, interactive skip (pty), light
and dark selection, existing terminal config + JSONC comments, existing
override protection, malformed settings untouched, repeated installation
idempotency, uninstall preservation (user edits + comments + backup) and
uninstall no-op. All Zed tests run in isolated temp HOMEs with fake detection;
the developer's real `~/Library/Application Support/Zed/settings.json` was
never modified by the test suite.

## 10. Addendum — production code review round (pre-release)

A multi-role production review (correctness, security, architecture,
efficiency, density, dependencies, testing, hygiene) was performed on the
whole repository at `c861f64`. Verdict: request changes; no Critical findings;
one High. All actionable findings were fixed and are covered by regression
tests (suite extended 48 → **54 checks, all passing**):

| Finding | Severity | Fix |
| --- | --- | --- |
| Pre-existing keyless `settings.json` modified without backup (docs promised otherwise) | High | Installer backs the file up whenever it exists and will be modified; unused backups are removed (no churn) |
| Unhandled `IndexError` on unterminated `/*` comment in Zed settings via uninstall path | Medium | Comment masking is bounds-safe; operation fails soft, file untouched |
| Test suite depended on `rg` (not shipped with macOS) and fixed `/tmp` log names | Medium | Portable `grep -E`; all logs inside the per-run temp dir |
| Key lookup was global-first-match — a stray `KALI_ITERM2_THEME` outside `terminal.env` could be misread as ours or duplicated | Low | Lookup scoped to the `terminal.env` object span; stray keys are refused (install) / left alone (uninstall) |
| Uninstall reported success/kept backups even when it wrote nothing (foreign value) | Low | Backup kept and change reported only on actual removal |
| Non-atomic writes, bare `open()` calls, swallowed helper output on failure | Low | Atomic write (temp + rename), explicit read-error handling, failures print the helper's message |
| Unguarded `read` under `set -e` in interactive Zed prompts | Low | Reads default safely on EOF |
| Managed-block markers duplicated across scripts with drift risk | Low | Comments name the contract; a suite tripwire asserts install/uninstall markers stay byte-identical |

Not changed (deliberate): `DEV_REPORT.md` itself stays at repo root as a
handoff artifact for this project's governance; `zed_settings.py` remains a
top-level script (single purpose, no package justified); review noted the
codebase is appropriately small — no abstraction changes recommended.
