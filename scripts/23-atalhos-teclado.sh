#!/usr/bin/env bash
# 23-atalhos-teclado.sh — leva os atalhos de teclado que você já usava para o
# gerenciador de janelas do ambiente novo.
#
# Uso:
#   bash 23-atalhos-teclado.sh exportar [ARQUIVO]     # salva o que existe hoje
#   bash 23-atalhos-teclado.sh migrar [opções]        # GNOME/mutter -> xfwm4
#   bash 23-atalhos-teclado.sh status                 # o que migraria, o que colide
#   bash 23-atalhos-teclado.sh mapa                   # a tabela de tradução
#   bash 23-atalhos-teclado.sh reverter [ARQUIVO.xml] # volta o backup do canal
#
# Opções do migrar:
#   --de dconf|ARQUIVO   origem dos atalhos (padrão: dconf do usuário)
#   --modo mesclar       (padrão) grava o atalho do GNOME e mantém o do Kali
#                        quando não há colisão de tecla
#   --modo exclusivo     cada ação traduzida fica SÓ com a tecla do GNOME
#   --somente-janelas    migra apenas ações do gerenciador de janelas
#   --somente-comandos   migra apenas atalhos que abrem programa
#
# Por que isto é um script e não um parágrafo de guia:
#
# 1. Trocar de ambiente NÃO leva atalho nenhum: o GNOME guarda no dconf
#    (org.gnome.desktop.wm.keybindings, mutter, shell, media-keys) e o Xfce no
#    canal xfconf `xfce4-keyboard-shortcuts`. São bancos diferentes, com nomes de
#    ação diferentes — `close` de um lado, `close_window_key` do outro.
# 2. Boa parte dos atalhos que a pessoa "configurou" no GNOME são os PADRÕES do
#    GNOME, que não aparecem em `dconf dump` (o dump só traz o que desviou do
#    padrão). Por isso a leitura é feita com `gsettings`, que devolve o valor
#    efetivo — padrão incluído.
# 3. O dconf é do usuário, não da sessão: dentro do Xfce ainda se lê o que o
#    GNOME usava. A migração funciona depois da troca, sem precisar voltar.
#
# Origem dos nomes de ação do xfwm4 e dos comandos do Xfce usados aqui:
# docs/referencia/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml (do Kali) e
# as strings do próprio binário xfwm4 instalado.
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
CANAL="xfce4-keyboard-shortcuts"
XML="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/$CANAL.xml"
STATE_DIR="$HOME/.local/state/kali-look-backup/atalhos"

if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_VERDE=$'\033[38;5;42m'; C_AMBAR=$'\033[38;5;214m'; C_VERM=$'\033[38;5;160m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_VERDE=""; C_AMBAR=""; C_VERM=""
fi
ok()    {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    printf '%s✓ [dry-run, não executado]%s %s\n' "$C_DIM" "$C_RESET" "$*"
  else
    printf '%s✓%s %s\n' "$C_VERDE" "$C_RESET" "$*"
  fi
}
aviso() { printf '%s!%s %s\n' "$C_AMBAR" "$C_RESET" "$*"; }
info()  { printf '%s\n' "$*"; }
morre() { printf '%s✗%s %s\n' "$C_VERM" "$C_RESET" "$*" >&2; exit 1; }
etapa() { printf '\n%s== %s ==%s\n' "$C_BOLD" "$*" "$C_RESET"; }
run()   {
  if [ "$DRY_RUN" -eq 1 ]; then printf '%s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"; return 0; fi
  "$@"
}

