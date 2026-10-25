#!/bin/bash
# Kali-iTerm2 test suite. Runs every scenario inside an isolated temporary
# HOME; it never reads or writes the real user's shell configuration.
# Compatible with stock macOS bash 3.2.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="$(mktemp -d)"
trap 'chmod -R u+rwX "$BASE" 2>/dev/null; rm -rf "$BASE"' EXIT

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [[ -n "${2:-}" ]] && printf '       %s\n' "$2"; }
skip() { SKIP=$((SKIP+1)); printf '  skip %s (%s)\n' "$1" "${2:-}"; }

new_home() { # new_home <name> -> echoes path
  local h="$BASE/$1"
  mkdir -p "$h"
  printf '%s\n' "$h"
}

run_install() { # run_install <home> [mode] ; non-interactive (no tty)
  HOME="$1" bash "$ROOT/install.sh" ${2:+"$2"} </dev/null >/tmp/kali-t-install.log 2>&1
}
run_uninstall() { # run_uninstall <home>
  HOME="$1" bash "$ROOT/uninstall.sh" </dev/null >/tmp/kali-t-uninstall.log 2>&1
}
block_count() { local c; c=$(grep -c 'kali-iterm2 managed >>>' "$1/.zshrc" 2>/dev/null) || true; echo "${c:-0}"; }

# ---------------------------------------------------------------- syntax ----
echo "== syntax and format =="
bash -n "$ROOT/install.sh"   && ok "install.sh parses (bash)"        || bad "install.sh parse"
bash -n "$ROOT/uninstall.sh" && ok "uninstall.sh parses (bash)"      || bad "uninstall.sh parse"
zsh -n "$ROOT/prompt/kali.zsh"      && ok "prompt/kali.zsh parses"       || bad "prompt parse"
zsh -n "$ROOT/colors/ls-colors.zsh" && ok "colors/ls-colors.zsh parses"  || bad "colors parse"
for m in light dark; do
  plutil -lint "$ROOT/themes/kali-$m.itermcolors" >/dev/null 2>&1 \
    && ok "kali-$m.itermcolors is a valid plist" || bad "kali-$m.itermcolors plist"
done

# ------------------------------------------------------- profile generation --
echo "== iTerm2 profile generation =="
PJ="$BASE/profiles.json"
python3 "$ROOT/make_profiles.py" "$PJ" >/dev/null 2>&1 && ok "make_profiles.py runs" || bad "make_profiles.py run"
python3 -m json.tool "$PJ" >/dev/null 2>&1 && ok "profiles JSON is valid" || bad "profiles JSON invalid"
GUIDS1=$(python3 -c "import json;print(sorted(p['Guid'] for p in json.load(open('$PJ'))['Profiles']))")
python3 "$ROOT/make_profiles.py" "$PJ" >/dev/null 2>&1
GUIDS2=$(python3 -c "import json;print(sorted(p['Guid'] for p in json.load(open('$PJ'))['Profiles']))")
[[ "$GUIDS1" == "$GUIDS2" ]] && ok "profile GUIDs stable across regeneration" || bad "GUIDs unstable"

# ------------------------------------------------------------- scenarios ----
echo "== installer scenarios =="

# 1. Clean install, light (no pre-existing .zshrc)
H=$(new_home s1); run_install "$H" light
if [[ $? -eq 0 && $(block_count "$H") == 1 && -f "$H/.config/kali-iterm2/prompt/kali.zsh" \
   && -f "$H/Library/Application Support/iTerm2/DynamicProfiles/kali-iterm2.json" ]]; then
  ok "clean install (light) creates one block and all files"
else bad "clean install light" "$(tail -3 /tmp/kali-t-install.log)"; fi

# 2. Clean install, dark
H=$(new_home s2); run_install "$H" dark
grep -qF 'KALI_ITERM2_THEME="${KALI_ITERM2_THEME:-dark}"' "$H/.zshrc" 2>/dev/null \
  && ok "clean install (dark) sets default theme=dark" || bad "clean install dark"

# 3. Reinstall same theme -> still exactly one block
run_install "$H" dark
[[ $(block_count "$H") == 1 ]] && ok "reinstalling same theme keeps a single block" \
  || bad "duplicate blocks after reinstall" "count=$(block_count "$H")"

# 4/5. Switch dark -> light -> dark
run_install "$H" light
grep -qF 'KALI_ITERM2_THEME="${KALI_ITERM2_THEME:-light}"' "$H/.zshrc" && [[ $(block_count "$H") == 1 ]] \
  && ok "switch dark to light (single block, theme updated)" || bad "switch dark->light"
run_install "$H" dark
grep -qF 'KALI_ITERM2_THEME="${KALI_ITERM2_THEME:-dark}"' "$H/.zshrc" && [[ $(block_count "$H") == 1 ]] \
  && ok "switch light to dark (single block, theme updated)" || bad "switch light->dark"

