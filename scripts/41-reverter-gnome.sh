#!/usr/bin/env bash
# Volta o GNOME ao padrão desta máquina (Yaru-purple-dark / Ubuntu Sans).
# Uso: bash 41-reverter-gnome.sh
set -euo pipefail

gsettings set org.gnome.desktop.interface gtk-theme           'Yaru-purple-dark'
gsettings set org.gnome.desktop.interface icon-theme          'Yaru-purple'
gsettings set org.gnome.desktop.interface cursor-theme        'Yaru'
gsettings set org.gnome.desktop.interface font-name           'Ubuntu Sans 11'
gsettings set org.gnome.desktop.interface document-font-name  'Ubuntu Sans 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Sans Mono 13'
gsettings set org.gnome.shell.extensions.user-theme name ''
gsettings reset org.gnome.desktop.wm.preferences button-layout
gsettings reset org.gnome.desktop.background picture-uri
gsettings reset org.gnome.desktop.background picture-uri-dark
gsettings reset org.gnome.desktop.background picture-options
gsettings reset org.gnome.desktop.screensaver picture-uri
gsettings reset org.gnome.desktop.screensaver picture-options

gnome-extensions enable  ubuntu-dock@ubuntu.com          2>/dev/null || true
gnome-extensions disable dash-to-dock@micxgx.gmail.com   2>/dev/null || true
gsettings reset-recursively org.gnome.shell.extensions.dash-to-dock 2>/dev/null || true
gsettings reset-recursively org.gnome.shell.extensions.ding         2>/dev/null || true

for e in apps-menu places-menu drive-menu system-monitor; do
  gnome-extensions disable "$e@gnome-shell-extensions.gcampax.github.com" 2>/dev/null || true
done

P=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || true)
if [ -n "${P:-}" ]; then
  G="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P/"
  for k in palette use-theme-colors bold-is-bright scrollback-unlimited \
           use-transparent-background background-transparency-percent \
           use-system-font font; do
    gsettings reset "$G" "$k" 2>/dev/null || true
  done
  gsettings reset org.gnome.Terminal.Legacy.Settings theme-variant 2>/dev/null || true
fi

gsettings reset org.gnome.TextEditor style-scheme 2>/dev/null || true

echo "GNOME revertido. Faça logout/login para o shell voltar ao tema padrão."
echo "Lembre de remover o bloco do prompt Kali do ~/.zshrc, se você o adicionou."