# ------------------------------------------------------------- tradução -------
# GNOME -> xfwm4. Formato: schema|chave|ação do xfwm4
# Só entram ações que existem nos dois lados. As que não têm par estão listadas
# em SEM_PAR, e o script diz o que não migrou em vez de fingir que migrou.
mapa_janela() {
  cat <<'MAPA'
org.gnome.desktop.wm.keybindings|close|close_window_key
org.gnome.desktop.wm.keybindings|begin-move|move_window_key
org.gnome.desktop.wm.keybindings|begin-resize|resize_window_key
org.gnome.desktop.wm.keybindings|activate-window-menu|popup_menu_key
org.gnome.desktop.wm.keybindings|toggle-maximized|maximize_window_key
org.gnome.desktop.wm.keybindings|maximize|maximize_window_key
org.gnome.desktop.wm.keybindings|minimize|hide_window_key
org.gnome.desktop.wm.keybindings|toggle-fullscreen|fullscreen_key
org.gnome.desktop.wm.keybindings|toggle-above|above_key
org.gnome.desktop.wm.keybindings|toggle-on-all-workspaces|stick_window_key
org.gnome.desktop.wm.keybindings|raise|raise_window_key
org.gnome.desktop.wm.keybindings|lower|lower_window_key
org.gnome.desktop.wm.keybindings|switch-applications|cycle_windows_key
org.gnome.desktop.wm.keybindings|switch-applications-backward|cycle_reverse_windows_key
org.gnome.desktop.wm.keybindings|cycle-windows|cycle_windows_key
org.gnome.desktop.wm.keybindings|cycle-windows-backward|cycle_reverse_windows_key
org.gnome.desktop.wm.keybindings|switch-windows|switch_window_key
org.gnome.desktop.wm.keybindings|show-desktop|show_desktop_key
org.gnome.desktop.wm.keybindings|switch-to-workspace-left|left_workspace_key
org.gnome.desktop.wm.keybindings|switch-to-workspace-right|right_workspace_key
org.gnome.desktop.wm.keybindings|switch-to-workspace-up|up_workspace_key
org.gnome.desktop.wm.keybindings|switch-to-workspace-down|down_workspace_key
org.gnome.desktop.wm.keybindings|move-to-workspace-left|move_window_left_workspace_key
org.gnome.desktop.wm.keybindings|move-to-workspace-right|move_window_right_workspace_key
org.gnome.desktop.wm.keybindings|move-to-workspace-up|move_window_up_workspace_key
org.gnome.desktop.wm.keybindings|move-to-workspace-down|move_window_down_workspace_key
org.gnome.desktop.wm.keybindings|move-to-monitor-left|move_window_to_monitor_left_key
org.gnome.desktop.wm.keybindings|move-to-monitor-right|move_window_to_monitor_right_key
org.gnome.desktop.wm.keybindings|move-to-monitor-up|move_window_to_monitor_up_key
org.gnome.desktop.wm.keybindings|move-to-monitor-down|move_window_to_monitor_down_key
MAPA
  local n
  for n in 1 2 3 4 5 6 7 8 9 10 11 12; do
    printf 'org.gnome.desktop.wm.keybindings|switch-to-workspace-%s|workspace_%s_key\n' "$n" "$n"
    printf 'org.gnome.desktop.wm.keybindings|move-to-workspace-%s|move_window_workspace_%s_key\n' "$n" "$n"
  done
}

# GNOME -> comando do Xfce. Formato: schema|chave|comando
# Todo comando desta lista sai do xfce4-keyboard-shortcuts.xml do Kali, exceto
# xfce4-settings-manager (control-center), que é o equivalente óbvio e é
# checado com `command -v` antes de ser gravado.
mapa_comando() {
  cat <<'MAPA'
org.gnome.settings-daemon.plugins.media-keys|terminal|exo-open --launch TerminalEmulator
org.gnome.settings-daemon.plugins.media-keys|home|thunar
org.gnome.settings-daemon.plugins.media-keys|www|exo-open --launch WebBrowser
org.gnome.settings-daemon.plugins.media-keys|email|exo-open --launch MailReader
org.gnome.settings-daemon.plugins.media-keys|screensaver|xflock4
org.gnome.settings-daemon.plugins.media-keys|logout|xfce4-session-logout
org.gnome.settings-daemon.plugins.media-keys|search|xfce4-appfinder
org.gnome.settings-daemon.plugins.media-keys|control-center|xfce4-settings-manager
org.gnome.settings-daemon.plugins.media-keys|screenreader|orca
org.gnome.shell.keybindings|show-screenshot-ui|xfce4-screenshooter
org.gnome.shell.keybindings|screenshot|xfce4-screenshooter -f
org.gnome.shell.keybindings|screenshot-window|xfce4-screenshooter -w
org.gnome.mutter.keybindings|switch-monitor|xfce4-display-settings --minimal
org.gnome.desktop.wm.keybindings|panel-main-menu|xfce4-popup-whiskermenu
org.gnome.desktop.wm.keybindings|panel-run-dialog|xfce4-appfinder --collapsed
MAPA
}

