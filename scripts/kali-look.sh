#!/usr/bin/env bash
# kali-look.sh — ponto de entrada único para instalar, aplicar, reverter e
# remover a aparência do Kali Linux em Ubuntu/Debian.
#
# Testado em Ubuntu 24.04 (GNOME 46, Xfce 4.18, Plasma 5.27). Em outra versão ou
# distribuição os passos valem, mas nomes e versões de pacote podem divergir —
# o `status` avisa quando o sistema não é o testado.
#
# Sem argumentos abre um menu interativo. Com argumentos, funciona como CLI.
# Documentação: ../README.md e os 13 guias em ../docs/guias/.
set -euo pipefail

VERSAO="1.0"
# Resolvidos a partir da localização do script: funciona em qualquer diretório.
BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(dirname -- "$BASE_DIR")"
REF_DIR="$PROJ/docs/referencia"
STATE_DIR="$HOME/.local/state/kali-look-backup"
LOG="$STATE_DIR/kali-look.log"

DRY_RUN=0
ASSUME_YES=0

# ---------------------------------------------------------------- aparência ---
if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_AZUL=$'\033[38;5;33m'; C_VERDE=$'\033[38;5;42m'
  C_AMBAR=$'\033[38;5;214m'; C_VERM=$'\033[38;5;160m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_AZUL=""; C_VERDE=""; C_AMBAR=""; C_VERM=""
fi

mkdir -p "$STATE_DIR"

log()  { printf '%s | %s\n' "$(date -Is)" "$*" >> "$LOG"; }
titulo(){ printf '\n%s== %s ==%s\n' "$C_BOLD$C_AZUL" "$*" "$C_RESET"; }
info() { printf '%s\n' "$*"; log "INFO $*"; }
ok()   {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    printf '%s✓ [dry-run, não executado]%s %s\n' "$C_DIM" "$C_RESET" "$*"
  else
    printf '%s✓%s %s\n' "$C_VERDE" "$C_RESET" "$*"
  fi
  log "OK $*"
}
aviso(){ printf '%s!%s %s\n' "$C_AMBAR" "$C_RESET" "$*"; log "AVISO $*"; }
erro() { printf '%s✗%s %s\n' "$C_VERM" "$C_RESET" "$*" >&2; log "ERRO $*"; }
morre(){ erro "$*"; exit 1; }

# Executa (ou apenas mostra, em --dry-run) e registra no log.
run() {
  log "RUN $*"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"
    if [ "${1:-}" = "bash" ]; then
      printf '%s          (o dry-run não entra nos scripts numerados; leia-os para ver os comandos)%s\n' \
        "$C_DIM" "$C_RESET"
    fi
    return 0
  fi
  "$@"
}

# Igual ao run, mas para comandos com sudo: sempre anuncia antes.
run_sudo() {
  printf '%ssudo:%s %s\n' "$C_AMBAR" "$C_RESET" "$*"
  run sudo "$@"
}

confirmar() {
  local pergunta="$1"
  if [ "$ASSUME_YES" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    log "CONFIRMA-AUTO $pergunta"
    return 0
  fi
  if [ ! -t 0 ]; then
    aviso "sem terminal interativo; assumindo NÃO para: $pergunta"
    return 1
  fi
  local r
  read -r -p "$(printf '%s?%s %s [s/N] ' "$C_AMBAR" "$C_RESET" "$pergunta")" r
  case "${r,,}" in s|sim|y|yes) log "CONFIRMA-SIM $pergunta"; return 0 ;; esac
  log "CONFIRMA-NAO $pergunta"
  return 1
}

tem() { command -v "$1" >/dev/null 2>&1; }

# `grep -q` fecha o pipe no primeiro casamento e o `fc-list` morre de SIGPIPE; com
# `pipefail` o pipeline devolve 141 e uma fonte instalada é relatada como ausente —
# de forma intermitente, porque depende de o fc-list ter terminado de escrever.
# Sem o -q o grep lê até o fim: nada de SIGPIPE, resultado estável.
fonte_presente() {
  fc-list : family 2>/dev/null | grep -i -- "$1" >/dev/null 2>&1
}

precisa() {
  tem "$1" || morre "comando '$1' não encontrado. $2"
}

# ------------------------------------------------------------------ contexto ---
sessao() {
  local d="${XDG_CURRENT_DESKTOP:-desconhecida}"
  printf '%s' "${d,,}"
}

exige_sessao() {
  local alvo="$1" atual
  atual="$(sessao)"
  case "$alvo" in
    xfce)   [[ "$atual" == *xfce*  ]] && return 0 ;;
    plasma) [[ "$atual" == *kde*   ]] && return 0 ;;
    gnome)  [[ "$atual" == *gnome* ]] && return 0 ;;
  esac
  erro "esta ação precisa rodar dentro da sessão $alvo (sessão atual: ${XDG_CURRENT_DESKTOP:-?})."
  info "Motivo: as configurações são gravadas no serviço de configuração do próprio"
  info "ambiente (xfconf / kconfig / dconf da sessão). Fora dele, o comando não tem"
  info "efeito ou grava em lugar errado."
  info "Saia da sessão, escolha \"$alvo\" na engrenagem do GDM e rode de novo."
  return 1
}

assets_usuario() { [ -d "$HOME/.themes/Kali-Dark" ]; }
assets_sistema() { [ -d /usr/share/themes/Kali-Dark ]; }

exige_assets() {
  if assets_usuario || assets_sistema; then return 0; fi
  if [ "$DRY_RUN" -eq 1 ]; then
    aviso "os arquivos de tema do Kali não estão instalados — seguindo só porque é --dry-run"
    return 0
  fi
  erro "os arquivos de tema do Kali não foram encontrados."
  info "Rode primeiro:  $0 assets --usuario   (ou --sistema)"
  return 1
}

wallpaper_kali() {
  local c
  for c in "$HOME/.local/share/backgrounds/kali/kali-cubes-16x9.jpg" \
           /usr/share/backgrounds/kali/kali-cubes-16x9.jpg \
           /usr/share/backgrounds/kali-16x9/default; do
    [ -e "$c" ] && { printf '%s' "$c"; return 0; }
  done
  return 1
}

# --------------------------------------------------------- listas de pacotes ---
# Validadas contra os repositórios do Ubuntu 24.04 (docs 04 e 05).
XFCE_PKGS=(
  xfce4 xfce4-goodies xfce4-terminal xfce4-notifyd xfce4-screensaver
  xfce4-whiskermenu-plugin xfce4-genmon-plugin xfce4-cpugraph-plugin
  xfce4-pulseaudio-plugin xfce4-power-manager-plugins xfce4-taskmanager
  xfce4-screenshooter xfce4-panel-profiles
  xfce4-clipman-plugin
  thunar thunar-archive-plugin thunar-volman ristretto parole mousepad
  network-manager-gnome blueman
  mate-polkit gvfs-backends gvfs-fuse
  xdg-user-dirs-gtk gtk2-engines-pixbuf dconf-cli
  fonts-cantarell fonts-firacode
)
# mate-polkit é o agente gráfico de autenticação: sem ele, no Xfce, nada que
# peça senha de administrador (gnome-disks, synaptic) consegue elevar privilégio.
# É a mesma escolha do kali-desktop-xfce.
PLASMA_PKGS=(
  kde-plasma-desktop plasma-desktop plasma-workspace kwin-x11
  plasma-nm plasma-pa powerdevil kscreen
  konsole dolphin kate gwenview ark kcalc okular
  plasma-systemmonitor kde-spectacle breeze breeze-gtk-theme
  systemsettings kde-config-gtk-style
  fonts-cantarell fonts-firacode
)
# Removidos de propósito das listas: sddm, lightdm, lightdm-gtk-greeter.
# Eles trocam o gerenciador de login de TODAS as sessões (inclusive GNOME).

