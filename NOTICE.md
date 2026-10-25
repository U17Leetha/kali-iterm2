# Notices and Provenance

## License

Kali-iTerm2 is licensed under the MIT License (see `LICENSE`).

## Origin of the artwork

- The two color palettes (`themes/kali-light.itermcolors`,
  `themes/kali-dark.itermcolors`) were produced independently for this project
  by choosing hex values and encoding them in iTerm2's color-scheme format.
  They are original works, not copies or conversions of any third-party theme
  file.
- The zsh prompt (`prompt/kali.zsh`) is an original implementation. It evokes
  the general look of a Kali-style two-line prompt (box-drawing prefix,
  user/host, path, root marker) but was written from scratch; it contains no
  code copied or adapted from the Kali Linux `zsh` configuration, Oh My Zsh,
  or any published dotfiles repository.
- The `ls` color setup (`colors/ls-colors.zsh`) is likewise original.

## Trademarks

"Kali", "Kali Linux", and the Kali dragon are registered trademarks of
Offensive Security GmbH. This project is **not** affiliated with, endorsed by,
or sponsored by Offensive Security or the Kali Linux project; the names are
used only to describe the visual style it imitates. See the disclaimer in
`README.md`.

## Third-party software

No third-party source code is bundled or downloaded at install time. Runtime
dependencies (macOS system tools, `python3`, optionally GNU `coreutils` for
`gls`) are invoked as installed on your machine and remain under their own
licenses.