# O que o GNOME tem e o xfwm4 não — some na migração, e é melhor dizer.
sem_par() {
  cat <<'MAPA'
unmaximize|o xfwm4 usa a MESMA tecla para maximizar e restaurar (maximize_window_key)
switch-to-workspace-last|o xfwm4 não tem "ir para a última área de trabalho"
move-to-workspace-last|o xfwm4 não tem "mover para a última área de trabalho"
switch-group|troca de janela do mesmo aplicativo não existe no xfwm4
switch-input-source|é o xfce4-settings/xkb quem cuida do layout, não o WM
toggle-overview|não existe visão geral de atividades no Xfce
shift-overview-up|não existe visão geral de atividades no Xfce
shift-overview-down|não existe visão geral de atividades no Xfce
magnifier|a lupa do GNOME não tem equivalente instalado por padrão
MAPA
}

# -------------------------------------------------------------- utilidades ----
# Um acelerador por linha, já com o valor efetivo (padrão do GNOME incluído).
acels_de() {
  local v item
  v="$(gsettings get "$1" "$2" 2>/dev/null || true)"
  [ -n "$v" ] || return 0
  case "$v" in "@as []"|"[]"|"''") return 0 ;; esac
  v="${v#@as }"; v="${v#[}"; v="${v%]}"
  local IFS=,
  for item in $v; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    item="${item#\'}"; item="${item%\'}"
    [ -n "$item" ] && printf '%s\n' "$item"
  done
  return 0
}

# GTK aceita <Control>, <Ctrl> e <Primary> como a mesma coisa; o xfconf do Xfce
# grava <Primary>. A ordem dos modificadores é irrelevante para o xfwm4, mas
# não para comparar strings — então normalizamos numa ordem só.
normaliza_acel() {
  local a="$1" mods="" tecla resto
  a="${a//<Control>/<Primary>}"
  a="${a//<Ctrl>/<Primary>}"
  a="${a//<Control_L>/<Primary>}"
  a="${a//<Meta>/<Alt>}"
  case "$a" in
    *'>'*) tecla="${a##*>}"; resto="${a%>*}>" ;;
    *)     tecla="$a";       resto="" ;;
  esac
  case "$resto" in *'<Primary>'*) mods="$mods<Primary>" ;; esac
  case "$resto" in *'<Shift>'*)   mods="$mods<Shift>"   ;; esac
  case "$resto" in *'<Alt>'*)     mods="$mods<Alt>"     ;; esac
  case "$resto" in *'<Super>'*)   mods="$mods<Super>"   ;; esac
  printf '%s%s' "$mods" "$tecla"
}

# Aceleradores que o xfwm4 não sabe interpretar. Above_Tab é invenção do mutter
# (a tecla acima do Tab, que varia com o layout) e não existe no GTK.
acel_suportado() {
  case "$1" in
    *Above_Tab*|"") return 1 ;;
    XF86*)          return 1 ;;   # tecla de hardware: quem trata é o xfce4-settings
  esac
  return 0
}

precisa_xfconf() {
  command -v xfconf-query >/dev/null 2>&1 \
    || morre "xfconf-query não encontrado — este comando é para o Xfce (sudo apt install xfconf)"
}

# "/xfwm4/custom/<Alt>F4  close_window_key" para cada atalho já gravado.
xfconf_pares() {
  local sub="$1" prop valor
  xfconf-query -c "$CANAL" -l -v 2>/dev/null | while read -r prop valor; do
    case "$prop" in
      "/$sub/custom/"*)
        case "$prop" in */override) continue ;; esac
        case "$prop" in */startup-notify) continue ;; esac
        printf '%s|%s\n' "${prop#"/$sub/custom/"}" "$valor"
        ;;
    esac
  done
  return 0
}

acao_em() { # sub acel -> ação/comando gravado, ou vazio
  xfconf-query -c "$CANAL" -p "/$1/custom/$2" 2>/dev/null || true
}

