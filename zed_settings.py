#!/usr/bin/env python3
"""Surgical editor for Zed's settings.json (JSONC), used by install/uninstall.

Writes exactly one key — terminal.env.KALI_ITERM2_THEME — and never rewrites
the file wholesale: comments, formatting, and every unrelated setting stay
byte-identical. If a safe surgical edit cannot be proven (malformed JSON,
unexpected structure), nothing is written and exit code 3 tells the caller to
fall back to showing the manual snippet.

Exit codes: apply  0 = applied/created/no-op, 3 = manual snippet needed,
                   4 = existing override differs (needs confirmation)
            remove 0 = removed or key absent, 3 = manual review needed
Standard library only — no JSON dependency is introduced for this feature.
"""
import json
import re
import sys

KEY = 'KALI_ITERM2_THEME'


def mask(text):
    """Blank out comments and string interiors (same length) so structural
    scanning can't be fooled by text inside strings or comments."""
    out = list(text)
    i, n = len(text), len(text)
    i = 0
    while i < n:
        c = text[i]
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                if text[j] == '\\':
                    out[j] = 'x'
                    if j + 1 < n:
                        out[j + 1] = 'x'
                    j += 2
                    continue
                if text[j] != '\n':
                    out[j] = 'x'
                j += 1
            # A string followed by ':' is an object key; keep it visible so
            # structural scans can find keys, while value strings stay blanked.
            k = j + 1
            while k < n and text[k] in ' \t\n\r':
                k += 1
            if k < n and text[k] == ':':
                out[i + 1:j] = list(text[i + 1:j])
            i = j + 1
        elif c == '/' and i + 1 < n and text[i + 1] == '/':
            j = i
            while j < n and text[j] != '\n':
                out[j] = ' '
                j += 1
            i = j
        elif c == '/' and i + 1 < n and text[i + 1] == '*':
            j = i
            while j < n - 1 and not (text[j] == '*' and text[j + 1] == '/'):
                if text[j] != '\n':
                    out[j] = ' '
                j += 1
            out[j] = out[j + 1] = ' '
            i = j + 2
        else:
            i += 1
    return ''.join(out)


def strip_for_validate(text):
    """Remove comments and trailing commas so json.loads can check a result."""
    s = re.sub(r'"(?:[^"\\]|\\.)*"', '""', text)          # strings first
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
    s = re.sub(r'//[^\n]*', '', s)
    s = re.sub(r',\s*([}\]])', r'\1', s)
    return s


def parses(text):
    try:
        json.loads(strip_for_validate(text))
        return True
    except ValueError:
        return False


def match_brace(masked, open_idx):
    depth = 0
    for i in range(open_idx, len(masked)):
        if masked[i] == '{':
            depth += 1
        elif masked[i] == '}':
            depth -= 1
            if depth == 0:
                return i
    return -1


def find_key(masked, key, after=0, before=None):
    """Index of a structural "key" token within [after, before), or -1."""
    for m in re.finditer(r'"%s"' % key, masked[after:before]):
        return after + m.start()
    return -1


def object_value(masked, key_idx):
    """(open, close) of the {…} object that is the value of the key at key_idx."""
    colon = masked.find(':', key_idx)
    if colon < 0:
        return -1, -1
    m = re.compile(r'\s*\{').match(masked, colon + 1)
    if not m:
        return -1, -1
    o = m.end() - 1
    c = match_brace(masked, o)
    return (o, c) if c > 0 else (-1, -1)


def insert_first_key(text, masked, open_idx, line_prefix, entry):
    """Insert `entry` as the first member of the object at open_idx."""
    close = match_brace(masked, open_idx)
    body = masked[open_idx + 1:close]
    comma = ',' if body.strip() else ''
    ins = '\n%s  %s%s' % (line_prefix, entry, comma)
    return text[:open_idx + 1] + ins + text[open_idx + 1:]


def line_indent_at(text, idx):
    start = text.rfind('\n', 0, idx) + 1
    m = re.match(r'[ \t]*', text[start:])
    return m.group(0)


