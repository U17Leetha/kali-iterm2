#!/bin/bash
# Kali-iTerm2 installer — appearance-only iTerm2 + Zsh theming for macOS.
# Independent work; not affiliated with Kali Linux or Offensive Security.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-}"

if [[ $# -gt 1 || ( -n "$MODE" && "$MODE" != light && "$MODE" != dark ) ]]; then
  echo 'Usage: ./install.sh [light|dark]' >&2
  exit 2
fi
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'This package supports macOS iTerm2 only.' >&2
  exit 1
fi

# --- Preflight checks (run before any file is modified) --------------------
command -v python3 >/dev/null 2>&1 || {
  echo 'Python 3 is required (used to generate the iTerm2 profiles).' >&2
  exit 1
}
command -v zsh >/dev/null 2>&1 || {
  echo 'Zsh is required but was not found on PATH.' >&2
  exit 1
}
if [[ ! -d /Applications/iTerm.app ]]; then
  echo 'Warning: iTerm2 was not found in /Applications; profile files will' >&2
  echo '         still be installed but will have no effect until iTerm2 is present.' >&2
fi
for f in prompt/kali.zsh colors/ls-colors.zsh \
         themes/kali-light.itermcolors themes/kali-dark.itermcolors \
         make_profiles.py; do
  [[ -f "$ROOT/$f" ]] || {
    echo "Missing required file: $f (incomplete download?)" >&2
    exit 1
  }
done

# --- Theme selection --------------------------------------------------------
if [[ -z "$MODE" ]]; then
  if [[ ! -t 0 ]]; then
    echo 'No interactive terminal detected. Use ./install.sh light or ./install.sh dark.' >&2
    exit 2
  fi
  printf '\n  Kali-iTerm2 Setup\n\n  Select a theme:\n\n    1) Kali Light\n    2) Kali Dark\n    3) Cancel\n\n'
  while :; do
    read -r -p '  Choice [1-3]: ' choice || { echo; exit 1; }
    case "$choice" in
      1|light|Light) MODE=light; break ;;
      2|dark|Dark)   MODE=dark;  break ;;
      3|q|Q|quit|Quit) echo 'Canceled; no changes made.'; exit 0 ;;
      *) echo '  Please enter 1, 2, or 3.' ;;
    esac
  done
fi

# bash 3.2 (stock macOS) has no ${var^}; map explicitly instead.
case "$MODE" in light) LABEL=Light ;; *) LABEL=Dark ;; esac

ZSHRC="$HOME/.zshrc"
INSTALL_DIR="$HOME/.config/kali-iterm2"
DYNAMIC_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"

# --- Confirmation -----------------------------------------------------------
if [[ -t 0 ]]; then
  printf '\n  Theme: Kali %s\n\n  This installer will:\n' "$LABEL"
  echo '    • Add two iTerm2 dynamic profiles (your default profile is not changed)'
  echo "    • Install prompt and ls-color files into $INSTALL_DIR"
  echo '    • Back up ~/.zshrc, then append one clearly marked block'
  echo '    • Leave all other settings, plugins, and profiles untouched'
  if [[ -f "$ZSHRC" ]] && grep -Eq '(^|[;&|[:space:]])alias[[:space:]]+ls=' "$ZSHRC"; then
    echo
    echo '  Note: your ~/.zshrc defines its own "ls" alias. Our block is appended'
    echo '        last, so our "ls" alias will take precedence while installed.'
  fi
  if [[ -f "$ZSHRC" ]] && grep -Eq 'starship init|oh-my-zsh(\.sh)?["'"'"']?[[:space:]]*$|source \$ZSH/oh-my-zsh' "$ZSHRC"; then
    echo
    echo '  Note: an existing prompt framework (Starship / Oh My Zsh) was detected.'
    echo '        Our block is appended after it and will take precedence. Remove the'
    echo '        block (or run ./uninstall.sh) to hand the prompt back to it.'
  fi
  printf '\n'
  read -r -p '  Install? [y/N]: ' confirm || { echo; exit 1; }
  case "$confirm" in y|Y|yes|YES|Yes) ;; *) echo 'Canceled; no changes made.'; exit 0 ;; esac
fi

# --- Install ----------------------------------------------------------------
mkdir -p "$INSTALL_DIR/prompt" "$INSTALL_DIR/colors" "$DYNAMIC_DIR"
cp "$ROOT/prompt/kali.zsh"        "$INSTALL_DIR/prompt/"
cp "$ROOT/colors/ls-colors.zsh"   "$INSTALL_DIR/colors/"
cp "$ROOT/themes/kali-light.itermcolors" "$INSTALL_DIR/"
cp "$ROOT/themes/kali-dark.itermcolors"  "$INSTALL_DIR/"
python3 "$ROOT/make_profiles.py" "$DYNAMIC_DIR/kali-iterm2.json"

[[ -f "$ZSHRC" ]] || : > "$ZSHRC"
BACKUP="$HOME/.zshrc.kali-iterm2.$(date +%Y%m%d-%H%M%S).bak"
n=1
while [[ -e "$BACKUP" ]]; do BACKUP="${BACKUP%.bak}-$n.bak"; n=$((n+1)); done
cp "$ZSHRC" "$BACKUP"

python3 - "$ZSHRC" "$MODE" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1]); mode = sys.argv[2]
s = p.read_text()
start = '# >>> kali-iterm2 managed >>>'
end   = '# <<< kali-iterm2 managed <<<'
s = re.sub(r'\n?' + re.escape(start) + r'.*?' + re.escape(end) + r'\n?', '\n', s, flags=re.S)
block = (f'\n{start}\n'
         f'export KALI_ITERM2_THEME={mode}\n'
         f'source "$HOME/.config/kali-iterm2/colors/ls-colors.zsh"\n'
         f'source "$HOME/.config/kali-iterm2/prompt/kali.zsh"\n'
         f'{end}\n')
p.write_text(s.rstrip('\n') + '\n' + block)
PY

printf '\n  ✓ Installed Kali %s appearance.\n' "$LABEL"
echo "  ✓ Your ~/.zshrc was backed up to: $BACKUP"
echo
echo '  Next steps:'
echo '    1. iTerm2 → Settings → Profiles → Kali Light or Kali Dark'
echo '       → Other Actions → Set as Default Profile.'
echo '    2. Open a new tab; the Kali-style prompt and file colors apply there.'
echo "  To switch themes: rerun ./install.sh. To remove everything: ./uninstall.sh."