# A MESMA tecla pode já estar gravada com os modificadores em outra ordem — o
# Kali grava `<Alt><Shift>Tab`, o GNOME devolve `<Shift><Alt>Tab`. Comparar a
# string crua criaria duas propriedades para uma tecla só, e aí qual das duas
# vale é indefinido. Esta função acha a propriedade equivalente e devolve
# "propriedade real|valor".
equivalente_em() {
  local sub="$1" acel="$2" p v
  while IFS='|' read -r p v; do
    [ -n "${p:-}" ] || continue
    if [ "$(normaliza_acel "$p")" = "$acel" ]; then
      printf '%s|%s\n' "$p" "$v"; return 0
    fi
  done < <(xfconf_pares "$sub")
  return 0
}

backup_canal() {
  mkdir -p "$STATE_DIR"
  if [ -f "$XML" ]; then
    local dest; dest="$STATE_DIR/$CANAL-$(date +%Y%m%d-%H%M%S).xml"
    run cp -a "$XML" "$dest"
    ok "backup do canal em $dest"
  else
    aviso "não havia $XML — o canal ainda está nos padrões do sistema"
  fi
}

# ---------------------------------------------------------------- exportar ----
cmd_exportar() {
  local dest="${1:-}"
  mkdir -p "$STATE_DIR"
  [ -n "$dest" ] || dest="$STATE_DIR/perfil-$(date +%Y%m%d-%H%M%S).atalhos"
  etapa "Exportando os atalhos que existem hoje"

  local tmp; tmp="$(mktemp)"
  {
    printf '#kali-look-atalhos v1\n'
    printf '#data=%s sessao=%s\n' "$(date -Is)" "${XDG_CURRENT_DESKTOP:-?}"
    printf '#escopo\tchave\tacelerador\tcomando\n'
  } > "$tmp"

  local n_j=0 n_c=0 schema chave acao acel
  if command -v gsettings >/dev/null 2>&1; then
    while IFS='|' read -r schema chave acao; do
      [ -n "${schema:-}" ] || continue
      while read -r acel; do
        [ -n "$acel" ] || continue
        printf 'janela\t%s\t%s\t\n' "$chave" "$acel" >> "$tmp"
        n_j=$((n_j + 1))
      done < <(acels_de "$schema" "$chave")
    done < <(mapa_janela)

    while IFS='|' read -r schema chave acao; do
      [ -n "${schema:-}" ] || continue
      while read -r acel; do
        [ -n "$acel" ] || continue
        printf 'comando\t%s\t%s\t%s\n' "$chave" "$acel" "$acao" >> "$tmp"
        n_c=$((n_c + 1))
      done < <(acels_de "$schema" "$chave")
    done < <(mapa_comando)

    # atalhos personalizados do GNOME (Configurações -> Teclado -> Personalizados)
    local base="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
    local caminhos p nome cmd
    caminhos="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || true)"
    case "$caminhos" in
      "@as []"|"[]"|"") ;;
      *)
        caminhos="${caminhos#[}"; caminhos="${caminhos%]}"
        local IFS_ANTIGO="$IFS"; IFS=,
        for p in $caminhos; do
          p="${p#"${p%%[![:space:]]*}"}"; p="${p#\'}"; p="${p%\'}"
          [ -n "$p" ] || continue
          nome="$(gsettings get "$base:$p" name 2>/dev/null || echo "''")"
          cmd="$(gsettings get "$base:$p" command 2>/dev/null || echo "''")"
          acel="$(gsettings get "$base:$p" binding 2>/dev/null || echo "''")"
          nome="${nome#\'}"; nome="${nome%\'}"
          cmd="${cmd#\'}";  cmd="${cmd%\'}"
          acel="${acel#\'}"; acel="${acel%\'}"
          [ -n "$acel" ] && [ -n "$cmd" ] || continue
          printf 'custom\t%s\t%s\t%s\n' "${nome:-sem-nome}" "$acel" "$cmd" >> "$tmp"
          n_c=$((n_c + 1))
        done
        IFS="$IFS_ANTIGO"
        ;;
    esac
  else
    aviso "gsettings não encontrado: nada do GNOME foi exportado"
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s[dry-run]%s escreveria %s\n' "$C_DIM" "$C_RESET" "$dest"
    rm -f "$tmp"
  else
    mv "$tmp" "$dest"
    ok "$n_j atalho(s) de janela e $n_c de programa em $dest"
  fi

  if [ -f "$XML" ]; then
    local xdest; xdest="$STATE_DIR/$CANAL-$(date +%Y%m%d-%H%M%S).xml"
    run cp -a "$XML" "$xdest"
    ok "conjunto atual do Xfce copiado para $xdest"
  fi
  info "Este arquivo é a entrada de:  bash 23-atalhos-teclado.sh migrar --de $dest"
}