apt_disponiveis() {
  local -n _entrada=$1; local -n _saida=$2
  local p cand
  _saida=()
  for p in "${_entrada[@]}"; do
    cand="$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{print $2}')"
    if [ -n "$cand" ] && [ "$cand" != "(none)" ]; then
      _saida+=("$p")
    else
      aviso "sem candidato nos repositórios, pulando: $p"
    fi
  done
}

# Avisa (sem abortar) quando o sistema não é a base em que este material foi
# testado. Nada aqui é específico do Ubuntu, mas nomes e versões de pacote e os
# valores de reversão variam por distribuição.
checa_base_testada() {
  local id="" ver="" like=""
  if [ -r /etc/os-release ]; then
    id="$(. /etc/os-release && echo "${ID:-}")"
    ver="$(. /etc/os-release && echo "${VERSION_ID:-}")"
    like="$(. /etc/os-release && echo "${ID_LIKE:-}")"
  fi
  if [ "$id" = "ubuntu" ] && [ "$ver" = "24.04" ]; then
    return 0
  fi
  if [ "$id" = "debian" ] || [ "$id" = "ubuntu" ] || case "$like" in *debian*) true ;; *) false ;; esac; then
    aviso "base testada: Ubuntu 24.04. Aqui é ${id:-?} ${ver:-?} — os passos valem,"
    aviso "mas versões de pacote (Xfce, Plasma, GNOME) e o tema de reversão diferem."
  else
    aviso "este material foi feito para Ubuntu/Debian; ${id:-sistema desconhecido} não foi testado."
    aviso "nomes de pacote e caminhos de /usr/share podem não existir aqui."
  fi
}

# ================================================================== STATUS ====
cmd_status() {
  titulo "Sistema"
  printf '  distro .......: %s\n' "$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-?}")"
  printf '  kernel .......: %s\n' "$(uname -r)"
  printf '  desktop ......: %s\n' "${XDG_CURRENT_DESKTOP:-?}"
  printf '  sessão .......: %s (%s)\n' "${DESKTOP_SESSION:-?}" "${XDG_SESSION_TYPE:-?}"
  printf '  login manager : %s\n' "$(cat /etc/X11/default-display-manager 2>/dev/null || echo '?')"
  printf '  disco em / ...: %s livres (%s em uso)\n' \
    "$(df -h / | awk 'NR==2{print $4}')" "$(df -h / | awk 'NR==2{print $5}')"
  printf '  projeto ......: %s\n' "$PROJ"
  checa_base_testada

  titulo "Aparência em uso"
  if tem gsettings; then
    printf '  %sGNOME%s\n' "$C_BOLD" "$C_RESET"
    local k
    for k in gtk-theme icon-theme cursor-theme font-name monospace-font-name color-scheme; do
      printf '    %-22s %s\n' "$k" "$(gsettings get org.gnome.desktop.interface "$k" 2>/dev/null || echo '?')"
    done
    printf '    %-22s %s\n' "shell (user-theme)" \
      "$(gsettings get org.gnome.shell.extensions.user-theme name 2>/dev/null || echo 'extensão ausente')"
    printf '    %-22s %s\n' "wallpaper" \
      "$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null || echo '?')"
  fi
  if tem xfconf-query && xfconf-query -c xsettings -l >/dev/null 2>&1; then
    printf '  %sXfce%s\n' "$C_BOLD" "$C_RESET"
    printf '    %-22s %s\n' "tema GTK"  "$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null || echo '-')"
    printf '    %-22s %s\n' "ícones"    "$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null || echo '-')"
    printf '    %-22s %s\n' "fonte"     "$(xfconf-query -c xsettings -p /Gtk/FontName 2>/dev/null || echo '-')"
    printf '    %-22s %s\n' "xfwm4"     "$(xfconf-query -c xfwm4 -p /general/theme 2>/dev/null || echo '-')"
    # A paleta do Kali vale só para o xfce4-terminal: se o preferido é outro, a
    # aparência do terminal não muda e parece que a paleta não pegou.
    printf '    %-22s %s\n' "terminal preferido" \
      "$(awk -F= '/^TerminalEmulator=/{print $2; exit}' "$HOME/.config/xfce4/helpers.rc" 2>/dev/null || echo 'não definido')"
    printf '    %-22s %s\n' "paleta no terminalrc" \
      "$(grep -q 'ColorPalette=#1F2229' "$HOME/.config/xfce4/terminal/terminalrc" 2>/dev/null && echo 'Kali' || echo 'padrão')"
  fi
  printf '  %sTerminal do sistema%s\n' "$C_BOLD" "$C_RESET"
  printf '    %-22s %s\n' "x-terminal-emulator" \
    "$(update-alternatives --query x-terminal-emulator 2>/dev/null | awk '/^Value:/{print $2; exit}' || echo '-')"
  if [ -f "$HOME/.config/kdeglobals" ]; then
    printf '  %sKDE Plasma%s\n' "$C_BOLD" "$C_RESET"
    printf '    %-22s %s\n' "esquema de cores" \
      "$(awk -F= '/^ColorScheme=/{print $2; exit}' "$HOME/.config/kdeglobals" 2>/dev/null || echo '-')"
    printf '    %-22s %s\n' "ícones" \
      "$(awk -F= '/^Theme=/{print $2; exit}' "$HOME/.config/kdeglobals" 2>/dev/null || echo '-')"
    printf '    %-22s %s\n' "decoração" \
      "$(awk -F= '/^library=/{print $2; exit}' "$HOME/.config/kwinrc" 2>/dev/null || echo '-')"
  fi

  titulo "Arquivos do Kali"
  if assets_usuario; then ok "instalados no \$HOME (~/.themes/Kali-Dark)"; else info "  não instalados no \$HOME"; fi
  if assets_sistema; then ok "instalados no sistema (/usr/share/themes/Kali-Dark)"; else info "  não instalados no sistema"; fi
  local w
  if w="$(wallpaper_kali)"; then ok "wallpaper disponível: $w"; else info "  wallpaper do Kali não encontrado"; fi
  [ -d "$HOME/.cache/kali-assets" ] && info "  cache de download: $HOME/.cache/kali-assets"
  printf '  fontes .......: Cantarell %s | Fira Code %s\n' \
    "$(fonte_presente cantarell   && echo presente || echo ausente)" \
    "$(fonte_presente 'fira code' && echo presente || echo ausente)"

  titulo "Sessões instaladas (tela de login)"
  ls /usr/share/xsessions/ 2>/dev/null | sed 's/^/  /' || info "  nenhuma"
  ls /usr/share/wayland-sessions/ 2>/dev/null | sed 's/^/  (wayland) /' || true

  if tem gnome-extensions; then
    titulo "Extensões GNOME relevantes"
    local ativas e
    ativas="$(gnome-extensions list --enabled 2>/dev/null || true)"
    for e in dash-to-dock@micxgx.gmail.com ubuntu-dock@ubuntu.com \
             user-theme@gnome-shell-extensions.gcampax.github.com \
             apps-menu@gnome-shell-extensions.gcampax.github.com \
             places-menu@gnome-shell-extensions.gcampax.github.com \
             drive-menu@gnome-shell-extensions.gcampax.github.com \
             system-monitor@gnome-shell-extensions.gcampax.github.com \
             ding@rastersoft.com; do
      if grep -qx "$e" <<< "$ativas"; then
        printf '  %s[on ]%s %s\n' "$C_VERDE" "$C_RESET" "${e%%@*}"
      elif gnome-extensions info "$e" >/dev/null 2>&1; then
        printf '  %s[off]%s %s\n' "$C_DIM" "$C_RESET" "${e%%@*}"
      else
        printf '  %s[ -- ]%s %s (não instalada)\n' "$C_DIM" "$C_RESET" "${e%%@*}"
      fi
    done
  fi

  titulo "Camada de boot/login"
  local dm_ativo
  dm_ativo="$(cat /etc/X11/default-display-manager 2>/dev/null || true)"
  # "aplicado" sozinho engana: o logo do GDM fica inerte se o LightDM é o ativo,
  # e foi essa leitura que fez parecer que a tela de login tinha sido tematizada.
  local gdm_logo="padrão"
  if [ -f /etc/dconf/db/gdm.d/95-kali-logo ]; then
    gdm_logo="aplicado"
    case "$dm_ativo" in
      */gdm3|*/gdm) : ;;
      "") gdm_logo="aplicado (gerenciador ativo desconhecido)" ;;
      *)  gdm_logo="aplicado, porém INERTE — o ativo é $(basename "$dm_ativo")" ;;
    esac
  fi
  printf '  logo do GDM ..: %s\n' "$gdm_logo"
  local greeter="não se aplica (LightDM não instalado)"
  if tem lightdm; then
    if grep -q '^theme-name *= *Kali' /etc/lightdm/lightdm-gtk-greeter.conf 2>/dev/null; then
      greeter="tema do Kali"
    else
      greeter="padrão — rode: $0 greeter aplicar"
    fi
  fi
  printf '  greeter LightDM: %s\n' "$greeter"
  printf '  tema do GRUB .: %s\n' \
    "$([ -f /etc/default/grub.d/kali-themes.cfg ] && echo 'aplicado' || echo 'padrão')"
  printf '  plymouth .....: %s\n' \
    "$(readlink -f /usr/share/plymouth/themes/default.plymouth 2>/dev/null | xargs -r basename || echo '?')"
  local pstat="não aplicado"
  if grep -q '>>> prompt kali >>>' "$HOME/.zshrc" 2>/dev/null; then
    pstat="aplicado"
    local quem=""
    quem="$(prompt_concorrente "$HOME/.zshrc" || true)"
    # "aplicado" sozinho engana quando outro prompt redesenha depois.
    [ -n "$quem" ] && pstat="aplicado, mas SOBRESCRITO por: $quem"
  fi
  printf '  prompt no zsh : %s\n' "$pstat"

  titulo "Backups"
  if [ -d "$STATE_DIR" ]; then
    find "$STATE_DIR" -maxdepth 1 -mindepth 1 -type d -printf '  %f\n' 2>/dev/null | sort | tail -5
    [ -f "$LOG" ] && info "  log: $LOG"
  else
    info "  nenhum backup ainda — rode: $0 backup"
  fi
  echo
}