def do_apply():
    try:
        text = open(PATH, encoding='utf-8').read()
    except FileNotFoundError:
        text = ''
    if not text.strip():
        new = ('{\n  "terminal": {\n    "env": {\n      "%s": "%s"\n    }\n  }\n}\n'
               % (KEY, MODE))
        assert parses(new)
        open(PATH, 'w', encoding='utf-8').write(new)
        print('CREATED')
        return 0

    if not parses(text):
        print('MALFORMED: settings.json does not parse as JSONC; nothing written.',
              file=sys.stderr)
        return 3

    masked = mask(text)
    kidx = find_key(masked, KEY)
    if kidx >= 0:
        m = re.compile(r'"%s"\s*:\s*"([^"]*)"' % KEY).match(text, kidx)
        cur = m.group(1) if m else None
        if cur == MODE:
            print('NOOP')
            return 0
        if cur in ('light', 'dark'):
            if not REPLACE:
                print('CONFLICT: existing override is "%s".' % cur, file=sys.stderr)
                return 4
            s, e = m.span(1)
            new = text[:s] + MODE + text[e:]
        else:
            print('CONFLICT: existing value %r is not managed by Kali-iTerm2; '
                  'leaving it untouched.' % cur, file=sys.stderr)
            return 3
        if not parses(new):
            print('INTERNAL: proposed edit failed validation.', file=sys.stderr)
            return 3
        open(PATH, 'w', encoding='utf-8').write(new)
        print('REPLACED')
        return 0

    root = masked.find('{')
    if root < 0:
        return 3
    tkey = find_key(masked, 'terminal', root + 1, match_brace(masked, root))
    key_entry = '"%s": "%s"' % (KEY, MODE)
    if tkey < 0:
        new = insert_first_key(text, masked, root, '',
                               '"terminal": {"env": {%s}}' % key_entry)
    else:
        to, _tc = object_value(masked, tkey)
        if to < 0:
            print('MALFORMED: "terminal" is not an object; nothing written.',
                  file=sys.stderr)
            return 3
        ekey = find_key(masked, 'env', to + 1, match_brace(masked, to))
        if ekey < 0:
            new = insert_first_key(text, masked, to, line_indent_at(text, to),
                                   '"env": {%s}' % key_entry)
        else:
            eo, _ec = object_value(masked, ekey)
            if eo < 0:
                print('MALFORMED: "env" is not an object; nothing written.',
                      file=sys.stderr)
                return 3
            new = insert_first_key(text, masked, eo, line_indent_at(text, eo),
                                   key_entry)
    if not parses(new):
        print('INTERNAL: proposed edit failed validation; nothing written.',
              file=sys.stderr)
        return 3
    open(PATH, 'w', encoding='utf-8').write(new)
    print('APPLIED')
    return 0


def do_remove():
    try:
        text = open(PATH, encoding='utf-8').read()
    except FileNotFoundError:
        print('NOKEY')
        return 0
    masked = mask(text)
    kidx = find_key(masked, KEY)
    if kidx < 0:
        print('NOKEY')
        return 0
    m = re.compile(r'"%s"\s*:\s*"(?:light|dark)"' % KEY).match(text, kidx)
    if not m:
        print('Value is not a Kali-iTerm2 setting; leaving it untouched.')
        return 0
    s, e = m.span()
    after = re.compile(r'[ \t]*,([ \t]*\n)?').match(text, e)
    if after:
        new = text[:s] + text[after.end():]
    else:
        m2 = re.compile(r',[ \t]*\n?[ \t]*$').search(text[:s])
        if m2:
            new = text[:m2.start()] + text[e:]
        elif (re.compile(r'\{\s*$').search(text[:s])
              and re.compile(r'^\s*\}').match(text[e:])):
            # Sole member written inline: { "KEY": "v" } -> {  }
            new = text[:s] + ' ' + text[e:]
        elif not text[text.rfind('\n', 0, s) + 1:s].strip():
            # Sole member of its object: drop the whole (indented) line.
            ls = text.rfind('\n', 0, s) + 1
            me = re.compile(r'[ \t]*\n?').match(text, e)
            new = text[:ls] + text[me.end():]
        else:
            new = None
    if new is None or not parses(new):
        print('Could not remove the key safely; review settings.json manually.',
              file=sys.stderr)
        return 3
    open(PATH, 'w', encoding='utf-8').write(new)
    print('REMOVED')
    return 0


CMD = sys.argv[1] if len(sys.argv) > 1 else ''
if CMD == 'apply' and len(sys.argv) not in (4, 5):
    print(__doc__)
    sys.exit(2)
if CMD == 'remove' and len(sys.argv) != 3:
    print(__doc__)
    sys.exit(2)
if CMD not in ('apply', 'remove'):
    print(__doc__)
    sys.exit(2)
PATH = sys.argv[2]
MODE, REPLACE = '', False
if CMD == 'apply':
    MODE = sys.argv[3]
    if MODE not in ('light', 'dark'):
        sys.exit(2)
    REPLACE = '--replace' in sys.argv[4:]
sys.exit(do_apply() if CMD == 'apply' else do_remove())