# Lê um perfil exportado e emite as mesmas linhas TSV (sem cabeçalho).
le_perfil() {
  local arq="$1"
  [ -f "$arq" ] || morre "perfil não encontrado: $arq"
  grep -v '^#' "$arq" || true
}

# Lê o dconf ao vivo e emite as linhas TSV, sem passar por arquivo.
le_dconf() {
  local schema chave acao acel
  while IFS='|' read -r schema chave acao; do
    [ -n "${schema:-}" ] || continue
    while read -r acel; do
      [ -n "$acel" ] && printf 'janela\t%s\t%s\t\n' "$chave" "$acel"
    done < <(acels_de "$schema" "$chave")
  done < <(mapa_janela)
  while IFS='|' read -r schema chave acao; do
    [ -n "${schema:-}" ] || continue
    while read -r acel; do
      [ -n "$acel" ] && printf 'comando\t%s\t%s\t%s\n' "$chave" "$acel" "$acao"
    done < <(acels_de "$schema" "$chave")
  done < <(mapa_comando)
  local base="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
  local caminhos p nome cmd
  caminhos="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || true)"
  case "$caminhos" in
    "@as []"|"[]"|"") return 0 ;;
  esac
  caminhos="${caminhos#[}"; caminhos="${caminhos%]}"
  local IFS=,
  for p in $caminhos; do
    p="${p#"${p%%[![:space:]]*}"}"; p="${p#\'}"; p="${p%\'}"
    [ -n "$p" ] || continue
    nome="$(gsettings get "$base:$p" name 2>/dev/null || true)"
    cmd="$(gsettings get "$base:$p" command 2>/dev/null || true)"
    acel="$(gsettings get "$base:$p" binding 2>/dev/null || true)"
    nome="${nome#\'}"; nome="${nome%\'}"
    cmd="${cmd#\'}";  cmd="${cmd%\'}"
    acel="${acel#\'}"; acel="${acel%\'}"
    [ -n "$acel" ] && [ -n "$cmd" ] && printf 'custom\t%s\t%s\t%s\n' "${nome:-sem-nome}" "$acel" "$cmd"
  done
  return 0
}

acao_de_chave() { # chave GNOME -> ação xfwm4 (vazio se não houver par)
  local chave="$1" k a
  while IFS='|' read -r _ k a; do
    [ "$k" = "$chave" ] && { printf '%s' "$a"; return 0; }
  done < <(mapa_janela)
  return 0
}