# ================================================================== BACKUP ====
cmd_backup() {
  precisa dconf "Instale com: sudo apt install dconf-cli"
  titulo "Backup do estado atual"
  run bash "$BASE_DIR/00-backup.sh"
}

# ================================================================== ASSETS ====
cmd_assets() {
  local modo="${1:-}"
  local instalar_modo
  case "$modo" in
    --usuario)
      instalar_modo="--instalar-usuario"
      ;;
    --sistema)
      instalar_modo="--instalar-sistema"
      aviso "o modo --sistema roda 'dpkg -i' nos pacotes de dados do Kali"
      aviso "(kali-themes-common, kali-wallpapers-2026) e pede sudo."
      confirmar "seguir com a instalação no sistema?" || return 1
      ;;
    *) morre "uso: $0 assets --usuario | --sistema" ;;
  esac
  titulo "Assets do Kali ($modo)"
  run bash "$BASE_DIR/10-baixar-assets.sh" "$instalar_modo"
}

# =============================================================== INSTALAR =====
instala_lista() {
  local nome="$1"; shift
  local -a pedidos=("$@") disponiveis=()
  precisa apt-cache "Sem APT? Verifique a instalação do sistema."
  info "verificando disponibilidade de ${#pedidos[@]} pacotes…"
  apt_disponiveis pedidos disponiveis
  [ "${#disponiveis[@]}" -gt 0 ] || morre "nenhum pacote disponível para $nome"
  echo
  info "serão instalados (${#disponiveis[@]}): ${disponiveis[*]}"
  aviso "nenhum gerenciador de login (sddm/lightdm) entra nesta lista — ver abaixo"
  confirmar "instalar agora com --no-install-recommends?" || return 1
  run_sudo apt-get update
  run_sudo apt-get install -y --no-install-recommends "${disponiveis[@]}"
  ok "$nome instalado"
  info "A sessão aparece na engrenagem do GDM na próxima tela de login."
}

oferta_display_manager() {
  local qual="$1" pacotes="$2"
  echo
  aviso "O Kali usa $qual no sabor correspondente."
  aviso "Instalar $qual TROCA o gerenciador de login de todas as sessões desta"
  aviso "máquina, inclusive a sua sessão GNOME atual. Não é necessário: o GDM"
  aviso "já lista a nova sessão."
  if confirmar "instalar $qual mesmo assim (risco: tela de login)?"; then
    if confirmar "confirme de novo — trocar o gerenciador de login?"; then
      # shellcheck disable=SC2086
      run_sudo apt-get install -y $pacotes
      aviso "para voltar ao GDM: sudo dpkg-reconfigure gdm3"
      if [ "$qual" = "LightDM" ]; then
        echo
        aviso "O $qual recém-instalado usa o greeter PADRÃO — instalá-lo não deixa a"
        aviso "tela de login parecida com a do Kali, e o logo aplicado ao GDM fica inerte."
        aviso "Para tematizar a tela de entrada, depois:  $0 greeter aplicar"
      fi
    fi
  else
    info "mantendo o GDM (recomendado)."
  fi
}

# Instalar o ambiente NÃO aplica a aparência: o 'aplicar' grava no xfconf/kconfig da
# sessão e por isso só funciona de dentro dela. Quem instala, reinicia e entra no
# ambiente novo encontra o tema padrão dele e conclui que o runbook falhou — logo,
# este recado precisa sobreviver às dezenas de linhas de saída do apt.
proximo_passo_aplicar() {
  local alvo="$1"
  echo
  printf '%s┌──────────────────────────────────────────────────────────────┐%s\n' "$C_AMBAR" "$C_RESET"
  printf '%s│%s  O ambiente foi instalado, mas a APARÊNCIA ainda NÃO.        %s│%s\n' \
    "$C_AMBAR" "$C_RESET" "$C_AMBAR" "$C_RESET"
  printf '%s└──────────────────────────────────────────────────────────────┘%s\n' "$C_AMBAR" "$C_RESET"
  info "Sem o passo abaixo você entra na sessão $alvo e vê o tema padrão dela"
  info "(no Xfce: Greybird), não o do Kali."
  echo
  info "  1. Saia da sessão atual (logout, não é preciso reiniciar)."
  info "  2. Na tela de login, escolha a sessão \"$alvo\"."
  info "  3. Abra um terminal já dentro dela e rode:"
  printf '       %s%s aplicar %s%s\n' "$C_BOLD" "$0" "$alvo" "$C_RESET"
  echo
  info "Motivo: a aparência é gravada no serviço de configuração da própria sessão"
  info "(xfconf no Xfce, kconfig no Plasma). De fora, o comando é recusado."
  if [ "$alvo" = "xfce" ] && tem lightdm; then
    info "Depois, para a tela de login: $0 greeter aplicar"
  fi
}

cmd_instalar() {
  checa_base_testada
  case "${1:-}" in
    xfce)
      titulo "Instalar ambiente Xfce"
      instala_lista "Xfce" "${XFCE_PKGS[@]}" || return 1
      oferta_display_manager "LightDM" "lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"
      proximo_passo_aplicar xfce
      ;;
    plasma)
      titulo "Instalar ambiente KDE Plasma"
      aviso "Ubuntu 24.04 traz Plasma 5.27; o Kali usa Plasma 6."
      aviso "A decoração de janela do Kali (kwin-style-kali) não existe aqui —"
      aviso "fica Breeze com as cores KaliDark. Ver docs/guias/05-ambiente-kde-plasma.md §5.1."
      instala_lista "Plasma" "${PLASMA_PKGS[@]}" || return 1
      oferta_display_manager "SDDM" "sddm sddm-theme-breeze"
      proximo_passo_aplicar plasma
      ;;
    *) morre "uso: $0 instalar xfce | plasma" ;;
  esac
}

