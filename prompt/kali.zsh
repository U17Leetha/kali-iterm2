# Original Kali-inspired two-line Zsh prompt.
# Loaded after any existing prompt framework, and scoped to interactive shells.
[[ -o interactive ]] || return 0
setopt prompt_subst
if [[ ${KALI_ITERM2_THEME:-light} == dark ]]; then
  local_kali_frame='#69B5FF'
  local_kali_accent='#69B5FF'
  local_kali_path='#EBEFF7'
else
  # Kali's structure reads cyan/aqua while identity stays a strong blue.
  local_kali_frame='#009BC9'
  local_kali_accent='#006BD6'
  local_kali_path='#1D2430'
fi
PROMPT="%F{${local_kali_frame}}┌──(%F{${local_kali_accent}}%B%n㉿%m%b%F{${local_kali_frame}})-[%F{${local_kali_path}}%B%~%b%F{${local_kali_frame}}]
└─%(!.#.$)%f "
RPROMPT=''
unset local_kali_frame local_kali_accent local_kali_path