# 6. Existing Oh My Zsh configuration preserved
H=$(new_home s6)
printf 'export ZSH="$HOME/.oh-my-zsh"\nsource $ZSH/oh-my-zsh.sh\nplugins=(git z)\n' > "$H/.zshrc"
run_install "$H" light
grep -q 'oh-my-zsh.sh' "$H/.zshrc" && grep -q 'plugins=(git z)' "$H/.zshrc" \
  && ok "Oh My Zsh lines preserved" || bad "OMZ config damaged"

# 7. Existing Starship configuration preserved; our block appended after it
H=$(new_home s7)
printf 'eval "$(starship init zsh)"\n' > "$H/.zshrc"
run_install "$H" dark
grep -q 'starship init zsh' "$H/.zshrc" && [[ $(grep -n 'kali-iterm2 managed >>>' "$H/.zshrc" | cut -d: -f1) -gt $(grep -n 'starship init zsh' "$H/.zshrc" | cut -d: -f1) ]] \
  && ok "Starship preserved; kali block appended after it" || bad "starship scenario"

# 8. Uninstall removes managed config, preserves user content
printf '\nexport CANARY=keep-me\n' >> "$H/.zshrc"   # unrelated change AFTER install
run_uninstall "$H"
if [[ $(block_count "$H") == 0 ]] && grep -q 'starship init zsh' "$H/.zshrc" \
   && grep -q 'CANARY=keep-me' "$H/.zshrc" && [[ ! -e "$H/.config/kali-iterm2" ]] \
   && [[ ! -e "$H/Library/Application Support/iTerm2/DynamicProfiles/kali-iterm2.json" ]]; then
  ok "uninstall removes managed files/block, keeps user content incl. post-install edits"
else bad "uninstall scenario" "$(cat /tmp/kali-t-uninstall.log)"; fi
ls "$H"/.zshrc.kali-iterm2.uninstall.*.bak >/dev/null 2>&1 \
  && ok "uninstall kept a .zshrc backup" || bad "no uninstall backup"
run_uninstall "$H" && grep -q 'starship init zsh' "$H/.zshrc" \
  && ok "second uninstall is a safe no-op" || bad "repeat uninstall"

# 9. HOME path containing spaces
H=$(new_home "home with spaces and (parens)")
run_install "$H" light
grep -q 'kali-iterm2 managed >>>' "$H/.zshrc" 2>/dev/null \
  && ok "install works under HOME containing spaces/parens" || bad "spaces in HOME" "$(tail -3 /tmp/kali-t-install.log)"

# 10. Missing GNU coreutils: BSD fallback alias, no error
if env PATH=/usr/bin:/bin zsh -f -c 'command -v gls >/dev/null 2>&1'; then
  skip "gls absent from restricted PATH" "gls found in /usr/bin?!"
else
  ALIASED=$(env PATH=/usr/bin:/bin HOME="$BASE/s10" zsh -f -c "source '$ROOT/colors/ls-colors.zsh'; alias ls" 2>/dev/null)
  [[ "$ALIASED" == *"-G"* ]] && ok "without gls: falls back to BSD 'ls -G'" || bad "gls fallback" "$ALIASED"
fi
if command -v gls >/dev/null 2>&1; then
  ALIASED=$(HOME="$BASE/s10" zsh -f -c "source '$ROOT/colors/ls-colors.zsh'; alias ls" 2>/dev/null)
  [[ "$ALIASED" == *"color"* ]] && ok "with gls present: uses 'gls --color'" || bad "gls path" "$ALIASED"
else
  skip "gls --color alias check" "gls not installed on this host"
fi

# 11. Interrupted/failed install leaves .zshrc untouched
H=$(new_home s11); printf 'CANARY-INTERRUPT\n' > "$H/.zshrc"
mkdir -p "$H/.config"; chmod 500 "$H/.config"
if run_install "$H" light; then
  bad "failing install should exit non-zero"
else
  grep -q 'kali-iterm2 managed' "$H/.zshrc" && bad "failed install modified .zshrc" \
    || ok "failed install aborts before touching .zshrc"
fi
chmod 700 "$H/.config"

# 12. Repeated install/uninstall cycles -> no duplicates
H=$(new_home s12)
CYC_OK=1
for i in 1 2 3; do
  run_install "$H" light || CYC_OK=0
  [[ $(block_count "$H") == 1 ]] || CYC_OK=0
  run_uninstall "$H"   || CYC_OK=0
  [[ $(block_count "$H") == 0 ]] || CYC_OK=0
done
run_install "$H" dark
[[ $CYC_OK == 1 && $(block_count "$H") == 1 ]] \
  && ok "3x install/uninstall cycles leave exactly one block" || bad "cycle test"