# ================================================================= APLICAR ====
cmd_aplicar() {
  checa_base_testada
  case "${1:-}" in
    xfce)
      exige_assets || return 1
      exige_sessao xfce || { [ "$DRY_RUN" -eq 1 ] && aviso "seguindo apenas porque é --dry-run" || return 1; }
      titulo "Aplicar aparência do Kali no Xfce"
      run bash "$BASE_DIR/20-aplicar-xfce.sh"
      echo
      info "Próximo passo — o painel, que é etapa separada:  $0 painel xfce"
      ;;
    plasma)
      exige_assets || return 1
      exige_sessao plasma || { [ "$DRY_RUN" -eq 1 ] && aviso "seguindo apenas porque é --dry-run" || return 1; }
      titulo "Aplicar aparência do Kali no Plasma"
      run bash "$BASE_DIR/30-aplicar-plasma.sh"
      ;;
    gnome)
      exige_assets || return 1
      exige_sessao gnome || { [ "$DRY_RUN" -eq 1 ] && aviso "seguindo apenas porque é --dry-run" || return 1; }
      titulo "Aplicar aparência do Kali no GNOME"
      confirmar "isto altera o SEU desktop atual (reversível com '$0 reverter gnome')" || return 1
      run bash "$BASE_DIR/40-aplicar-gnome.sh"
      aviso "em Wayland, faça logout/login para o tema do shell entrar"
      ;;
    *) morre "uso: $0 aplicar xfce | plasma | gnome" ;;
  esac
}

# ================================================================ REVERTER ====
move_bak() {
  local alvo="$1"
  [ -e "$alvo" ] || { info "  nada em $alvo"; return 0; }
  local dest="$alvo.bak-$(date +%Y%m%d-%H%M%S)"
  run mv "$alvo" "$dest"
  ok "movido: $alvo -> $dest"
}

cmd_reverter() {
  case "${1:-}" in
    gnome)
      titulo "Reverter GNOME ao padrão do Ubuntu"
      run bash "$BASE_DIR/41-reverter-gnome.sh"
      ;;
    xfce)
      titulo "Reverter configuração do Xfce"
      info "A configuração do usuário é movida para .bak (nada é apagado)."
      confirmar "mover ~/.config/xfce4 para backup?" || return 1
      move_bak "$HOME/.config/xfce4"
      info "No próximo login, o Xfce recria a configuração padrão."
      ;;
    plasma)
      titulo "Reverter configuração do Plasma"
      info "Os arquivos de configuração do usuário são movidos para .bak."
      confirmar "mover kdeglobals/kwinrc/plasmarc/konsolerc e ~/.local/share/plasma?" || return 1
      local f
      for f in kdeglobals kwinrc plasmarc konsolerc kscreenlockerrc \
               plasma-org.kde.plasma.desktop-appletsrc; do
        move_bak "$HOME/.config/$f"
      done
      move_bak "$HOME/.local/share/plasma"
      ;;
    *) morre "uso: $0 reverter gnome | xfce | plasma" ;;
  esac
}

# ================================================================= REMOVER ====
remove_pacotes() {
  local nome="$1"; shift
  local -a pedidos=("$@") instalados=()
  local p
  for p in "${pedidos[@]}"; do
    # sem `-q`, pelo mesmo motivo de `fonte_presente`: o grep que fecha o pipe cedo
    # mata o produtor com SIGPIPE e o pipefail transforma "instalado" em "ausente".
    if dpkg -l "$p" 2>/dev/null | grep "^ii  $p " >/dev/null 2>&1; then
      instalados+=("$p")
    fi
  done
  [ "${#instalados[@]}" -gt 0 ] || { info "nada de $nome está instalado"; return 0; }
  titulo "Simulação (dry-run do APT) — $nome"
  run_sudo apt-get remove --purge -s "${instalados[@]}"
  echo
  aviso "leia a simulação acima: veja se algum pacote que você usa por conta"
  aviso "própria (thunar, mousepad, konsole, dolphin…) seria removido."
  confirmar "remover de verdade ${#instalados[@]} pacotes de $nome?" || return 1
  run_sudo apt-get remove --purge -y "${instalados[@]}"
  confirmar "rodar 'apt autoremove --purge' para limpar dependências órfãs?" \
    && run_sudo apt-get autoremove --purge -y
  ok "$nome removido"
}

cmd_remover() {
  case "${1:-}" in
    xfce)
      remove_pacotes "Xfce" xfce4 xfce4-goodies xfce4-whiskermenu-plugin \
        xfce4-genmon-plugin xfce4-cpugraph-plugin xfce4-panel-profiles \
        xfce4-terminal xfce4-notifyd xfce4-screensaver xfce4-taskmanager \
        xfce4-screenshooter xfce4-pulseaudio-plugin xfce4-power-manager-plugins
      confirmar "também mover ~/.config/xfce4 para backup?" && move_bak "$HOME/.config/xfce4"
      ;;
    plasma)
      remove_pacotes "Plasma" kde-plasma-desktop plasma-desktop plasma-workspace \
        kwin-x11 systemsettings plasma-nm plasma-pa kscreen powerdevil \
        plasma-systemmonitor kde-spectacle kde-config-gtk-style
      confirmar "também mover a configuração do Plasma para backup?" && cmd_reverter plasma
      ;;
    assets)
      case "${2:-}" in
        --usuario)
          titulo "Remover assets do Kali do \$HOME"
          confirmar "apagar temas, ícones, wallpapers e logos do Kali em \$HOME?" || return 1
          run bash -c 'rm -rf "$HOME"/.themes/Kali-* "$HOME"/.themes/adw-gtk3*'
          run bash -c 'rm -rf "$HOME"/.local/share/icons/Flat-Remix-* "$HOME"/.local/share/icons/Adwaita+Flat-Remix-Blue'
          run bash -c 'rm -rf "$HOME"/.local/share/backgrounds/kali "$HOME"/.local/share/kali-logos'
          run bash -c 'rm -rf "$HOME"/.local/share/wallpapers/KaliCubes*'
          run bash -c 'rm -f  "$HOME"/.local/share/gtksourceview-*/styles/Kali-*.xml'
          run bash -c 'rm -rf "$HOME"/.local/share/color-schemes/Kali*.colors "$HOME"/.local/share/konsole/Kali-Dark.*'
          ok "assets do usuário removidos"
          confirmar "apagar também o cache de download (~/.cache/kali-assets)?" \
            && run bash -c 'rm -rf "$HOME"/.cache/kali-assets'
          ;;
        --sistema)
          titulo "Remover assets do Kali do sistema"
          confirmar "remover kali-themes-common, kali-wallpapers-2026 e adw-gtk3-kali?" || return 1
          run_sudo apt-get remove --purge -y kali-themes-common kali-wallpapers-2026 adw-gtk3-kali
          ok "pacotes removidos"
          ;;
        *) morre "uso: $0 remover assets --usuario | --sistema" ;;
      esac
      ;;
    *) morre "uso: $0 remover xfce | plasma | assets --usuario|--sistema" ;;
  esac
}

