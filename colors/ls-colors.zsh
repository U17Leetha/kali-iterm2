# GNU ls supports archive extension colors; BSD ls uses LSCOLORS.
if [[ ${KALI_ITERM2_THEME:-light} == dark ]]; then
  export LS_COLORS='rs=0:di=01;34:ln=01;36:ex=01;32:*.tar=01;31:*.gz=01;31:*.tgz=01;31:*.zip=01;31:*.7z=01;31:*.rar=01;31:*.xz=01;31:*.bz2=01;31:*.zst=01;31'
else
  export LS_COLORS='rs=0:di=01;34:ln=36:ex=01;32:*.tar=01;31:*.gz=01;31:*.tgz=01;31:*.zip=01;31:*.7z=01;31:*.rar=01;31:*.xz=01;31:*.bz2=01;31:*.zst=01;31'
fi
export LSCOLORS='ExGxcxdxbxegedabagacad'
if command -v gls >/dev/null 2>&1; then
  alias ls='gls --color=auto'
else
  alias ls='ls -G'
fi