# ------------------------------------------------------------------ migrar ----
cmd_migrar() {
  local origem="dconf" modo="mesclar" so_janelas=0 so_comandos=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --de) origem="${2:-}"; shift 2 ;;
      --modo) modo="${2:-}"; shift 2 ;;
      --somente-janelas) so_janelas=1; shift ;;
      --somente-comandos) so_comandos=1; shift ;;
      *) morre "opção desconhecida: $1" ;;
    esac
  done
  case "$modo" in mesclar|exclusivo) ;; *) morre "--modo aceita mesclar ou exclusivo" ;; esac
  precisa_xfconf

  etapa "Migrando atalhos do GNOME para o xfwm4 (modo $modo)"
  case "${XDG_CURRENT_DESKTOP:-}" in
    *[Xx][Ff][Cc][Ee]*) ;;
    *) aviso "você não está numa sessão Xfce: a gravação vale, mas só terá efeito"
       aviso "quando você entrar no Xfce (o xfconf é do usuário, não da sessão)." ;;
  esac

  backup_canal

  # o canal só respeita os atalhos de "custom" quando override está ligado
  run xfconf-query -c "$CANAL" -p /xfwm4/custom/override -n -t bool -s true
  run xfconf-query -c "$CANAL" -p /commands/custom/override -n -t bool -s true

  local linhas; linhas="$(mktemp)"
  if [ "$origem" = "dconf" ]; then
    le_dconf > "$linhas"
  else
    le_perfil "$origem" > "$linhas"
  fi

  local escopo chave acel cmd acao alvo atual n_ok=0 n_pulado=0 n_conflito=0
  while IFS=$'\t' read -r escopo chave acel cmd; do
    [ -n "${escopo:-}" ] || continue
    if ! acel_suportado "$acel"; then
      n_pulado=$((n_pulado + 1)); continue
    fi
    acel="$(normaliza_acel "$acel")"

    case "$escopo" in
      janela)
        [ "$so_comandos" -eq 1 ] && continue
        acao="$(acao_de_chave "$chave")"
        if [ -z "$acao" ]; then n_pulado=$((n_pulado + 1)); continue; fi
        alvo="xfwm4"
        ;;
      comando|custom)
        [ "$so_janelas" -eq 1 ] && continue
        acao="$cmd"
        [ -n "$acao" ] || { n_pulado=$((n_pulado + 1)); continue; }
        # não grava atalho para programa que não está instalado
        local bin="${acao%% *}"
        if ! command -v "$bin" >/dev/null 2>&1; then
          aviso "$acel → $acao: '$bin' não está instalado, não gravei"
          n_pulado=$((n_pulado + 1)); continue
        fi
        alvo="commands"
        ;;
      *) continue ;;
    esac

    # a tecla já faz outra coisa no OUTRO grupo do canal (ação do WM x programa)
    local oposto par p_real p_val
    [ "$alvo" = "xfwm4" ] && oposto="commands" || oposto="xfwm4"
    par="$(equivalente_em "$oposto" "$acel")"
    if [ -n "$par" ]; then
      p_real="${par%%|*}"; p_val="${par#*|}"
      aviso "$acel era \"$p_val\" ($oposto); passa a ser \"$acao\""
      run xfconf-query -c "$CANAL" -p "/$oposto/custom/$p_real" -r
      n_conflito=$((n_conflito + 1))
    fi

    # a mesma tecla no mesmo grupo: pode já estar certa, ou estar em outra ordem
    par="$(equivalente_em "$alvo" "$acel")"
    if [ -n "$par" ]; then
      p_real="${par%%|*}"; p_val="${par#*|}"
      if [ "$p_val" = "$acao" ]; then
        n_ok=$((n_ok + 1))
        continue                     # nada a fazer: já é isso
      fi
      aviso "$acel era \"$p_val\"; virou \"$acao\""
      [ "$p_real" != "$acel" ] && run xfconf-query -c "$CANAL" -p "/$alvo/custom/$p_real" -r
      n_conflito=$((n_conflito + 1))
    fi

    # modo exclusivo: a ação passa a existir só na tecla do GNOME
    if [ "$modo" = "exclusivo" ]; then
      local p_acel p_valor
      while IFS='|' read -r p_acel p_valor; do
        [ -n "${p_acel:-}" ] || continue
        if [ "$p_valor" = "$acao" ] && [ "$p_acel" != "$acel" ]; then
          info "  removo $p_acel (a mesma ação $acao)"
          run xfconf-query -c "$CANAL" -p "/$alvo/custom/$p_acel" -r
        fi
      done < <(xfconf_pares "$alvo")
    fi

    run xfconf-query -c "$CANAL" -p "/$alvo/custom/$acel" -n -t string -s "$acao"
    case "$acao" in
      xfce4-appfinder*) run xfconf-query -c "$CANAL" \
        -p "/$alvo/custom/$acel/startup-notify" -n -t bool -s true ;;
    esac
    n_ok=$((n_ok + 1))
  done < "$linhas"
  rm -f "$linhas"

  echo
  ok "$n_ok atalho(s) gravado(s); $n_conflito substituição(ões); $n_pulado sem par ou sem programa"
  etapa "O que o GNOME tem e o xfwm4 não"
  local k motivo
  while IFS='|' read -r k motivo; do
    [ -n "${k:-}" ] && printf '  %-28s %s\n' "$k" "$motivo"
  done < <(sem_par)
  echo
  info "O xfwm4 aplica na hora. Se algo não responder:  xfwm4 --replace &"
  info "Para voltar ao conjunto do Kali:  bash 23-atalhos-teclado.sh reverter"
}

