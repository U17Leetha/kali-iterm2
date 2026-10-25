#!/bin/bash
# Kali-iTerm2 uninstaller — removes only project-managed configuration.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo 'This package supports macOS iTerm2 only.' >&2
  exit 1
fi
command -v python3 >/dev/null 2>&1 || {
  echo 'Python 3 is required (used to edit ~/.zshrc).' >&2
  exit 1
}

ZSHRC="$HOME/.zshrc"
CHANGED=0

if [[ -f "$ZSHRC" ]] && grep -qF '# >>> kali-iterm2 managed >>>' "$ZSHRC"; then
  BACKUP="$HOME/.zshrc.kali-iterm2.uninstall.$(date +%Y%m%d-%H%M%S).bak"
  n=1
  while [[ -e "$BACKUP" ]]; do BACKUP="${BACKUP%.bak}-$n.bak"; n=$((n+1)); done
  cp "$ZSHRC" "$BACKUP"
  python3 - "$ZSHRC" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
s = p.read_text()
start = '# >>> kali-iterm2 managed >>>'
end   = '# <<< kali-iterm2 managed <<<'
s = re.sub(r'\n?' + re.escape(start) + r'.*?' + re.escape(end) + r'\n?', '\n', s, flags=re.S)
p.write_text(s)
PY
  echo "Removed the kali-iterm2 block from ~/.zshrc (backup kept: $BACKUP)."
  CHANGED=1
else
  echo 'No kali-iterm2 block found in ~/.zshrc; leaving it untouched.'
fi

PROFILE="$HOME/Library/Application Support/iTerm2/DynamicProfiles/kali-iterm2.json"
if [[ -f "$PROFILE" ]]; then
  rm -f "$PROFILE"
  echo 'Removed the Kali Light / Kali Dark iTerm2 dynamic profiles.'
  CHANGED=1
fi

if [[ -d "$HOME/.config/kali-iterm2" ]]; then
  rm -rf "$HOME/.config/kali-iterm2"
  echo 'Removed installed prompt/color files from ~/.config/kali-iterm2.'
  CHANGED=1
fi

echo
if [[ "$CHANGED" -eq 1 ]]; then
  echo 'Backups are kept; delete them yourself once you are happy with the result.'
  echo 'Choose your previous default profile under iTerm2 → Settings → Profiles,'
  echo 'then open a new terminal tab for restored shell behavior.'
else
  echo 'Nothing to remove — Kali-iTerm2 does not appear to be installed.'
fi
