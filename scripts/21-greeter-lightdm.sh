#!/usr/bin/env bash
# 21-greeter-lightdm.sh — aparência do Kali na tela de login do LightDM.
#
# Uso: bash 21-greeter-lightdm.sh aplicar | reverter | status
#
# Esta é a camada de MAIOR RISCO junto com GRUB e Plymouth: config inválida aqui
# deixa a máquina sem tela de entrada. Por isso o script exige confirmação, faz
# backup datado e valida cada asset ANTES de escrever em /etc.
#
# Só faz sentido se o LightDM for o gerenciador de login (o Kali usa LightDM; o
# Ubuntu vem com GDM). Ver docs/guias/08-boot-login-e-logos.md §8.4.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(dirname -- "$SCRIPT_DIR")"
REF="$PROJ/docs/referencia"
CONF=/etc/lightdm/lightdm-gtk-greeter.conf
ORIGEM="$REF/lightdm-gtk-greeter.conf"

# Herdados do kali-look.sh quando chamado por ele; utilizáveis à mão também.
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"

if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_VERDE=$'\033[38;5;42m'; C_AMBAR=$'\033[38;5;214m'; C_VERM=$'\033[38;5;160m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_VERDE=""; C_AMBAR=""; C_VERM=""
fi

info() { printf '%s\n' "$*"; }
ok()   { printf '%s✓%s %s\n' "$C_VERDE" "$C_RESET" "$*"; }
aviso(){ printf '%s!%s %s\n' "$C_AMBAR" "$C_RESET" "$*"; }
erro() { printf '%s✗%s %s\n' "$C_VERM" "$C_RESET" "$*" >&2; }
morre(){ erro "$*"; exit 1; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"
    return 0
  fi
  "$@"
}

run_sudo() {
  printf '%ssudo:%s %s\n' "$C_AMBAR" "$C_RESET" "$*"
  run sudo "$@"
}

confirmar() {
  local pergunta="$1"
  if [ "$ASSUME_YES" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then return 0; fi
  if [ ! -t 0 ]; then
    aviso "sem terminal interativo; assumindo NÃO para: $pergunta"
    return 1
  fi
  local r
  read -r -p "$(printf '%s?%s %s [s/N] ' "$C_AMBAR" "$C_RESET" "$pergunta")" r
  case "${r,,}" in s|sim|y|yes) return 0 ;; esac
  return 1
}

# O sudo precisa de um TTY para pedir a senha. Chamado de um agente ou de um pipe,
# ele falha no meio do trabalho e deixa /etc pela metade — melhor barrar na entrada.
exige_sudo_utilizavel() {
  if [ "$DRY_RUN" -eq 1 ]; then return 0; fi
  if sudo -n true 2>/dev/null; then return 0; fi
  if [ -t 0 ]; then return 0; fi
  erro "este comando precisa de sudo e não há terminal para digitar a senha."
  info "Rode você mesmo, num terminal de verdade:"
  info "  $PROJ/scripts/kali-look.sh greeter aplicar"
  info "(no prompt do Claude Code, prefixe com '! ' para rodar na sua sessão)"
  return 1
}

# ------------------------------------------------------------------- assets ---
# O greeter roda como o usuário de sistema `lightdm`: ele NÃO lê o seu $HOME.
# Tema e ícones têm de estar em /usr/share — assets instalados no modo usuário
# (~/.themes, ~/.local/share/icons) são invisíveis aqui.
declare -a FALTANDO=()

checa_asset() {
  local caminho="$1" descricao="$2"
  if [ -e "$caminho" ]; then
    ok "$descricao: $caminho"
  else
    erro "$descricao NÃO existe: $caminho"
    FALTANDO+=("$caminho")
  fi
}

valida_assets_do_sistema() {
  info "Conferindo o que o greeter precisa em /usr/share (o \$HOME não conta aqui):"
  checa_asset /usr/share/themes/Kali-Light             "tema GTK Kali-Light"
  checa_asset /usr/share/icons/Flat-Remix-Blue-Light   "ícones Flat-Remix-Blue-Light"
  checa_asset /usr/share/desktop-base/kali-theme/login/background "fundo da tela de login"
  if [ "${#FALTANDO[@]}" -gt 0 ]; then
    echo
    erro "${#FALTANDO[@]} asset(s) faltando — o greeter cairia no tema padrão ou não subiria."
    info "Instale os assets no sistema primeiro:  $PROJ/scripts/kali-look.sh assets --sistema"
    return 1
  fi
  return 0
}

