#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-}"
if [[ $# -gt 1 || ( -n "$MODE" && "$MODE" != light && "$MODE" != dark ) ]]; then
  echo 'Usage: ./install.sh [light|dark]' >&2; exit 2
fi
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'This package supports macOS iTerm2 only.' >&2; exit 1
fi
command -v python3 >/dev/null || { echo 'Python 3 required (for iTerm2 profiles)' >&2; exit 1; }
if [[ -z "$MODE" ]]; then
  if [[ ! -t 0 ]]; then
    echo 'No interactive terminal detected. Use ./install.sh light or ./install.sh dark.' >&2
    exit 2
  fi
  printf '\n  Kali-inspired iTerm2 Setup\n  -------------------------\n'
  printf '  Select a theme:\n\n    1) Kali Light\n    2) Kali Dark\n    3) Cancel\n\n'
  while :; do
    read -r -p '  Choice [1-3]: ' choice || exit 1
    case "$choice" in
      1|light|Light) MODE=light; break ;;
      2|dark|Dark) MODE=dark; break ;;
      3|q|Q|quit|Quit) echo 'Canceled; no changes made.'; exit 0 ;;
      *) echo '  Please enter 1, 2, or 3.' ;;
    esac
  done
fi
ZSHRC="$HOME/.zshrc"
INSTALL_DIR="$HOME/.config/kali-iterm2"
DYNAMIC_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
if [[ -t 0 ]]; then
  printf '\n  Theme: Kali %s\n' "${MODE^}"
  echo '  Changes:'
  echo '    • Add two new iTerm2 profiles (does not change your default)'
  echo '    • Install our own Zsh prompt and ls color files'
  echo '    • Back up ~/.zshrc and add a marked block'
  echo '    • Keep your existing plugins and other terminal profiles'
  echo '  Note: an existing prompt tool (e.g. Starship) may conflict.'
  printf '\n'
  read -r -p '  Install? [y/N]: ' confirm || exit 1
  case "$confirm" in y|Y|yes|YES|Yes) ;; *) echo 'Canceled; no changes made.'; exit 0 ;; esac
fi
mkdir -p "$INSTALL_DIR/prompt" "$INSTALL_DIR/colors" "$DYNAMIC_DIR"
cp "$ROOT/prompt/kali.zsh" "$INSTALL_DIR/prompt/"
cp "$ROOT/colors/ls-colors.zsh" "$INSTALL_DIR/colors/"
cp "$ROOT/themes/kali-light.itermcolors" "$INSTALL_DIR/"
cp "$ROOT/themes/kali-dark.itermcolors" "$INSTALL_DIR/"
python3 "$ROOT/make_profiles.py" "$DYNAMIC_DIR/kali-iterm2.json"
[[ -f "$ZSHRC" ]] || touch "$ZSHRC"
BACKUP="$HOME/.zshrc.kali-iterm2.$(date +%Y%m%d-%H%M%S).bak"
cp "$ZSHRC" "$BACKUP"
python3 - "$ZSHRC" "$MODE" <<'PY'
from pathlib import Path
import sys,re
p=Path(sys.argv[1]); mode=sys.argv[2]
s=p.read_text()
start='# >>> kali-iterm2 managed >>>'
end='# <<< kali-iterm2 managed <<<'
s=re.sub(r'\n?'+re.escape(start)+r'.*?'+re.escape(end)+r'\n?', '\n', s, flags=re.S)
block=f'''\n{start}\nexport KALI_ITERM2_THEME={mode}\nsource "$HOME/.config/kali-iterm2/colors/ls-colors.zsh"\nsource "$HOME/.config/kali-iterm2/prompt/kali.zsh"\n{end}\n'''
p.write_text(s.rstrip('\n')+'\n'+block)
PY
printf '\n✓ Installed Kali %s appearance.\n' "${MODE^}"
echo "✓ Zsh backup: $BACKUP"
echo 'Next: iTerm2 → Settings → Profiles → Kali Light / Kali Dark → Other Actions → Set as Default.'
echo 'Open a new tab. To switch themes, run ./install.sh again. To remove, run ./uninstall.sh.'
