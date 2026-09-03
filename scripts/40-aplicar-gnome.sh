#!/usr/bin/env bash
# Aplica a aparência do Kali no GNOME 46 (sessão atual).
# Uso: bash 40-aplicar-gnome.sh
set -euo pipefail

echo "== tema, ícones e fontes =="
gsettings set org.gnome.desktop.interface color-scheme          'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme             'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface icon-theme            'Flat-Remix-Blue-Dark'
gsettings set org.gnome.desktop.interface cursor-theme          'Adwaita'
gsettings set org.gnome.desktop.interface font-name             'Cantarell 11'
gsettings set org.gnome.desktop.interface document-font-name    'Cantarell 11'
gsettings set org.gnome.desktop.interface monospace-font-name   'Fira Code Medium 10'
gsettings set org.gnome.desktop.wm.preferences button-layout    'appmenu:minimize,maximize,close'

echo "== tema do shell (precisa da extensão user-theme) =="
if gnome-extensions list 2>/dev/null | grep -q user-theme; then
  gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
  gsettings set org.gnome.shell.extensions.user-theme name 'Kali-Dark'
else
  echo "  extensão user-theme ausente: sudo apt install gnome-shell-extensions"
fi

echo "== papel de parede =="
WALL=""
for c in "$HOME/.local/share/backgrounds/kali/kali-cubes-16x9.jpg" \
         /usr/share/backgrounds/kali/kali-cubes-16x9.jpg; do
  [ -e "$c" ] && WALL="$c" && break
done
if [ -n "$WALL" ]; then
  gsettings set org.gnome.desktop.background picture-uri      "file://$WALL"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALL"
  gsettings set org.gnome.desktop.background picture-options  'zoom'
  LOCK="${WALL/kali-cubes-16x9/kali-cubes2-16x9}"
  [ -e "$LOCK" ] || LOCK="$WALL"
  gsettings set org.gnome.desktop.screensaver picture-uri     "file://$LOCK"
  gsettings set org.gnome.desktop.screensaver picture-options 'zoom'
  echo "  $WALL"
else
  echo "  wallpaper não encontrado — rode 10-baixar-assets.sh --instalar-usuario"
fi

echo "== dock (dash-to-dock como no Kali) =="
if gnome-extensions list 2>/dev/null | grep -q 'dash-to-dock@micxgx.gmail.com'; then
  gnome-extensions disable ubuntu-dock@ubuntu.com 2>/dev/null || true
  gnome-extensions enable  dash-to-dock@micxgx.gmail.com
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
  gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS'
  gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
  gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink false
  gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true
else
  echo "  dash-to-dock não instalado — mantendo o ubuntu-dock"
fi

echo "== ícones da área de trabalho =="
gsettings set org.gnome.shell.extensions.ding icon-size 'small'   2>/dev/null || true
gsettings set org.gnome.shell.extensions.ding show-home false     2>/dev/null || true
gsettings set org.gnome.shell.extensions.ding show-trash false    2>/dev/null || true
gsettings set org.gnome.shell.extensions.ding show-volumes false  2>/dev/null || true

echo "== extensões da barra superior =="
for e in apps-menu places-menu drive-menu system-monitor; do
  gnome-extensions enable "$e@gnome-shell-extensions.gcampax.github.com" 2>/dev/null \
    || echo "  não encontrada: $e"
done

echo "== terminal =="
P=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || true)
if [ -n "${P:-}" ]; then
  G="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P/"
  gsettings set "$G" palette "['#1F2229','#D41919','#5EBDAB','#FEA44C','#367BF0','#9755B3','#49AEE6','#E6E6E6','#198388','#EC0101','#47D4B9','#FF8A18','#277FFF','#962AC3','#05A1F7','#FFFFFF']"
  gsettings set "$G" use-theme-colors true
  gsettings set "$G" bold-is-bright true
  gsettings set "$G" scrollback-unlimited true
  gsettings set "$G" use-transparent-background true
  gsettings set "$G" background-transparency-percent 5
  gsettings set "$G" use-system-font false
  gsettings set "$G" font 'Fira Code Medium 10'
  gsettings set org.gnome.Terminal.Legacy.Settings theme-variant 'dark'
  gsettings set org.gnome.Terminal.Legacy.Settings confirm-close false
fi

echo "== editor de texto =="
gsettings set org.gnome.TextEditor style-scheme 'Kali-Dark' 2>/dev/null || true

echo "== monitor do sistema =="
gsettings set org.gnome.gnome-system-monitor cpu-stacked-area-chart true 2>/dev/null || true
gsettings set org.gnome.gnome-system-monitor mem-color     '#B8174C' 2>/dev/null || true
gsettings set org.gnome.gnome-system-monitor net-in-color  '#367BF0' 2>/dev/null || true
gsettings set org.gnome.gnome-system-monitor net-out-color '#D41919' 2>/dev/null || true
gsettings set org.gnome.gnome-system-monitor swap-color    '#19a187' 2>/dev/null || true

echo
echo "Pronto. Em Wayland, faça logout/login para o tema do shell entrar."
echo "Prompt do terminal: veja docs/guias/07-terminal-e-prompt.md §7.6."