# ------------------------------------------------------------------ status ----
cmd_status() {
  printf '%s== Tela de login (LightDM) ==%s\n' "$C_BOLD" "$C_RESET"
  printf '  gerenciador ativo .: %s\n' "$(cat /etc/X11/default-display-manager 2>/dev/null || echo '?')"
  printf '  lightdm instalado .: %s\n' \
    "$(command -v lightdm >/dev/null 2>&1 && echo sim || echo não)"
  printf '  greeter tematizado : %s\n' \
    "$(grep -q '^theme-name *= *Kali' "$CONF" 2>/dev/null && echo 'Kali' || echo 'padrão')"
  if [ -r "$CONF" ]; then
    printf '  valores em uso ....:\n'
    grep -E '^[a-z].*=' "$CONF" 2>/dev/null | sed 's/^/    /' || printf '    (nenhum; tudo comentado)\n'
  fi
  local n
  # `|| true`: sem /etc/lightdm o find sai 1, o pipefail propaga e o set -e mataria
  # o status em silêncio — exatamente em quem ainda usa GDM e veio aqui diagnosticar.
  n="$(find /etc/lightdm -maxdepth 1 -name 'lightdm-gtk-greeter.conf.bak-*' 2>/dev/null | wc -l || true)"
  printf '  backups do greeter : %s\n' "$n"
  echo
  valida_assets_do_sistema || true
}

# ----------------------------------------------------------------- aplicar ----
cmd_aplicar() {
  printf '%s== Aparência do Kali na tela de login (LightDM) ==%s\n' "$C_BOLD" "$C_RESET"
  [ -r "$ORIGEM" ] || morre "não encontrei a config de referência em $ORIGEM"

  if ! command -v lightdm >/dev/null 2>&1; then
    erro "o LightDM não está instalado — não há greeter para tematizar."
    info "O Ubuntu usa GDM; o Kali usa LightDM. Ver docs/guias/08-boot-login-e-logos.md §8.4."
    return 1
  fi

  local dm
  dm="$(cat /etc/X11/default-display-manager 2>/dev/null || true)"
  if [ "$dm" != "/usr/sbin/lightdm" ]; then
    aviso "o gerenciador de login ativo é '${dm:-desconhecido}', não o LightDM."
    aviso "a config será escrita, mas só terá efeito quando o LightDM for o ativo."
  fi

  valida_assets_do_sistema || return 1
  echo
  aviso "Isto reescreve $CONF — a tela de entrada da máquina."
  aviso "Se algo der errado, abra um console com Ctrl+Alt+F3, faça login em texto e rode:"
  aviso "  $PROJ/scripts/kali-look.sh greeter reverter"
  confirmar "entendi o risco e quero tematizar a tela de login" || return 1
  confirmar "confirme de novo: reescrever $CONF?" || return 1

  exige_sudo_utilizavel || return 1

  if [ -e "$CONF" ]; then
    run_sudo cp -a "$CONF" "$CONF.bak-$(date +%Y%m%d-%H%M%S)"
    ok "config atual guardada em $CONF.bak-<data>"
  else
    aviso "não havia $CONF — nada a preservar"
  fi

  run_sudo install -m 644 -o root -g root "$ORIGEM" "$CONF"

  # `keyboard = onboard` vem da config original do Kali, mas o onboard não é
  # instalado por este runbook: apontar para binário ausente só deixa o botão de
  # acessibilidade morto na tela de login.
  if ! command -v onboard >/dev/null 2>&1; then
    run_sudo sed -i \
      's|^keyboard = onboard|#keyboard = onboard   # onboard não instalado neste sistema|' \
      "$CONF"
    aviso "'keyboard = onboard' comentado: o pacote onboard não está instalado"
    info "  para ter o teclado virtual: sudo apt install onboard, e descomente a linha"
  fi

  ok "greeter do Kali aplicado"
  echo
  info "Confira ANTES de reiniciar, ainda com esta sessão aberta:"
  info "  $PROJ/scripts/kali-look.sh greeter status"
  info "O efeito aparece no próximo logout. O logo configurado para o GDM"
  info "(/etc/dconf/db/gdm.d/95-kali-logo) fica inerte enquanto o LightDM for o ativo."
}

# ---------------------------------------------------------------- reverter ----
cmd_reverter() {
  printf '%s== Reverter a tela de login ao greeter padrão ==%s\n' "$C_BOLD" "$C_RESET"
  local ultimo
  # `|| true`: com set -e, um find sem resultado dentro de $() aborta o script.
  ultimo="$(find /etc/lightdm -maxdepth 1 -name 'lightdm-gtk-greeter.conf.bak-*' 2>/dev/null \
            | sort | tail -1 || true)"

  if [ -n "$ultimo" ]; then
    info "backup mais recente: $ultimo"
    confirmar "restaurar esse backup sobre $CONF?" || return 1
    exige_sudo_utilizavel || return 1
    run_sudo cp -a "$ultimo" "$CONF"
    ok "config anterior restaurada"
  else
    aviso "nenhum backup encontrado em /etc/lightdm."
    info "A alternativa é gravar uma config mínima, que faz o greeter usar o tema padrão."
    confirmar "gravar '[greeter]' vazio em $CONF?" || return 1
    exige_sudo_utilizavel || return 1
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '%s[dry-run]%s escreveria "[greeter]" em %s\n' "$C_DIM" "$C_RESET" "$CONF"
    else
      printf '[greeter]\n' | sudo tee "$CONF" >/dev/null
    fi
    ok "config mínima gravada"
  fi
  info "O efeito aparece no próximo logout."
}

case "${1:-}" in
  aplicar)  cmd_aplicar ;;
  reverter) cmd_reverter ;;
  status)   cmd_status ;;
  *) morre "uso: $(basename "$0") aplicar | reverter | status" ;;
esac
