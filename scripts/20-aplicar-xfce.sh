#!/usr/bin/env bash
# Aplica a aparência do Kali na sessão Xfce (rode DENTRO da sessão Xfce).
# Uso: bash 20-aplicar-xfce.sh
set -euo pipefail

# Caminhos resolvidos a partir da localização deste script: o projeto funciona
# em qualquer diretório, clonado por qualquer usuário.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(dirname -- "$SCRIPT_DIR")"
REF="$PROJ/docs/referencia"
[ -d "$REF" ] || { echo "docs/referencia não encontrada (procurei em $REF)"; exit 1; }

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

# A paleta configura o xfce4-terminal e mais nenhum terminal. Sem apontar o
# terminal preferido para ele, os atalhos do Kali (Super+T, Ctrl+Alt+T, que rodam
# `exo-open --launch TerminalEmulator`) e o launcher do painel abrem o terminal
# padrão do sistema — no Ubuntu isso pode ser tilix, terminator ou gnome-terminal,
# e aí nada muda de aparência.
HELPERS="$HOME/.config/xfce4/helpers.rc"
ATUAL=""
[ -f "$HELPERS" ] && ATUAL="$(awk -F= '/^TerminalEmulator=/{print $2; exit}' "$HELPERS" 2>/dev/null || true)"
if [ "$ATUAL" = "xfce4-terminal" ]; then
  echo "  terminal preferido já é o xfce4-terminal"
elif command -v xfce4-terminal >/dev/null; then
  if [ -f "$HELPERS" ]; then
    cp "$HELPERS" "$HELPERS.bak-$(date +%Y%m%d-%H%M%S)"
    grep -v '^TerminalEmulator=' "$HELPERS" > "$HELPERS.tmp" 2>/dev/null || true
    printf 'TerminalEmulator=xfce4-terminal\n' >> "$HELPERS.tmp"
    mv "$HELPERS.tmp" "$HELPERS"
  else
    printf 'TerminalEmulator=xfce4-terminal\n' > "$HELPERS"
  fi
  echo "  terminal preferido = xfce4-terminal (era: ${ATUAL:-nao definido})"
else
  echo "  xfce4-terminal não instalado — a paleta não terá onde aparecer"
fi

# O "Root Terminal" do painel do Kali roda `pkexec x-terminal-emulator`, que é
# alternativa global do dpkg: só avisamos, porque trocá-la exige sudo.
XTE="$(update-alternatives --query x-terminal-emulator 2>/dev/null | awk '/^Value:/{print $2; exit}' || true)"
case "$XTE" in
  *xfce4-terminal*|"") ;;
  *) echo "  atenção: x-terminal-emulator aponta para $XTE"
     echo "           o \"Root Terminal\" do painel sairia sem a paleta do Kali."
     echo "           trocar:  sudo update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper" ;;
esac

echo
echo "Falta o painel — e ele é etapa separada de propósito:"
echo "  bash \"$SCRIPT_DIR/22-painel-xfce.sh\"            # painel de 34 px"
echo "  bash \"$SCRIPT_DIR/22-painel-xfce.sh\" --compacto  # painel de 28 px"
echo
echo "Não carregue o perfil com 'xfce4-panel-profiles load' à mão: ele substitui"
echo "~/.config/xfce4/panel/ inteiro e desfaz ajustes feitos antes. O 22 carrega o"
echo "perfil primeiro e só então configura o Whisker Menu e o genmon, na ordem que"
echo "funciona."
