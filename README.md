# Kali-inspired iTerm2

A tiny, independently written appearance-only package for **iTerm2 on macOS**. It does not install Kali, alter OpenCode, or copy Kali's published `.zshrc` source. Unaffiliated with [Kali Linux](https://www.kali.org/) / Offensive Security.

## Included
- Kali-inspired two-line Zsh prompt (`┌──(user㉿host)-[path]` / `└─$`) with cyan/aqua structure and blue username/host on the light theme
- Two iTerm2 Dynamic Profiles: **Kali Light** and **Kali Dark**
- GNU `ls` colors: blue directories, red archives, green executables; BSD `ls` fallback
- Reversible installer

## Requirements

- macOS with **zsh** (preinstalled) and **python3** (used to edit `.zshrc` safely and generate profiles).
- Any recent Bash — including the stock macOS Bash 3.2 (`/bin/bash`). No sudo, no network access, no remote scripts: everything runs from this folder.
- iTerm2 (the installer warns if it is not present; the shell-side pieces still install).
- `gls` from `brew install coreutils` is optional but required for GNU-only color features (archive-extension colors); without it a BSD `ls -G` fallback is used.

## Install

From the extracted folder, run the interactive installer:

```sh
./install.sh
```

Choose **Kali Light** or **Kali Dark**, review the changes, and confirm. For automation, run `./install.sh light` or `./install.sh dark` (non-interactive; skips the menu and confirmation).

Then in **iTerm2 → Settings → Profiles**, choose **Kali Light** or **Kali Dark** and use **Other Actions → Set as Default**. Open a new terminal tab. Existing profiles are not overwritten.

Optional: macOS prints `Last login: …` at the start of every session, which real Kali doesn't have. Run `touch ~/.hushlogin` to silence it (purely cosmetic; the installer deliberately does not do this for you).

To switch light/dark later, rerun `./install.sh dark` or `./install.sh light` and select the matching iTerm2 profile.

### Per-terminal theme (e.g. Zed)

The installed theme is only the **default**. Any terminal can request the other palette for its own shell sessions by setting `KALI_ITERM2_THEME` (`light` or `dark`) in the child environment; nothing else changes and no other terminal is affected. Zed's integrated terminal, for example, uses its dark editor theme — add to Zed's `settings.json`:

```json
"terminal": { "env": { "KALI_ITERM2_THEME": "dark" } }
```

iTerm2 keeps using the profile you installed (it does not set that variable), and this package never writes to Zed or iTerm2 settings. Automatic appearance detection is deliberately not attempted: neither terminal reliably exposes its active light/dark theme to shells, so the choice is explicit.

## Uninstall

```sh
./uninstall.sh
```

Uninstall backs up `.zshrc` (to `~/.zshrc.kali-iterm2.uninstall.<timestamp>.bak`), removes only the clearly marked managed block, deletes the installed prompt/color files and the two dynamic profiles, and reports every action. It is a safe no-op if nothing was installed. Reselect your previous default profile in iTerm2. It doesn't uninstall existing tools or fonts.

## Tests

```sh
tests/run-tests.sh
```

Runs the full suite inside isolated temporary `HOME` directories — it never touches your real shell configuration. Covers clean installs, theme switching, reinstall idempotency, Oh My Zsh / Starship coexistence, uninstall reversibility, interrupted installs, spaces in `$HOME`, GNU/BSD `ls` behavior, prompt rendering, argument validation, and an interactive pty run of the menu.

## Limitations

- This is a visual approximation, not an official pixel-perfect reproduction of Kali's own terminal theme.
- If your shell framework or custom `precmd` hooks reset `PROMPT` after this script is sourced, they may supersede the theme. Disable the competing prompt framework or put this integration after it.
- For matching red file extensions, install GNU coreutils (`brew install coreutils`).
- The active iTerm2 tab and the default profile may need to be selected manually; automated switching of open tabs is deliberately avoided.

## Licensing and provenance

Implementation and theme palette are independently authored for this project and released under MIT. Visual inspiration only: Kali Linux's recognizable two-line Zsh presentation. No source code, artwork, or logos from Kali or other theme repositories are included. The name 'Kali' is used descriptively and implies no affiliation.