# ==================================================================== BOOT ====
cmd_boot() {
  case "${1:-}" in
    aplicar)
      titulo "Camada de boot e login (GRUB, Plymouth, logo do GDM)"
      aviso "Esta é a parte de MAIOR RISCO deste material: erro em GRUB ou em"
      aviso "gerenciador de login pode deixar a máquina sem boot ou sem tela de"
      aviso "entrada. Tenha um live USB à mão e saiba abrir um console com"
      aviso "Ctrl+Alt+F3 antes de continuar."
      assets_sistema || { erro "esta camada exige os assets no sistema: $0 assets --sistema"; return 1; }
      confirmar "entendi os riscos e quero seguir" || return 1
      confirmar "confirme de novo: aplicar tema de boot/login do Kali?" || return 1

      titulo "1/4 avatar do usuário"
      if [ -f /usr/share/images/kali-logos/logo-256.png ]; then
        run cp /usr/share/images/kali-logos/logo-256.png "$HOME/.face"
        run cp "$HOME/.face" "$HOME/.face.icon"
        ok "avatar aplicado"
      fi

      titulo "2/4 logo do GDM"
      run_sudo mkdir -p /etc/dconf/db/gdm.d
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '%s[dry-run]%s escreveria /etc/dconf/db/gdm.d/95-kali-logo\n' "$C_DIM" "$C_RESET"
      else
        printf "[org/gnome/login-screen]\nlogo='/usr/share/images/kali-logos/logo-text-128.png'\n" \
          | sudo tee /etc/dconf/db/gdm.d/95-kali-logo >/dev/null
      fi
      run_sudo dconf update
      ok "logo do GDM aplicado"

      titulo "3/4 Plymouth"
      if [ -f /usr/share/plymouth/themes/kali/kali.plymouth ]; then
        run_sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
          default.plymouth /usr/share/plymouth/themes/kali/kali.plymouth 200
        run_sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/kali/kali.plymouth
        run_sudo update-initramfs -u
        ok "tema de boot aplicado (precisa do pacote plymouth-label)"
      else
        aviso "tema kali do Plymouth não encontrado; pulando"
      fi

      titulo "4/4 GRUB"
      if confirmar "aplicar também o tema do GRUB? (mexe no menu de boot)"; then
        run_sudo cp /boot/grub/grub.cfg "/boot/grub/grub.cfg.bak-$(date +%Y%m%d-%H%M%S)"
        run_sudo cp -r /usr/share/grub/themes/kali /boot/grub/themes/
        run_sudo cp "$REF_DIR/grub-kali-themes.cfg" /etc/default/grub.d/kali-themes.cfg
        run_sudo update-grub
        ok "tema do GRUB aplicado"
      fi
      ;;
    reverter)
      titulo "Reverter boot e login"
      confirmar "remover tema do GRUB, do Plymouth e o logo do GDM?" || return 1
      run_sudo rm -f /etc/default/grub.d/kali-themes.cfg
      run_sudo update-grub
      run_sudo rm -f /etc/dconf/db/gdm.d/95-kali-logo
      run_sudo dconf update
      aviso "Plymouth: escolha o tema anterior na lista que vai abrir"
      run_sudo update-alternatives --config default.plymouth
      run_sudo update-initramfs -u
      run rm -f "$HOME/.face" "$HOME/.face.icon"
      ok "boot/login revertidos"
      ;;
    *) morre "uso: $0 boot aplicar | reverter" ;;
  esac
}

# ================================================================== PAINEL ====
# Etapa separada do 'aplicar xfce' porque `xfce4-panel-profiles load` substitui
# ~/.config/xfce4/panel/ inteiro: carregado depois, ele desfaz o que veio antes.
cmd_painel() {
  case "${1:-}" in
    xfce) ;;
    *) morre "uso: $0 painel xfce [--compacto]" ;;
  esac
  shift
  exige_sessao xfce || { [ "$DRY_RUN" -eq 1 ] && aviso "seguindo apenas porque é --dry-run" || return 1; }
  titulo "Painel do Kali no Xfce"
  log "RUN 22-painel-xfce.sh ${*:-} (dry-run=$DRY_RUN)"
  DRY_RUN="$DRY_RUN" bash "$BASE_DIR/22-painel-xfce.sh" "$@"
}

# ================================================================= GREETER ====
# A tela de login do LightDM é a única camada de aparência que roda como o usuário
# de sistema `lightdm`: ela não lê o seu $HOME. Por isso é etapa própria, exige os
# assets no sistema e não é coberta por 'aplicar xfce'.
cmd_greeter() {
  local acao="${1:-}"
  case "$acao" in
    aplicar|reverter|status) ;;
    *) morre "uso: $0 greeter aplicar | reverter | status" ;;
  esac
  # Chamado direto, sem o wrapper `run`: ao contrário dos outros scripts numerados,
  # o 21 honra DRY_RUN por dentro e imprime cada comando privilegiado que faria.
  log "RUN 21-greeter-lightdm.sh $acao (dry-run=$DRY_RUN)"
  DRY_RUN="$DRY_RUN" ASSUME_YES="$ASSUME_YES" \
    bash "$BASE_DIR/21-greeter-lightdm.sh" "$acao"
}

# ================================================================ TERMINAL ====
PALETA_KALI="['#1F2229','#D41919','#5EBDAB','#FEA44C','#367BF0','#9755B3','#49AEE6','#E6E6E6','#198388','#EC0101','#47D4B9','#FF8A18','#277FFF','#962AC3','#05A1F7','#FFFFFF']"

# A paleta do Kali configura o xfce4-terminal e mais nenhum terminal. Não basta
# instalá-la: se o terminal que abre for outro (o Ubuntu pode ter tilix, terminator
# ou gnome-terminal como padrão), nada muda de aparência e parece que a paleta
# falhou. Estas três funções fecham esse buraco.

# `exo-open --launch TerminalEmulator` — usado pelos atalhos do Kali (Super+T,
# Ctrl+Alt+T) e pelo launcher do painel — resolve pelo helpers.rc.
terminal_preferido_xfce() {
  local rc="$HOME/.config/xfce4/helpers.rc"
  local atual=""
  if [ -f "$rc" ]; then
    atual="$(awk -F= '/^TerminalEmulator=/{print $2; exit}' "$rc" 2>/dev/null || true)"
  fi
  if [ "$atual" = "xfce4-terminal" ]; then
    ok "terminal preferido do Xfce já é o xfce4-terminal"
    return 0
  fi
  [ -n "$atual" ] && info "  terminal preferido atual: $atual"
  run mkdir -p "$HOME/.config/xfce4"
  if [ -f "$rc" ]; then
    run cp "$rc" "$rc.bak-$(date +%Y%m%d-%H%M%S)"
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s[dry-run]%s escreveria TerminalEmulator=xfce4-terminal em %s\n' \
      "$C_DIM" "$C_RESET" "$rc"
  else
    # Preserva as outras escolhas do usuário; troca só a linha do terminal.
    if [ -f "$rc" ]; then
      grep -v '^TerminalEmulator=' "$rc" > "$rc.tmp" 2>/dev/null || true
      printf 'TerminalEmulator=xfce4-terminal\n' >> "$rc.tmp"
      mv "$rc.tmp" "$rc"
    else
      printf 'TerminalEmulator=xfce4-terminal\n' > "$rc"
    fi
  fi
  ok "terminal preferido do Xfce = xfce4-terminal (atalho Super+T)"
}

# O "Root Terminal Emulator" do painel do Kali roda `pkexec x-terminal-emulator`,
# que é uma alternativa do dpkg — global, e por isso pede sudo.
checa_x_terminal_emulator() {
  local atual=""
  atual="$(update-alternatives --query x-terminal-emulator 2>/dev/null \
           | awk '/^Value:/{print $2; exit}' || true)"
  case "$atual" in
    *xfce4-terminal*) ok "x-terminal-emulator já aponta para o xfce4-terminal"; return 0 ;;
    "") aviso "não há alternativa x-terminal-emulator configurada neste sistema"; return 0 ;;
  esac
  aviso "x-terminal-emulator aponta para: $atual"
  aviso "É o que o \"Root Terminal\" do painel abre — sairia sem a paleta do Kali."
  if confirmar "apontar x-terminal-emulator para o xfce4-terminal? (afeta todo o sistema)"; then
    run_sudo update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper
    ok "x-terminal-emulator = xfce4-terminal"
  else
    info "Mantido. Para trocar depois:"
    info "  sudo update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper"
    info "  (ou 'sudo update-alternatives --config x-terminal-emulator' para escolher)"
  fi
}

