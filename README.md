# Kali-inspired iTerm2

A tiny, independently written appearance-only package for **iTerm2 on macOS**. It does not install Kali, alter OpenCode, or copy Kali's published `.zshrc` source. Unaffiliated with Kali Linux / Offensive Security.

## Included
- Kali-inspired two-line Zsh prompt (`┌──(user㉿host)-[path]` / `└─$`)
- Two iTerm2 Dynamic Profiles: **Kali Light** and **Kali Dark**
- GNU `ls` colors: blue directories, red archives, green executables; BSD `ls` fallback
- Reversible installer

## Install

From the extracted folder, run the interactive installer:

```sh
./install.sh
```

Choose **Kali Light** or **Kali Dark**, review the changes, and confirm. For automation, you can still run `./install.sh light` or `./install.sh dark` (these also ask for confirmation when attached to a terminal).

Then in **iTerm2 → Settings → Profiles**, choose **Kali Light** or **Kali Dark** and use **Other Actions → Set as Default**. Open a new terminal tab. Existing profiles are not overwritten. `gls` from `brew install coreutils` is optional but required for archive-extension colors; otherwise macOS `/bin/ls` is used.

To switch light/dark later, rerun `./install.sh dark` or `./install.sh light` and select the matching iTerm2 profile.

## Uninstall

```sh
./uninstall.sh
```

Reselect your previous default profile in iTerm2. The installer backs up `.zshrc` before modifications and only adds/removes a clearly marked block. It doesn't uninstall existing tools or fonts.

## Limitations

- This is a visual approximation, not an official pixel-perfect reproduction of Kali's own terminal theme.
- If your shell framework or custom `precmd` hooks reset `PROMPT` after this script is sourced, they may supersede the theme. Disable the competing prompt framework or put this integration after it.
- For matching red file extensions, install GNU coreutils (`brew install coreutils`).
- The active iTerm2 tab and the default profile may need to be selected manually; automated switching of open tabs is deliberately avoided.

## Licensing and provenance

Implementation and theme palette are independently authored for this project and released under MIT. Visual inspiration only: Kali Linux's recognizable two-line Zsh presentation. No source code, artwork, or logos from Kali or other theme repositories are included. The name 'Kali' is used descriptively and implies no affiliation.