# Argument validation
H=$(new_home s13)
HOME="$H" bash "$ROOT/install.sh" bogus </dev/null >/dev/null 2>&1; [[ $? == 2 ]] \
  && ok "invalid theme argument rejected with exit 2" || bad "arg validation"
HOME="$H" bash "$ROOT/install.sh" light extra </dev/null >/dev/null 2>&1; [[ $? == 2 ]] \
  && ok "extra arguments rejected with exit 2" || bad "arg count validation"

# -------------------------------------------------------------- prompt ------
echo "== prompt behavior (isolated interactive zsh) =="
H=$(new_home prompt)
mkdir -p "$H/we ird dir (1)"
OUT=$(HOME="$H" zsh -f -i -c "source '$ROOT/prompt/kali.zsh'; cd '$H/we ird dir (1)'; print -P -- \$PROMPT" 2>&1)
RC=$?
if [[ $RC == 0 && "$OUT" == *"┌──("*"㉿"* && "$OUT" == *"└─"* ]]; then
  ok "prompt renders two-line Kali layout in odd-named directory"
else bad "prompt render (rc=$RC)" "$OUT"; fi
OUT=$(HOME="$H" KALI_ITERM2_THEME=dark zsh -f -i -c "source '$ROOT/prompt/kali.zsh'; print -P -- \$PROMPT" 2>&1); RC=$?
[[ $RC == 0 && "$OUT" == *"┌──("* ]] && ok "prompt renders in dark theme" || bad "dark prompt render"
# non-interactive shells must be untouched
OUT=$(HOME="$H" zsh -f -c "P=orig; source '$ROOT/prompt/kali.zsh'; print \$PROMPT" 2>&1)
[[ "$OUT" != *"┌──"* ]] && ok "non-interactive shell prompt untouched" || bad "interactive guard"

# -------------------------------------------- per-session theme override ----
echo "== per-session theme override (Zed-style terminal env) =="
H=$(new_home override); run_install "$H" light   # installed default: light
OUT=$(HOME="$H" KALI_ITERM2_THEME=dark zsh -f -c 'source "$HOME/.zshrc"; print -r -- $KALI_ITERM2_THEME' 2>&1)
[[ "$OUT" == dark ]] && ok "session env KALI_ITERM2_THEME=dark wins over installed light default" \
  || bad "session override ignored" "$OUT"
OUT=$(HOME="$H" zsh -f -c 'source "$HOME/.zshrc"; print -r -- $KALI_ITERM2_THEME' 2>&1)
[[ "$OUT" == light ]] && ok "unset session env falls back to installed default (light)" \
  || bad "fallback to installed default" "$OUT"
OUT=$(HOME="$H" KALI_ITERM2_THEME=dark zsh -f -c 'source "$HOME/.zshrc"; print -r -- $LS_COLORS' 2>&1)
[[ "$OUT" == *'ln=01;36'* ]] && ok "ls colors follow the session theme (dark variant)" \
  || bad "ls colors ignored session theme" "$OUT"
OUT=$(HOME="$H" KALI_ITERM2_THEME=bogus zsh -f -i -c "source '$ROOT/prompt/kali.zsh'; print -r -- \$PROMPT" 2>&1)
[[ "$OUT" == *'#006BD6'* ]] && ok "invalid session value safely falls back to light palette" \
  || bad "invalid-value fallback" "$OUT"

# --------------------------------------------------------- interactive UI ---
echo "== interactive installer (pty) =="
if command -v expect >/dev/null 2>&1; then
  H=$(new_home pty)
  EXP="$BASE/pty.exp"
  cat > "$EXP" <<EOF
set timeout 20
spawn env HOME=$H bash $ROOT/install.sh
expect {
  -re {Choice \[1-3\]:} { send "1\r"; exp_continue }
  -re {Install\? \[y/N\]:} { send "y\r"; exp_continue }
  eof
}
catch wait result
exit [lindex \$result 3]
EOF
  expect "$EXP" >/tmp/kali-t-pty.log 2>&1
  if [[ $? == 0 && $(block_count "$H") == 1 ]] && grep -qF 'KALI_ITERM2_THEME="${KALI_ITERM2_THEME:-light}"' "$H/.zshrc"; then
    ok "interactive menu (pty): pick 1 + confirm installs light"
  else
    bad "interactive pty run" "see /tmp/kali-t-pty.log"
  fi
elif command -v gtimeout >/dev/null 2>&1 && command -v script >/dev/null 2>&1; then
  skip "interactive pty run" "expect unavailable; BSD script(1) does not forward piped stdin"
else
  skip "interactive pty run" "expect/gtimeout/script unavailable"
fi

# ---------------------------------------------------------------- report ----
echo
echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
[[ $FAIL == 0 ]] || exit 1
