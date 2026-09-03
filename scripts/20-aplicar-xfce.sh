#!/usr/bin/env bash
# Aplica a aparência do Kali na sessão Xfce (rode DENTRO da sessão Xfce).
# Uso: bash 20-aplicar-xfce.sh
set -euo pipefail

REF="$HOME/Desktop/interface-kali/docs/referencia"
[ -d "$REF" ] || { echo "referência não encontrada em $REF"; exit 1; }

if ! command -v xfconf-query >/dev/null; then
  echo "xfconf-query não encontrado — instale o Xfce primeiro (veja docs/guias/04-ambiente-xfce.md)"; exit 1
fi

echo "== xfconf: tema, ícones, fontes, janelas =="
xfconf-query -c xsettings -p /Net/ThemeName          -s Kali-Dark
xfconf-query -c xsettings -p /Net/IconThemeName      -s Flat-Remix-Blue-Dark
xfconf-query -c xsettings -p /Gtk/CursorThemeName    -s Adwaita
xfconf-query -c xsettings -p /Gtk/CursorThemeSize    -t int -s 24
xfconf-query -c xsettings -p /Gtk/FontName           -s "Cantarell 11"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName  -s "Fira Code Medium 10"
xfconf-query -c xsettings -p /Xft/HintStyle          -s hintslight
xfconf-query -c xsettings -p /Xft/RGBA               -s rgb
xfconf-query -c xfwm4 -p /general/theme              -s Kali-Dark
xfconf-query -c xfwm4 -p /general/button_layout      -s "O|HMC"
xfconf-query -c xfwm4 -p /general/title_font         -s "Cantarell Bold 9"
xfconf-query -c xfwm4 -p /general/easy_click         -s Super
xfconf-query -c xfwm4 -p /general/workspace_count    -t int -s 4

echo "== papel de parede =="
WALL=""
for c in /usr/share/backgrounds/kali-16x9/default \
         /usr/share/backgrounds/kali/kali-cubes-16x9.jpg \
         "$HOME/.local/share/backgrounds/kali/kali-cubes-16x9.jpg"; do
  [ -e "$c" ] && WALL="$c" && break
done
if [ -n "$WALL" ]; then
  for p in $(xfconf-query -c xfce4-desktop -l | grep -E 'last-image$|image-path$'); do
    xfconf-query -c xfce4-desktop -p "$p" -s "$WALL"
  done
  echo "  $WALL"
else
  echo "  wallpaper do Kali não encontrado — rode 10-baixar-assets.sh"
fi

echo "== terminal =="
mkdir -p "$HOME/.config/xfce4/terminal"
cp "$REF/shell/xfce4-terminalrc" "$HOME/.config/xfce4/terminal/terminalrc"

echo "== Whisker Menu =="
mkdir -p "$HOME/.config/xfce4/panel"
cp "$REF/painel/whiskermenu-defaults.rc" "$HOME/.config/xfce4/panel/whiskermenu-1.rc"

echo "== script do IP de VPN (plugin genmon) =="
mkdir -p "$HOME/.local/share/kali-themes"
cp "$REF/painel/xfce4-panel-genmon-vpnip.sh" "$HOME/.local/share/kali-themes/"
chmod +x "$HOME/.local/share/kali-themes/xfce4-panel-genmon-vpnip.sh"

echo
echo "Falta o painel. Com o xfce4-panel-profiles instalado:"
echo "  xfce4-panel-profiles load \"$REF/painel/Kali.tar.bz2\""
echo "(ou 'Kali compact.tar.bz2' para o painel de 28 px)"