# ------------------------------------------------------------------ status ----
cmd_status() {
  etapa "Atalhos: origem, destino e diferença"
  info "sessão atual: ${XDG_CURRENT_DESKTOP:-?}"
  if ! command -v xfconf-query >/dev/null 2>&1; then
    aviso "xfconf-query ausente: sem Xfce instalado, não há destino para migrar"
  fi
  local total=0 comdestino=0 iguais=0 diferentes=0 ausentes=0
  local escopo chave acel cmd acao alvo atual
  while IFS=$'\t' read -r escopo chave acel cmd; do
    [ -n "${escopo:-}" ] || continue
    total=$((total + 1))
    acel_suportado "$acel" || continue
    acel="$(normaliza_acel "$acel")"
    case "$escopo" in
      janela) acao="$(acao_de_chave "$chave")"; alvo="xfwm4" ;;
      *)      acao="$cmd"; alvo="commands" ;;
    esac
    [ -n "$acao" ] || continue
    comdestino=$((comdestino + 1))
    atual=""
    if command -v xfconf-query >/dev/null 2>&1; then
      local par; par="$(equivalente_em "$alvo" "$acel")"
      [ -n "$par" ] && atual="${par#*|}"
    fi
    if [ "$atual" = "$acao" ]; then
      iguais=$((iguais + 1))
    elif [ -n "$atual" ]; then
      diferentes=$((diferentes + 1))
      printf '  %-26s %s  %s(hoje: %s)%s\n' "$acel" "$acao" "$C_DIM" "$atual" "$C_RESET"
    else
      ausentes=$((ausentes + 1))
      printf '  %-26s %s  %s(não existe no Xfce)%s\n' "$acel" "$acao" "$C_DIM" "$C_RESET"
    fi
  done < <(le_dconf)
  echo
  info "$total atalho(s) lidos do dconf · $comdestino com equivalente no Xfce"
  ok "$iguais já iguais · $diferentes com outro valor hoje · $ausentes faltando"
  [ "$diferentes" -gt 0 ] || [ "$ausentes" -gt 0 ] \
    && info "Para aplicar:  bash 23-atalhos-teclado.sh migrar" || true
  return 0
}

# ---------------------------------------------------------------- reverter ----
cmd_reverter() {
  local arq="${1:-}"
  mkdir -p "$STATE_DIR"
  if [ -z "$arq" ]; then
    arq="$(ls -1t "$STATE_DIR/$CANAL-"*.xml 2>/dev/null | head -1 || true)"
  fi
  [ -n "$arq" ] || morre "nenhum backup do canal em $STATE_DIR"
  [ -f "$arq" ] || morre "backup não encontrado: $arq"
  etapa "Revertendo o canal $CANAL"
  info "de:  $arq"
  info "para: $XML"
  aviso "o xfconfd guarda o canal em memória: para o arquivo valer, ele precisa"
  aviso "ser reiniciado (o D-Bus o relança sozinho na próxima consulta)."
  run mkdir -p "$(dirname "$XML")"
  run cp -a "$arq" "$XML"
  run pkill -x xfconfd || true
  ok "canal restaurado — se algum atalho ainda parecer velho, saia e entre na sessão"
}

# -------------------------------------------------------------------- mapa ----
cmd_mapa() {
  etapa "Ações do gerenciador de janelas: GNOME → xfwm4"
  local k a
  while IFS='|' read -r _ k a; do
    [ -n "${k:-}" ] && printf '  %-30s %s\n' "$k" "$a"
  done < <(mapa_janela)
  etapa "Atalhos que abrem programa: GNOME → comando do Xfce"
  while IFS='|' read -r _ k a; do
    [ -n "${k:-}" ] && printf '  %-30s %s\n' "$k" "$a"
  done < <(mapa_comando)
  etapa "Sem equivalente"
  while IFS='|' read -r k a; do
    [ -n "${k:-}" ] && printf '  %-30s %s\n' "$k" "$a"
  done < <(sem_par)
}

case "${1:-}" in
  exportar) shift; cmd_exportar "$@" ;;
  migrar)   shift; cmd_migrar "$@" ;;
  status)   shift; cmd_status ;;
  reverter) shift; cmd_reverter "$@" ;;
  mapa)     shift; cmd_mapa ;;
  *) sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