# Sobe a árvore de processos até achar um emulador de terminal conhecido. É assim
# que descobrimos em qual terminal o usuário está de fato — a causa nº 1 de
# "apliquei a paleta e o terminal não mudou" é ela ter ido para outro programa.
terminal_em_uso() {
  local p="$PPID" nome="" i=0
  while [ "$i" -lt 8 ] && [ -n "$p" ] && [ "$p" != "1" ]; do
    nome="$(ps -o comm= -p "$p" 2>/dev/null | tr -d ' ' || true)"
    case "$nome" in
      xfce4-terminal|tilix|terminator|konsole|kitty|alacritty|xterm|qterminal)
        printf '%s' "$nome"; return 0 ;;
      gnome-terminal*) printf 'gnome-terminal'; return 0 ;;
    esac
    p="$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ' || true)"
    i=$((i + 1))
  done
  return 1
}

terminal_em_uso_avisa() {
  local atual=""
  atual="$(terminal_em_uso || true)"
  [ -n "$atual" ] || return 0
  if [ "$atual" = "xfce4-terminal" ]; then
    ok "você já está no xfce4-terminal"
    return 0
  fi
  echo
  aviso "O terminal em que você está agora é o $atual, não o xfce4-terminal."
  aviso "O que acabou de ser configurado vale SÓ para o xfce4-terminal."
  info  "Abra o xfce4-terminal (Super+T, ou o ícone do painel) para ver o resultado —"
  info  "ou aplique a paleta no $atual, se preferir continuar nele:"
  case "$atual" in
    tilix)          info "  $0 terminal tilix" ;;
    gnome-terminal) info "  $0 terminal gnome" ;;
    konsole)        info "  $0 terminal plasma" ;;
    *)              info "  a paleta para $atual está em docs/guias/07-terminal-e-prompt.md §7.5" ;;
  esac
}

cmd_terminal() {
  case "${1:-}" in
    gnome)
      precisa gsettings "Instale com: sudo apt install libglib2.0-bin"
      titulo "Paleta do Kali no gnome-terminal"
      local P G
      P="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")"
      [ -n "$P" ] || morre "perfil padrão do gnome-terminal não encontrado"
      G="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P/"
      run gsettings set "$G" palette "$PALETA_KALI"
      run gsettings set "$G" use-theme-colors true
      run gsettings set "$G" bold-is-bright true
      run gsettings set "$G" scrollback-unlimited true
      run gsettings set "$G" use-transparent-background true
      run gsettings set "$G" background-transparency-percent 5
      run gsettings set "$G" use-system-font false
      run gsettings set "$G" font 'Fira Code Medium 10'
      run gsettings set org.gnome.Terminal.Legacy.Settings theme-variant 'dark'
      run gsettings set org.gnome.Terminal.Legacy.Settings confirm-close false
      ok "gnome-terminal configurado"
      ;;
    xfce)
      titulo "Terminal do Kali no Xfce"
      if ! tem xfce4-terminal; then
        erro "o xfce4-terminal não está instalado — é ELE que o Kali usa."
        info "A paleta deste runbook configura o xfce4-terminal e mais nenhum."
        info "Instale com: sudo apt install xfce4-terminal"
        return 1
      fi

      info "1/3 paleta, transparência e fonte"
      run mkdir -p "$HOME/.config/xfce4/terminal"
      if [ -f "$HOME/.config/xfce4/terminal/terminalrc" ]; then
        move_bak "$HOME/.config/xfce4/terminal/terminalrc"
      fi
      run cp "$REF_DIR/shell/xfce4-terminalrc" "$HOME/.config/xfce4/terminal/terminalrc"
      ok "terminalrc instalado"

      info "2/3 terminal preferido do Xfce"
      terminal_preferido_xfce

      info "3/3 terminal padrão do sistema"
      checa_x_terminal_emulator

      echo
      aviso "Janela de terminal já aberta NÃO muda: o xfce4-terminal lê o"
      aviso "terminalrc na inicialização. Abra uma nova (Super+T) para ver."
      terminal_em_uso_avisa
      ;;
    plasma)
      titulo "Paleta do Kali no Konsole"
      run mkdir -p "$HOME/.local/share/konsole"
      run cp "$REF_DIR/kde/Kali-Dark.profile" "$REF_DIR/kde/Kali-Dark.colorscheme" \
             "$HOME/.local/share/konsole/"
      local KW
      KW="$(command -v kwriteconfig5 || command -v kwriteconfig6 || true)"
      [ -n "$KW" ] && run "$KW" --file konsolerc --group "Desktop Entry" \
        --key DefaultProfile Kali-Dark.profile \
        || aviso "kwriteconfig não encontrado; defina o perfil pela interface do Konsole"
      ok "Konsole configurado"
      ;;
    tilix)
      precisa dconf "Instale com: sudo apt install dconf-cli"
      tem tilix || morre "o tilix não está instalado"
      titulo "Paleta do Kali no tilix"
      local U B
      # `|| true`: com pipefail, o grep sem correspondência abortaria a atribuição.
      U="$(dconf list /com/gexperts/Tilix/profiles/ 2>/dev/null | grep '/$' | head -1 | tr -d '/' || true)"
      [ -n "$U" ] || morre "nenhum perfil do tilix encontrado — abra o tilix uma vez e repita"
      B="/com/gexperts/Tilix/profiles/$U"
      info "perfil: $U"
      # Origem: /usr/share/tilix/schemes/Kali.json, do pacote kali-themes-common.
      # Mesmas 16 cores da PALETA_KALI usada no gnome-terminal.
      local PAL_TILIX="['#1F2229', '#D41919', '#5EBDAB', '#FEA44C', '#367bf0', '#9755b3', '#49AEE6', '#E6E6E6', '#198388', '#EC0101', '#47D4B9', '#FF8A18', '#277FFF', '#962ac3', '#05A1F7', '#FFFFFF']"
      run dconf write "$B/palette" "$PAL_TILIX"
      run dconf write "$B/use-theme-colors" true
      # Fonte: xsettings.xml do Kali define MonospaceFontName = Fira Code Medium 10.
      # O tilix, sendo app GTK, leria a fonte mono do GNOME (outra) com system-font.
      run dconf write "$B/use-system-font" false
      run dconf write "$B/font" "'Fira Code Medium 10'"
      # terminalrc do Kali: BackgroundDarkness=0.95 -> 5% de transparência.
      run dconf write "$B/use-transparent-background" true
      run dconf write "$B/background-transparency-percent" 5
      ok "tilix configurado (abra uma aba nova para ver)"
      info "Desfazer: dconf reset -f $B/"
      ;;
    auto|"")
      local atual=""
      atual="$(terminal_em_uso || true)"
      if [ -z "$atual" ]; then
        erro "não identifiquei o terminal em uso."
        info "uso: $0 terminal xfce | tilix | gnome | plasma"
        return 1
      fi
      info "terminal em uso: $atual"
      case "$atual" in
        xfce4-terminal) cmd_terminal xfce ;;
        tilix)          cmd_terminal tilix ;;
        gnome-terminal) cmd_terminal gnome ;;
        konsole)        cmd_terminal plasma ;;
        *)
          erro "não há receita automática para $atual neste runbook."
          info "A paleta das 16 cores está em docs/guias/07-terminal-e-prompt.md §7.1;"
          info "o §7.5 lista onde o Kali põe o esquema de cada terminal."
          return 1 ;;
      esac
      ;;
    *) morre "uso: $0 terminal xfce | tilix | gnome | plasma | auto" ;;
  esac
}

# ================================================================== PROMPT ====
PROMPT_INICIO='# >>> prompt kali >>>'
PROMPT_FIM='# <<< prompt kali <<<'

