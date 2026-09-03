#!/usr/bin/env bash
# 22-painel-xfce.sh — painel do Kali no Xfce, na ordem que funciona.
#
# Uso: bash 22-painel-xfce.sh [--compacto]
#
# Por que isto é um script e não uma linha de documentação:
#
# 1. `xfce4-panel-profiles load` SUBSTITUI ~/.config/xfce4/panel/ inteiro. Rodado
#    depois do 20-aplicar-xfce.sh, ele apaga o que aquele script tinha posto lá.
#    A ordem certa é: carregar o perfil primeiro, ajustar depois.
# 2. O Whisker Menu 2.8+ (Ubuntu 24.04) guarda a configuração no **xfconf**, não
#    em ~/.config/xfce4/panel/whiskermenu-<N>.rc — o arquivo legado é migrado e
#    APAGADO na primeira execução do plugin. Copiar o .rc não tem efeito nenhum
#    nesta versão; as chaves têm de ir para o xfconf, e no plugin certo, cujo
#    número só existe depois que o perfil foi carregado.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(dirname -- "$SCRIPT_DIR")"
REF="$PROJ/docs/referencia"
DRY_RUN="${DRY_RUN:-0}"

PERFIL="$REF/painel/Kali.tar.bz2"
[ "${1:-}" = "--compacto" ] && PERFIL="$REF/painel/Kali compact.tar.bz2"

if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_VERDE=$'\033[38;5;42m'
  C_AMBAR=$'\033[38;5;214m'; C_VERM=$'\033[38;5;160m'
else
  C_RESET=""; C_DIM=""; C_VERDE=""; C_AMBAR=""; C_VERM=""
fi
ok()   { printf '%s✓%s %s\n' "$C_VERDE" "$C_RESET" "$*"; }
aviso(){ printf '%s!%s %s\n' "$C_AMBAR" "$C_RESET" "$*"; }
morre(){ printf '%s✗%s %s\n' "$C_VERM" "$C_RESET" "$*" >&2; exit 1; }
run()  {
  if [ "$DRY_RUN" -eq 1 ]; then printf '%s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"; return 0; fi
  "$@"
}

case "${XDG_CURRENT_DESKTOP:-}" in
  *[Xx][Ff][Cc][Ee]*) ;;
  *) [ "$DRY_RUN" -eq 1 ] || morre "rode dentro da sessão Xfce (atual: ${XDG_CURRENT_DESKTOP:-?})" ;;
esac
command -v xfce4-panel-profiles >/dev/null \
  || morre "xfce4-panel-profiles não encontrado — sudo apt install xfce4-panel-profiles"
[ -f "$PERFIL" ] || morre "perfil não encontrado: $PERFIL"

echo "== 1/4 backup do painel atual =="
if [ -d "$HOME/.config/xfce4/panel" ]; then
  run cp -a "$HOME/.config/xfce4/panel" "$HOME/.config/xfce4/panel.bak-$(date +%Y%m%d-%H%M%S)"
  ok "painel atual copiado para ~/.config/xfce4/panel.bak-<data>"
else
  aviso "não havia ~/.config/xfce4/panel"
fi

echo "== 2/4 carregando o perfil do Kali =="
echo "   $(basename "$PERFIL")"
run xfce4-panel-profiles load "$PERFIL"
ok "perfil carregado"

echo "== 3/4 Whisker Menu (xfconf) =="
# O número do plugin vem do perfil recém-carregado; procurá-lo evita cravar "1".
WHISKER=""
for i in $(seq 1 30); do
  if [ "$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$i" 2>/dev/null || true)" = "whiskermenu" ]; then
    WHISKER="$i"; break
  fi
done

if [ -z "$WHISKER" ]; then
  aviso "nenhum plugin whiskermenu no painel — pulando os ajustes do menu"
else
  echo "   plugin-$WHISKER"
  P="/plugins/plugin-$WHISKER"
  # Origem de cada valor: docs/referencia/painel/whiskermenu-defaults.rc.
  # O perfil do painel já traz button-icon, favorites, menu-width/height e
  # position-*; estas são as que faltam nele.
  set_key() {  # set_key <chave> <tipo> <valor>
    run xfconf-query -c xfce4-panel -p "$P/$1" -n -t "$2" -s "$3"
  }
  set_key item-icon-size            int    2
  set_key category-icon-size        int    1
  set_key position-search-alternate bool   false
  set_key load-hierarchy            bool   true
  set_key command-settings          string xfce4-settings-manager
  set_key show-command-settings     bool   true
  set_key show-command-switchuser   bool   false
  set_key show-command-logoutuser   bool   false
  set_key show-command-restart      bool   false
  set_key show-command-shutdown     bool   false
  ok "ajustes do Whisker aplicados"

  # Fallback para whiskermenu < 2.8, que ainda lê o arquivo. Nas versões novas o
  # plugin migra e apaga este .rc — deixá-lo é inofensivo, copiá-lo sozinho não.
  if [ -f "$REF/painel/whiskermenu-defaults.rc" ]; then
    run cp "$REF/painel/whiskermenu-defaults.rc" \
           "$HOME/.config/xfce4/panel/whiskermenu-$WHISKER.rc"
  fi
fi

echo "== 4/4 script do IP de VPN (plugin genmon) =="
run mkdir -p "$HOME/.local/share/kali-themes"
run cp "$REF/painel/xfce4-panel-genmon-vpnip.sh" "$HOME/.local/share/kali-themes/"
run chmod +x "$HOME/.local/share/kali-themes/xfce4-panel-genmon-vpnip.sh"
ok "genmon no lugar"

echo
ok "painel do Kali aplicado"
echo "Confira: painel único no topo (34 px), dragão à esquerda, lista de janelas só"
echo "com ícones, gráfico de CPU azul→ciano e relógio 24 h sem segundos."
echo "Para desfazer: mv ~/.config/xfce4/panel.bak-<data> ~/.config/xfce4/panel"
