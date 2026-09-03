#!/usr/bin/env bash
# Aplica a aparência do Kali no KDE Plasma 5.27 (rode DENTRO da sessão Plasma).
# Uso: bash 30-aplicar-plasma.sh
set -euo pipefail

REF="$HOME/Desktop/interface-kali/docs/referencia/kde"
KW=$(command -v kwriteconfig5 || command -v kwriteconfig6 || true)
[ -n "$KW" ] || { echo "kwriteconfig5 não encontrado — instale o Plasma primeiro"; exit 1; }

echo "== tema global =="
if command -v plasma-apply-lookandfeel >/dev/null; then
  plasma-apply-lookandfeel -a org.kali.kalidark.desktop || \
    echo "  tema global não encontrado — rode 10-baixar-assets.sh"
fi
command -v plasma-apply-colorscheme  >/dev/null && plasma-apply-colorscheme KaliDark || true
command -v plasma-apply-desktoptheme >/dev/null && plasma-apply-desktoptheme kali    || true

echo "== ícones, fontes, estilo =="
"$KW" --file kdeglobals --group Icons   --key Theme       Flat-Remix-Blue-Dark
"$KW" --file kdeglobals --group General --key font        "Cantarell,11,-1,5,50,0,0,0,0,0"
"$KW" --file kdeglobals --group General --key fixed       "Fira Code,10,-1,5,50,0,0,0,0,0,Regular"
"$KW" --file kdeglobals --group KDE     --key widgetStyle Breeze

echo "== decoração de janela (Breeze + ordem de botões do Kali) =="
# a decoração original do Kali (org.kali.kali) é um plugin Qt6 e não existe no Plasma 5
"$KW" --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
"$KW" --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft  M
"$KW" --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight IAX
"$KW" --file kwinrc --group Desktops --key Number 2

echo "== Konsole =="
mkdir -p "$HOME/.local/share/konsole"
cp "$REF/Kali-Dark.profile" "$REF/Kali-Dark.colorscheme" "$HOME/.local/share/konsole/" 2>/dev/null || true
"$KW" --file konsolerc --group "Desktop Entry" --key DefaultProfile Kali-Dark.profile

echo "== tela de bloqueio =="
BG=/usr/share/desktop-base/kali-theme/login/background
[ -e "$BG" ] || BG="$HOME/.local/share/backgrounds/kali/kali-cubes2-16x9.jpg"
"$KW" --file kscreenlockerrc --group Greeter --group Wallpaper \
      --group org.kde.image --group General --key Image "$BG"

echo "== recarregando o KWin =="
qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo
echo "Painel: para trocar o ícone do menu pelo dragão e fixar os lançadores:"
echo "  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \\"
echo "    \"\$(cat $REF/kali-panel-customizations.js)\""