# Um framework de prompt (oh-my-zsh com tema, Powerlevel10k, Starship) redefine o
# PROMPT em cada `precmd`. O bloco do Kali fica no arquivo, a variável até é lida
# certa por `zsh -i -c`, e ainda assim a tela mostra o outro prompt — porque quem
# desenha por último ganha. Detectar isso é a diferença entre "não funcionou" e
# "há dois prompts disputando; escolha um".
prompt_concorrente() {
  local rc="$1" achados=""
  [ -f "$rc" ] || return 1
  local tema=""
  tema="$(awk -F'"' '/^[[:space:]]*ZSH_THEME=/{print $2; exit}' "$rc" 2>/dev/null || true)"
  if [ -n "$tema" ] && [ "$tema" != "" ]; then
    achados="oh-my-zsh com ZSH_THEME=\"$tema\""
  fi
  if grep -qE '^[[:space:]]*(eval "\$\(starship init zsh\)"|source.*starship)' "$rc" 2>/dev/null; then
    achados="${achados:+$achados; }Starship"
  fi
  if grep -qE '^[[:space:]]*source.*powerlevel10k|^[[:space:]]*ZSH_THEME=.*powerlevel10k' "$rc" 2>/dev/null; then
    achados="${achados:+$achados; }Powerlevel10k"
  fi
  [ -n "$achados" ] || return 1
  printf '%s' "$achados"
}

# Desativa o prompt concorrente em vez de só explicar como fazê-lo à mão. Mexe em
# UMA linha do .zshrc, com backup, e diz qual — reverter é trocar de volta.
prompt_desativa_concorrente() {
  local rc="$1" quem=""
  quem="$(prompt_concorrente "$rc" || true)"
  if [ -z "$quem" ]; then
    ok "nenhum prompt concorrente no $rc"
    return 0
  fi
  aviso "concorrente encontrado: $quem"
  info "Desativar troca a linha do tema por um valor vazio; plugins, aliases e o"
  info "resto do oh-my-zsh continuam iguais."
  confirmar "desativar o concorrente para o prompt do Kali aparecer?" || return 1
  run cp "$rc" "$rc.bak-$(date +%Y%m%d-%H%M%S)"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s[dry-run]%s comentaria/zeraria ZSH_THEME, starship e powerlevel10k em %s\n' \
      "$C_DIM" "$C_RESET" "$rc"
    return 0
  fi
  # ZSH_THEME="algo" -> ZSH_THEME=""  (mantém o oh-my-zsh, sem tema)
  sed -i 's/^\([[:space:]]*\)ZSH_THEME=".*"/\1ZSH_THEME=""   # zerado por kali-look: o prompt do Kali assume/' "$rc"
  # starship e p10k: comentar a linha que inicializa
  sed -i 's|^\([[:space:]]*\)\(eval "\$(starship init zsh)"\)|\1# \2   # comentado por kali-look|' "$rc"
  sed -i 's|^\([[:space:]]*\)\(source.*powerlevel10k.*\)$|\1# \2   # comentado por kali-look|' "$rc"
  ok "concorrente desativado (backup em $rc.bak-<data>)"
  info "Abra um terminal novo para ver. Para voltar ao seu prompt, reverta a linha"
  info "marcada com \"por kali-look\" ou restaure o .bak."
}

prompt_avisa_concorrente() {
  local rc="$1" quem=""
  quem="$(prompt_concorrente "$rc" || true)"
  [ -n "$quem" ] || return 0
  echo
  aviso "Há outro prompt ativo neste $rc: $quem."
  aviso "Ele redesenha o PROMPT a cada comando, DEPOIS do bloco do Kali — então o"
  aviso "bloco fica no arquivo e não aparece na tela. Não é falha da aplicação:"
  aviso "são dois prompts disputando, e quem desenha por último ganha."
  echo
  info "Para ficar com o prompt do Kali, desative o concorrente:"
  info "  • oh-my-zsh: troque a linha por  ZSH_THEME=\"\"  (tema vazio)"
  info "  • Starship:  comente a linha  eval \"\$(starship init zsh)\""
  info "  • Powerlevel10k: comente o source do tema e o do ~/.p10k.zsh"
  info "Depois abra um terminal novo. Para voltar ao seu, é só reverter a linha."
  echo
  info "Ou deixe o script fazer isso, com backup:  $0 prompt exclusivo"
}

cmd_prompt() {
  local RC="$HOME/.zshrc"
  case "${1:-}" in
    exclusivo)
      titulo "Prompt do Kali como único prompt do zsh"
      [ -f "$RC" ] || morre "$RC não existe"
      if ! grep -q "$PROMPT_INICIO" "$RC" 2>/dev/null; then
        info "o bloco do Kali ainda não está no $RC — aplicando primeiro"
        cmd_prompt aplicar || return 1
      fi
      prompt_desativa_concorrente "$RC"
      ;;
    aplicar)
      titulo "Prompt de duas linhas do Kali no zsh"
      [ -f "$RC" ] || morre "$RC não existe"
      if grep -q "$PROMPT_INICIO" "$RC" 2>/dev/null; then
        ok "o bloco do Kali já está no $RC"
        if prompt_avisa_concorrente "$RC"; then :; fi
        return 0
      fi
      prompt_avisa_concorrente "$RC"
      confirmar "acrescentar o bloco ao fim do $RC (com backup)?" || return 1
      run cp "$RC" "$RC.bak-$(date +%Y%m%d-%H%M%S)"
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '%s[dry-run]%s acrescentaria o bloco delimitado ao %s\n' "$C_DIM" "$C_RESET" "$RC"
      else
        cat >> "$RC" <<'ZEOF'

# >>> prompt kali >>>
# Prompt de duas linhas do Kali (origem: /etc/skel/.zshrc do pacote kali-defaults)
setopt promptsubst
PROMPT_EOL_MARK=""
prompt_symbol=㉿
PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}(%B%F{%(#.red.blue)}%n'$prompt_symbol$'%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└─%B%(#.%F{red}#.%F{blue}$)%b%F{reset} '
# RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'
precmd() { print "" }
# <<< prompt kali <<<
ZEOF
      fi
      ok "bloco acrescentado — abra um terminal novo para ver"
      ;;
    remover)
      titulo "Remover o prompt do Kali do zsh"
      grep -q "$PROMPT_INICIO" "$RC" 2>/dev/null || { info "bloco não encontrado"; return 0; }
      confirmar "remover o bloco delimitado do $RC (com backup)?" || return 1
      run cp "$RC" "$RC.bak-$(date +%Y%m%d-%H%M%S)"
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '%s[dry-run]%s removeria as linhas entre os marcadores\n' "$C_DIM" "$C_RESET"
      else
        sed -i "/$PROMPT_INICIO/,/$PROMPT_FIM/d" "$RC"
      fi
      ok "bloco removido"
      ;;
    *) morre "uso: $0 prompt aplicar | exclusivo | remover" ;;
  esac
}

# ================================================================= ANALISAR ===
cmd_analisar() {
  local script="$BASE_DIR/50-analise-wayland-xorg.sh"
  [ -x "$script" ] || morre "não encontrei $script"
  titulo "Análise Wayland → Xorg"
  info "Somente leitura: nada é alterado. Mostra o que da sua sessão GNOME/Wayland"
  info "deixa de funcionar, funciona pior ou muda de caminho numa sessão Xfce/Xorg."
  echo
  bash "$script" "$@"
}

