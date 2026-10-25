#!/bin/bash
set -euo pipefail
ZSHRC="$HOME/.zshrc"
python3 - "$ZSHRC" <<'PY'
from pathlib import Path
import sys,re
p=Path(sys.argv[1]);
if not p.exists(): quit()
s=p.read_text()
start='# >>> kali-iterm2 managed >>>'; end='# <<< kali-iterm2 managed <<<'
s=re.sub(r'\n?'+re.escape(start)+r'.*?'+re.escape(end)+r'\n?', '\n', s, flags=re.S)
p.write_text(s)
PY
rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/kali-iterm2.json"
rm -rf "$HOME/.config/kali-iterm2"
echo 'Removed Kali-iTerm2 shell integration and custom profiles.'
echo 'Choose your previous default iTerm2 profile under Settings → Profiles.'
echo 'Open a new terminal tab for restored shell behavior.'
