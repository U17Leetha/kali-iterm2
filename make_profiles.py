#!/usr/bin/env python3
"""Create separate iTerm2 Dynamic Profiles from independent theme color files."""
import json, plistlib, sys
from pathlib import Path
root=Path(__file__).resolve().parent
out=Path(sys.argv[1])
profiles=[]
for mode, guid in [('light','6C79C44E-31AA-4BC9-B100-4DB251E23301'),('dark','6C79C44E-31AA-4BC9-B100-4DB251E23302')]:
    colors=plistlib.loads((root/'themes'/f'kali-{mode}.itermcolors').read_bytes())
    profiles.append({'Name': f'Kali {mode.capitalize()}', 'Guid': guid, 'Transparency': 0, **colors})
out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(json.dumps({'Profiles':profiles},indent=2)+'\n')