# ==================================================================== MENU ====
menu() {
  local op
  while true; do
    printf '\n%s┌──────────────────────────────────────────────────────────────┐%s\n' "$C_AZUL" "$C_RESET"
    printf '%s│%s  %skali-look%s %s — aparência do Kali Linux neste Ubuntu        %s│%s\n' \
      "$C_AZUL" "$C_RESET" "$C_BOLD" "$C_RESET" "$VERSAO" "$C_AZUL" "$C_RESET"
    printf '%s└──────────────────────────────────────────────────────────────┘%s\n' "$C_AZUL" "$C_RESET"
    [ "$DRY_RUN" -eq 1 ] && printf '  %s(modo dry-run: nada será alterado)%s\n' "$C_AMBAR" "$C_RESET"
    cat <<'MENU'

  Diagnóstico e segurança
    1) Ver o estado atual do sistema
    2) Fazer backup antes de mexer
    a) Analisar o que muda ao sair do Wayland para o Xorg (Xfce)

  Preparação
    3) Baixar e instalar os assets do Kali no meu usuário  (reversível)
    4) Baixar e instalar os assets no sistema              (p/ boot e login)

  Escolher e instalar ambiente
    5) Instalar o ambiente Xfce        (recomendado, ~95% de fidelidade)
    6) Instalar o ambiente KDE Plasma  (~80%)

  Aplicar a aparência
    7) Aplicar no Xfce      (rodar dentro da sessão Xfce)
    8) Aplicar no Plasma    (rodar dentro da sessão Plasma)
    9) Aplicar no GNOME     (altera o desktop atual)
    p) Painel do Kali no Xfce (perfil + Whisker Menu + genmon)

  Peças isoladas
   10) Terminal: paleta do Kali (auto / xfce / tilix / gnome / plasma)
   11) Prompt de duas linhas no zsh: aplicar
    x) Prompt do Kali como ÚNICO prompt (desativa oh-my-zsh/Starship/p10k)
   12) Prompt de duas linhas no zsh: remover
   13) Boot e login (GRUB, Plymouth, logo do GDM) — risco alto
   14) Reverter boot e login
    g) Tela de login do LightDM: aplicar o tema do Kali  (risco alto)
    G) Tela de login do LightDM: reverter ao padrão

  Desfazer
   15) Reverter o GNOME ao padrão do Ubuntu
   16) Reverter configuração do Xfce
   17) Reverter configuração do Plasma
   18) Desinstalar o ambiente Xfce
   19) Desinstalar o ambiente KDE Plasma
   20) Remover os assets do Kali (usuário)
   21) Remover os assets do Kali (sistema)

    d) Alternar o modo dry-run
    q) Sair

MENU
    read -r -p "$(printf '%sopção:%s ' "$C_BOLD" "$C_RESET")" op || return 0
    case "$op" in
      1)  cmd_status ;;
      2)  cmd_backup ;;
      3)  cmd_assets --usuario ;;
      4)  cmd_assets --sistema ;;
      5)  cmd_instalar xfce ;;
      6)  cmd_instalar plasma ;;
      7)  cmd_aplicar xfce ;;
      8)  cmd_aplicar plasma ;;
      9)  cmd_aplicar gnome ;;
      10) read -r -p "  qual terminal (Enter=auto / xfce / tilix / gnome / plasma)? " t
          cmd_terminal "${t:-auto}" ;;
      11) cmd_prompt aplicar ;;
      x|X) cmd_prompt exclusivo ;;
      12) cmd_prompt remover ;;
      13) cmd_boot aplicar ;;
      14) cmd_boot reverter ;;
      15) cmd_reverter gnome ;;
      16) cmd_reverter xfce ;;
      17) cmd_reverter plasma ;;
      18) cmd_remover xfce ;;
      19) cmd_remover plasma ;;
      20) cmd_remover assets --usuario ;;
      21) cmd_remover assets --sistema ;;
      a|A) cmd_analisar ;;
      p)  cmd_painel xfce ;;
      g)  cmd_greeter aplicar ;;
      G)  cmd_greeter reverter ;;
      d)  DRY_RUN=$((1 - DRY_RUN)); info "dry-run agora: $DRY_RUN" ;;
      q|Q|"") info "até logo"; return 0 ;;
      *)  aviso "opção inválida: $op" ;;
    esac
  done
}

# =================================================================== USAGE ====
usage() {
  cat <<AJUDA_EOF
kali-look.sh $VERSAO — aparência do Kali Linux neste Ubuntu 24.04

USO
  $0                                  menu interativo
  $0 [opções globais] <comando> [...]

OPÇÕES GLOBAIS
  --dry-run     só mostra o que faria, não altera nada
  --sim         responde "sim" a todas as confirmações (cuidado)
  -h, --help    esta ajuda

COMANDOS
  status                              estado atual: sessão, temas, assets, extensões, boot
  backup                              salva dconf + configs + lista de pacotes
  analisar [--sem-md|--md-apenas]     o que muda ao trocar Wayland (GNOME) por Xorg (Xfce)

  assets --usuario                    baixa os .deb do Kali e instala no \$HOME (reversível)
  assets --sistema                    instala em /usr/share (necessário p/ GRUB, Plymouth, GDM)

  instalar xfce                       instala o ambiente Xfce (sem trocar o gerenciador de login)
  instalar plasma                     instala o ambiente KDE Plasma

  aplicar xfce|plasma|gnome           aplica tema, ícones, fontes, wallpaper e terminal
  reverter gnome                      volta o GNOME ao Yaru-purple-dark
  reverter xfce|plasma                move a configuração do usuário para .bak

  remover xfce|plasma                 desinstala o ambiente (simula antes, pede confirmação)
  remover assets --usuario|--sistema  remove temas, ícones e wallpapers do Kali

  terminal xfce|tilix|gnome|plasma    paleta/fonte/transparência do terminal
  terminal auto                       detecta o terminal em uso e aplica nele
  prompt aplicar|remover              bloco do prompt de duas linhas no ~/.zshrc
  prompt exclusivo                    aplica E desativa o prompt concorrente (oh-my-zsh,
                                      Starship, Powerlevel10k) que o sobrescreveria
  boot aplicar|reverter               GRUB + Plymouth + logo do GDM (risco alto)
  greeter aplicar|reverter|status     tela de login do LightDM (risco alto)
  painel xfce [--compacto]            painel do Kali: perfil + Whisker + genmon

EXEMPLOS
  $0 status
  $0 analisar                         # relatório no terminal + markdown em relatorios/
  $0 backup
  $0 assets --usuario
  $0 greeter status                   # o que a tela de login está usando hoje
  $0 --dry-run aplicar gnome          # ensaio, sem mexer em nada
  $0 aplicar gnome
  $0 reverter gnome
  $0 --dry-run remover xfce
  $0 terminal auto                    # aplica no terminal em que você está
  $0 --sim terminal gnome             # sem perguntas

Log de tudo o que foi feito: $LOG
Documentação completa: $PROJ/README.md
AJUDA_EOF
}

# ==================================================================== MAIN ====
main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1; shift ;;
      --sim|--yes|-y) ASSUME_YES=1; shift ;;
      -h|--help|help|ajuda) usage; return 0 ;;
      *) break ;;
    esac
  done

  log "INVOCADO ${*:-<menu>} (dry-run=$DRY_RUN sim=$ASSUME_YES)"

  case "${1:-}" in
    "")          menu ;;
    status)      cmd_status ;;
    backup)      cmd_backup ;;
    analisar)    shift; cmd_analisar "$@" ;;
    assets)      shift; cmd_assets "$@" ;;
    instalar)    shift; cmd_instalar "$@" ;;
    aplicar)     shift; cmd_aplicar "$@" ;;
    reverter)    shift; cmd_reverter "$@" ;;
    remover)     shift; cmd_remover "$@" ;;
    boot)        shift; cmd_boot "$@" ;;
    greeter)     shift; cmd_greeter "$@" ;;
    painel)      shift; cmd_painel "$@" ;;
    terminal)    shift; cmd_terminal "$@" ;;
    prompt)      shift; cmd_prompt "$@" ;;
    *)           erro "comando desconhecido: $1"; echo; usage; return 1 ;;
  esac
}

main "$@"
