#!/usr/bin/env bash
# 50-analise-wayland-xorg.sh — o que da sessão GNOME/Wayland atual deixa de
# funcionar, funciona pior ou muda de caminho numa sessão Xfce/Xorg.
#
# SOMENTE LEITURA: não instala, não remove, não altera configuração alguma.
#
# Uso:
#   bash 50-analise-wayland-xorg.sh              relatório no terminal + markdown
#   bash 50-analise-wayland-xorg.sh --sem-md     só no terminal
#   bash 50-analise-wayland-xorg.sh --md-apenas  só o arquivo markdown
#   bash 50-analise-wayland-xorg.sh --help
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_DIR="$(dirname "$BASE_DIR")"
REL_DIR="$DOC_DIR/relatorios"
MOSTRAR=1
GRAVAR=1

for a in "$@"; do
  case "$a" in
    --sem-md)    GRAVAR=0 ;;
    --md-apenas) MOSTRAR=0 ;;
    -h|--help)
      sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "opção desconhecida: $a" >&2; exit 1 ;;
  esac
done

# ---------------------------------------------------------------- aparência ---
if [ -t 1 ] && [ "$MOSTRAR" -eq 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_AZUL=$'\033[38;5;33m'; C_VERDE=$'\033[38;5;42m'
  C_AMBAR=$'\033[38;5;214m'; C_VERM=$'\033[38;5;160m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_AZUL=""; C_VERDE=""; C_AMBAR=""; C_VERM=""
fi

MD="$(mktemp)"
trap 'rm -f "$MD"' EXIT

N_QUEBRA=0; N_DEGRADA=0; N_MUDA=0; N_MELHORA=0; N_OK=0

tem()  { command -v "$1" >/dev/null 2>&1; }
inst() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"; }

sec() {
  if [ "$MOSTRAR" -eq 1 ]; then printf '\n%s== %s ==%s\n' "$C_BOLD$C_AZUL" "$*" "$C_RESET"; fi
  printf '\n## %s\n\n' "$*" >> "$MD"
}

nota() {
  if [ "$MOSTRAR" -eq 1 ]; then printf '   %s%s%s\n' "$C_DIM" "$*" "$C_RESET"; fi
  printf '%s\n\n' "_${*}_" >> "$MD"
}

# achado <SEVERIDADE> <título> <motivo> <ação>
achado() {
  local sev="$1" tit="$2" mot="$3" aco="${4:-—}" cor=""
  case "$sev" in
    QUEBRA)  cor="$C_VERM";  N_QUEBRA=$((N_QUEBRA+1)) ;;
    DEGRADA) cor="$C_AMBAR"; N_DEGRADA=$((N_DEGRADA+1)) ;;
    MUDA)    cor="$C_AZUL";  N_MUDA=$((N_MUDA+1)) ;;
    MELHORA) cor="$C_VERDE"; N_MELHORA=$((N_MELHORA+1)) ;;
    OK)      cor="$C_DIM";   N_OK=$((N_OK+1)) ;;
  esac
  if [ "$MOSTRAR" -eq 1 ]; then
    printf '  %s[%-7s]%s %s\n' "$cor$C_BOLD" "$sev" "$C_RESET" "$tit"
    printf '            motivo: %s\n' "$mot"
    if [ "$aco" != "—" ]; then printf '            %sação:%s   %s\n' "$C_BOLD" "$C_RESET" "$aco"; fi
  fi
  {
    printf -- '- **[%s] %s**\n' "$sev" "$tit"
    printf -- '    - Motivo: %s\n' "$mot"
    if [ "$aco" != "—" ]; then printf -- '    - Ação: %s\n' "$aco"; fi
  } >> "$MD"
}

# ================================================================ cabeçalho ===
AGORA="$(date '+%d/%m/%Y %H:%M')"
{
  printf '# Análise Wayland → Xorg (GNOME atual → sessão Xfce)\n\n'
  printf 'Gerado em %s por `scripts/50-analise-wayland-xorg.sh` (somente leitura).\n\n' "$AGORA"
  printf 'Severidades: **QUEBRA** deixa de funcionar · **DEGRADA** funciona pior ·\n'
  printf '**MUDA** funciona por outro caminho, precisa reconfigurar · **MELHORA** passa a\n'
  printf 'funcionar melhor no Xorg · **OK** indiferente.\n'
} >> "$MD"

if [ "$MOSTRAR" -eq 1 ]; then
  printf '%s┌────────────────────────────────────────────────────────────┐%s\n' "$C_AZUL" "$C_RESET"
  printf '%s│%s  %sAnálise Wayland → Xorg%s  (o que muda ao usar o Xfce)     %s│%s\n' \
    "$C_AZUL" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_AZUL" "$C_RESET"
  printf '%s└────────────────────────────────────────────────────────────┘%s\n' "$C_AZUL" "$C_RESET"
  printf '  %s%s — somente leitura, nada é alterado%s\n' "$C_DIM" "$AGORA" "$C_RESET"
fi

# ============================================================== 1. sessão =====
sec "1. Sessão gráfica"
TIPO="${XDG_SESSION_TYPE:-desconhecido}"
DESK="${XDG_CURRENT_DESKTOP:-desconhecido}"
nota "sessão atual: $DESK ($TIPO)"

SESS_X=""; SESS_W=""
if [ -d /usr/share/xsessions ]; then SESS_X="$(ls /usr/share/xsessions/ 2>/dev/null | tr '\n' ' ')"; fi
if [ -d /usr/share/wayland-sessions ]; then SESS_W="$(ls /usr/share/wayland-sessions/ 2>/dev/null | tr '\n' ' ')"; fi
nota "sessões Xorg disponíveis: ${SESS_X:-nenhuma}"
nota "sessões Wayland disponíveis: ${SESS_W:-nenhuma}"

if [ "$TIPO" != "wayland" ]; then
  achado OK "a sessão atual já não é Wayland" \
    "XDG_SESSION_TYPE=$TIPO — a maior parte desta análise não se aplica" \
    "rode de novo dentro da sessão Wayland para comparar"
elif ls /usr/share/xsessions/xfce.desktop >/dev/null 2>&1; then
  achado OK "a sessão Xfce (Xorg) já está instalada e aparece no login" \
    "existe /usr/share/xsessions/xfce.desktop" \
    "escolha \"Xfce Session\" na engrenagem do GDM; a sessão GNOME continua disponível"
else
  achado MUDA "não há sessão Xfce instalada ainda" \
    "nenhum xfce.desktop em /usr/share/xsessions — o Xfce ainda não foi instalado" \
    "veja docs/guias/04-ambiente-xfce.md ou rode ./kali-look.sh instalar xfce"
fi

# ============================================================== 2. escala =====
sec "2. Escala de tela e HiDPI"
if tem gsettings; then
  EXPF="$(gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo '?')"
  TSF="$(gsettings get org.gnome.desktop.interface text-scaling-factor 2>/dev/null || echo '?')"
  nota "mutter experimental-features: $EXPF"
  nota "text-scaling-factor: $TSF"

  if [[ "$EXPF" == *scale-monitor-framebuffer* ]]; then
    achado DEGRADA "escala fracionária está habilitada no Wayland" \
      "o Xorg só faz escala inteira e global (1x, 2x); não há 125%/150% por monitor" \
      "no Xfce use Aparência → Fontes → DPI personalizado, ou xfconf /Xft/DPI, como aproximação"
  else
    achado OK "escala fracionária não está em uso" \
      "org.gnome.mutter experimental-features não inclui scale-monitor-framebuffer" \
      "—"
  fi

  case "$TSF" in
    1.0|1|'?') : ;;
    *) achado MUDA "fator de escala de texto diferente de 1 ($TSF)" \
         "o Xfce não lê text-scaling-factor do GNOME" \
         "reproduza com: xfconf-query -c xsettings -p /Xft/DPI -t int -s \$((96 * $TSF))" ;;
  esac
else
  nota "gsettings não encontrado — escala não verificável aqui"
fi

MON="$HOME/.config/monitors.xml"
if [ -f "$MON" ]; then
  ESCALAS="$(grep -oE '<scale>[0-9.]+' "$MON" 2>/dev/null | sed 's/<scale>//' | sort -u | tr '\n' ' ' || true)"
  nota "escalas por monitor em monitors.xml: ${ESCALAS:-nenhuma}"
  FRAC=0; DIST=0
  for e in $ESCALAS; do case "$e" in 1|1.0) : ;; *) FRAC=1 ;; esac; done
  if [ "$(printf '%s\n' $ESCALAS | wc -w)" -gt 1 ]; then DIST=1; fi
  if [ "$FRAC" -eq 1 ] || [ "$DIST" -eq 1 ]; then
    achado DEGRADA "há escala fracionária e/ou escalas diferentes entre monitores" \
      "escalas encontradas: $ESCALAS — o Xorg aplica uma escala inteira para todas as telas" \
      "no Xfce, defina um DPI único que sirva às duas telas, ou use uma tela por vez"
  else
    achado OK "todas as telas estão em escala 1" \
      "sem escala fracionária, o Xorg reproduz o mesmo resultado" \
      "—"
  fi
  RATES="$(grep -oE '<rate>[0-9.]+' "$MON" 2>/dev/null | sed 's/<rate>//' | sort -u | tr '\n' ' ' || true)"
  if [ "$(printf '%s\n' $RATES | wc -w)" -gt 1 ]; then
    achado DEGRADA "monitores com taxas de atualização diferentes ($RATES)" \
      "no Xorg um único servidor compõe todas as telas; a menor taxa tende a limitar as demais" \
      "aceite o limite ou iguale as taxas em Configurações de tela do Xfce"
  fi
else
  nota "sem ~/.config/monitors.xml — layout de telas não verificável aqui"
fi

# ================================================= 3. variáveis e flags =======
sec "3. Variáveis de ambiente e flags de aplicativo com Wayland"
ARQS=("$HOME/.profile" "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc"
      "$HOME/.pam_environment" /etc/environment)
if [ -d "$HOME/.config/environment.d" ]; then
  while IFS= read -r f; do ARQS+=("$f"); done < <(find "$HOME/.config/environment.d" -type f 2>/dev/null)
fi
while IFS= read -r f; do ARQS+=("$f"); done < <(ls "$HOME"/.config/*-flags.conf 2>/dev/null || true)

PADRAO='MOZ_ENABLE_WAYLAND|GDK_BACKEND[[:space:]]*=[[:space:]]*wayland|QT_QPA_PLATFORM[[:space:]]*=[[:space:]]*wayland|SDL_VIDEODRIVER[[:space:]]*=[[:space:]]*wayland|CLUTTER_BACKEND[[:space:]]*=[[:space:]]*wayland|ozone-platform=wayland|ozone-platform-hint=wayland|WAYLAND_DISPLAY[[:space:]]*='
ACHOU_VAR=0
for f in "${ARQS[@]}"; do
  [ -f "$f" ] || continue
  while IFS= read -r linha; do
    [ -z "$linha" ] && continue
    ACHOU_VAR=1
    achado QUEBRA "força Wayland em configuração: ${f/#$HOME/~}" \
      "linha \"$(echo "$linha" | cut -c1-90)\" pede backend Wayland; no Xorg o app não sobe ou cai para fallback" \
      "comente ou remova essa linha antes de usar a sessão Xfce"
  done < <(grep -hnEi "$PADRAO" "$f" 2>/dev/null | grep -vE '^\s*[0-9]+:\s*#' || true)
done

DESKS=()
for d in "$HOME/.local/share/applications" /usr/share/applications; do
  [ -d "$d" ] || continue
  while IFS= read -r f; do DESKS+=("$f"); done < <(grep -rlE 'ozone-platform(-hint)?=wayland|GDK_BACKEND=wayland|MOZ_ENABLE_WAYLAND' "$d" 2>/dev/null || true)
done
if [ "${#DESKS[@]}" -gt 0 ]; then
  ACHOU_VAR=1
  for f in "${DESKS[@]}"; do
    achado QUEBRA "lançador com flag Wayland: ${f/#$HOME/~}" \
      "o Exec= desse .desktop pede Wayland explicitamente" \
      "edite o Exec= e remova a flag (uma cópia em ~/.local/share/applications sobrepõe a do sistema)"
  done
fi

if [ "$ACHOU_VAR" -eq 0 ]; then
  achado OK "nenhuma variável ou flag Wayland fixada" \
    "nada em ~/.profile, ~/.zshrc, /etc/environment, ~/.config/environment.d, *-flags.conf ou nos .desktop" \
    "—"
fi

# =========================================================== 4. extensões =====
sec "4. Extensões do GNOME Shell"
EXTS=""
if tem gnome-extensions; then
  EXTS="$(gnome-extensions list --enabled 2>/dev/null | tr '\n' ' ' || true)"
fi
if [ -z "${EXTS// /}" ] && tem gsettings; then
  EXTS="$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null \
          | tr -d "[]'@as" | tr ',' ' ' || true)"
fi

equivalente() {
  case "$1" in
    clipboard-indicator*)                 echo "xfce4-clipman-plugin (histórico de área de transferência no painel)" ;;
    dash-to-dock*|ubuntu-dock*)           echo "o próprio painel do Xfce (ou plank, se quiser um dock separado)" ;;
    ubuntu-appindicators*|appindicator*)  echo "bandeja nativa do xfce4-panel (plugin systray/status notifier)" ;;
    tiling-assistant*)                    echo "atalhos de tiling do xfwm4 (Super+setas), em Gerenciador de janelas → Teclado" ;;
    ding@*|desktop-icons*)                echo "ícones de área de trabalho do xfdesktop (nativos no Xfce)" ;;
    burn-my-windows*|compiz-*)            echo "compositor do xfwm4 — tem sombra e transparência, mas nada dos efeitos animados" ;;
    Bluetooth-Battery-Meter*|bluetooth-battery*) echo "blueman (mostra bateria de dispositivos pareados na bandeja)" ;;
    Battery-Health-Charging*)             echo "sem equivalente gráfico; limiar via /sys/class/power_supply/*/charge_control_end_threshold ou TLP" ;;
    emoji-copy*)                          echo "sem equivalente direto; use ibus-typing-booster ou um seletor de emoji avulso" ;;
    user-theme*)                           echo "não é necessário: no Xfce o tema é escolhido direto em Aparência" ;;
    apps-menu*|places-menu*|drive-menu*)  echo "plugins do xfce4-panel (whiskermenu, places, removable drives)" ;;
    system-monitor*)                       echo "xfce4-cpugraph-plugin / xfce4-systemload-plugin no painel" ;;
    *)                                     echo "sem equivalente conhecido — verifique manualmente" ;;
  esac
}

N_EXT=0
for e in $EXTS; do
  [ -z "$e" ] && continue
  N_EXT=$((N_EXT+1))
  achado QUEBRA "extensão \"$e\" deixa de existir" \
    "extensões são código do GNOME Shell; o Xfce não tem GNOME Shell" \
    "$(equivalente "$e")"
done
if [ "$N_EXT" -eq 0 ]; then
  achado OK "nenhuma extensão do GNOME habilitada" "nada a substituir no Xfce" "—"
else
  nota "$N_EXT extensão(ões) habilitada(s) — todas param de valer na sessão Xfce"
fi

# ============================================================= 5. atalhos =====
sec "5. Atalhos de teclado"
if tem gsettings; then
  CUSTOM="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo '@as []')"
  N_CUSTOM="$(echo "$CUSTOM" | grep -o 'custom[0-9]*' | sort -u | wc -l || true)"
  if [ "$N_CUSTOM" -gt 0 ]; then
    achado MUDA "$N_CUSTOM atalho(s) personalizado(s) do GNOME não migram" \
      "ficam no dconf do GNOME; o Xfce guarda atalhos no canal xfce4-keyboard-shortcuts" \
      "liste com: dconf dump /org/gnome/settings-daemon/plugins/media-keys/ e recrie em Configurações → Teclado do Xfce"
    if tem dconf; then
      nota "para conferir os comandos: dconf dump /org/gnome/settings-daemon/plugins/media-keys/"
    fi
  else
    achado OK "nenhum atalho personalizado no GNOME" "não há o que recriar" "—"
  fi
  achado MUDA "atalhos de janela e área de trabalho voltam ao padrão" \
    "org.gnome.desktop.wm.keybindings não é lido pelo xfwm4" \
    "o kali-themes traz xfce4-keyboard-shortcuts.xml com os atalhos do Kali — veja docs/guias/04-ambiente-xfce.md §4.3"
else
  nota "gsettings não encontrado — atalhos não verificáveis aqui"
fi

# ============================================================== 6. portais ====
sec "6. Compartilhamento de tela e portais xdg"
P_BASE=0; P_GNOME=0; P_GTK=0
inst xdg-desktop-portal       && P_BASE=1  || true
inst xdg-desktop-portal-gnome && P_GNOME=1 || true
inst xdg-desktop-portal-gtk   && P_GTK=1   || true
nota "instalados: xdg-desktop-portal=$P_BASE  -gnome=$P_GNOME  -gtk=$P_GTK"

if [ "$P_BASE" -eq 0 ]; then
  achado QUEBRA "xdg-desktop-portal não está instalado" \
    "sem o portal, apps em sandbox e chamadas de captura de tela não têm intermediário" \
    "sudo apt install xdg-desktop-portal xdg-desktop-portal-gtk"
elif [ "$P_GTK" -eq 0 ]; then
  achado QUEBRA "falta xdg-desktop-portal-gtk, que é o backend da sessão Xfce" \
    "o -gnome só é usado quando XDG_CURRENT_DESKTOP contém GNOME; no Xfce nada responderia ao portal" \
    "sudo apt install xdg-desktop-portal-gtk"
else
  achado MUDA "compartilhar tela passa a usar o backend GTK do portal" \
    "no Xfce quem atende é o xdg-desktop-portal-gtk, com diálogo e comportamento diferentes do GNOME" \
    "teste Slack/Meet/Teams logo na primeira sessão Xfce; no Xorg esses apps também podem capturar sem portal"
fi

# =============================================================== 7. polkit ====
sec "7. Autenticação gráfica (polkit)"
AG=""
for p in mate-polkit policykit-1-gnome polkit-gnome xfce-polkit lxpolkit lxqt-policykit; do
  inst "$p" && AG="$AG $p" || true
done
if [ -n "${AG// /}" ]; then
  achado OK "há agente gráfico de polkit instalado:${AG}" \
    "o Xfce precisa de um agente próprio, e ele já existe aqui" \
    "confirme que o agente sobe na sessão Xfce (Sessão e Inicialização → Autostart)"
else
  achado QUEBRA "nenhum agente gráfico de polkit instalado" \
    "no GNOME quem pede a senha é o próprio gnome-shell; o Xfce não tem substituto embutido" \
    "sudo apt install mate-polkit — sem ele, gnome-disks, synaptic, timeshift e afins não conseguem elevar privilégio"
fi

# ============================================================= 8. chaveiro ====
sec "8. Chaveiro (senhas de Slack, Chrome, Bitwarden…)"
if inst gnome-keyring; then
  if inst libpam-gnome-keyring; then
    achado MUDA "chaveiro destrava por PAM — confirme se trocar o gerenciador de login" \
      "gnome-keyring + libpam-gnome-keyring estão instalados e o GDM destrava no login" \
      "se você adotar o LightDM (docs/guias/08-boot-login-e-logos.md §8.4), confira /etc/pam.d/lightdm* por pam_gnome_keyring; senão os apps pedem a senha do chaveiro a cada início"
  else
    achado DEGRADA "gnome-keyring sem integração PAM" \
      "falta libpam-gnome-keyring; o chaveiro pode não destravar automaticamente" \
      "sudo apt install libpam-gnome-keyring"
  fi
else
  achado DEGRADA "gnome-keyring não está instalado" \
    "apps que usam libsecret (Slack, Chrome, DBeaver) guardariam segredos de forma degradada" \
    "sudo apt install gnome-keyring libpam-gnome-keyring"
fi

# ================================================= 9. serviços de sessão ======
sec "9. Serviços que o GNOME provê e o Xfce precisa instalar"
declare -A SERV=(
  [xfce4-notifyd]="daemon de notificações — sem ele, notificações de apps simplesmente não aparecem"
  [xfce4-screensaver]="bloqueio de tela e proteção de tela"
  [gvfs-backends]="montagem de rede, MTP, trash e volumes no Thunar"
  [gvfs-fuse]="acesso a volumes GVFS por caminho de arquivo (apps que não falam GIO)"
  [thunar-volman]="montagem automática de pendrive e mídia removível"
  [network-manager-gnome]="ícone de rede na bandeja (nm-applet) e diálogos de conexão"
  [blueman]="gerenciamento de Bluetooth na bandeja"
)
FALTAM=""
for p in "${!SERV[@]}"; do inst "$p" || FALTAM="$FALTAM $p"; done
if [ -n "${FALTAM// /}" ]; then
  for p in $FALTAM; do
    achado MUDA "falta $p" "no GNOME essa função é do gnome-shell/gnome-settings-daemon: ${SERV[$p]}" \
      "vem junto se você instalar o ambiente com ./kali-look.sh instalar xfce"
  done
else
  achado OK "todos os serviços de sessão do Xfce já estão instalados" \
    "notificação, bloqueio, gvfs, automount, rede e bluetooth cobertos" "—"
fi

# ========================================== 10. binários por servidor ========
sec "10. Ferramentas amarradas ao servidor gráfico"
for t in grim slurp wf-recorder wl-copy wl-paste ydotool wlr-randr swaybg swappy; do
  if tem "$t"; then achado QUEBRA "$t não funciona no Xorg" \
    "é ferramenta nativa de Wayland (protocolos wlroots/wayland)" \
    "equivalente no Xorg: $(case $t in
        grim|swappy) echo 'xfce4-screenshooter, scrot ou maim' ;;
        slurp) echo 'seleção de área do próprio xfce4-screenshooter' ;;
        wf-recorder) echo 'ffmpeg com x11grab, ou OBS' ;;
        wl-copy|wl-paste) echo 'xclip ou xsel' ;;
        ydotool) echo 'xdotool' ;;
        wlr-randr) echo 'xrandr / xfce4-display-settings' ;;
        swaybg) echo 'xfdesktop' ;;
      esac)"
  fi
done
MELHOROU=""
for t in xdotool xclip xsel wmctrl xcape autokey-gtk peek scrot maim import; do
  tem "$t" && MELHOROU="$MELHOROU $t" || true
done
if [ -n "${MELHOROU// /}" ]; then
  achado MELHORA "ferramentas X11 passam a funcionar de verdade:${MELHOROU}" \
    "no Wayland elas só alcançam janelas XWayland (ou nada); no Xorg voltam a ver toda a tela e o teclado" \
    "o peek, por exemplo, é gravador de tela X11-only e hoje não serve nesta sessão"
fi

# ================================================================ 11. OBS =====
sec "11. OBS Studio"
if inst obs-studio || tem obs; then
  CENAS="$HOME/.config/obs-studio/basic/scenes"
  if [ -d "$CENAS" ]; then
    PW="$(grep -lE 'pipewire|xdg_desktop_portal' "$CENAS"/*.json 2>/dev/null | tr '\n' ' ' || true)"
    if [ -n "${PW// /}" ]; then
      achado MUDA "há cenas com captura via PipeWire/portal" \
        "as fontes \"Captura de tela (PipeWire)\" dependem do portal do GNOME; no Xorg o OBS usa xshm/xcomposite" \
        "recrie as fontes como \"Captura de tela (XSHM)\" ou \"Captura de janela (Xcomposite)\" — cenas afetadas:$(echo " $PW" | sed "s|$CENAS/||g")"
    else
      achado OK "nenhuma cena do OBS usa PipeWire/portal" \
        "as fontes existentes não dependem do compositor Wayland" "—"
    fi
  else
    achado MUDA "OBS instalado, sem cenas configuradas ainda" \
      "no Xorg as fontes de captura são XSHM/Xcomposite, não PipeWire" \
      "ao criar a cena na sessão Xfce, escolha \"Captura de tela (XSHM)\""
  fi
else
  nota "OBS Studio não está instalado — nada a verificar"
fi

# ========================================================== 12. gestos =======
sec "12. Gestos de touchpad"
if inst touchegg || inst libinput-gestures || tem touchegg || tem libinput-gestures; then
  achado OK "há software de gestos instalado" \
    "touchegg/libinput-gestures cobre o que o mutter fazia nativamente" \
    "confirme que o daemon sobe na sessão Xfce"
elif [ -d /sys/class/input ] && grep -qiE 'touchpad|synaptics|elan' /proc/bus/input/devices 2>/dev/null; then
  achado DEGRADA "gestos de três dedos deixam de existir" \
    "no GNOME/Wayland os gestos são nativos do mutter; no Xfce/Xorg não há nada equivalente embutido" \
    "sudo apt install touchegg (ou libinput-gestures) e configure os gestos manualmente"
else
  nota "nenhum touchpad detectado em /proc/bus/input/devices — item não se aplica"
fi

# ====================================================== 13. luz noturna ======
sec "13. Luz noturna e cor da tela"
if tem gsettings; then
  NL="$(gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || echo '?')"
  nota "night-light-enabled: $NL"
  if [ "$NL" = "true" ]; then
    achado MUDA "luz noturna não existe no Xfce" \
      "é função do gnome-settings-daemon" \
      "sudo apt install redshift-gtk (ou gammastep) e configure o horário/temperatura"
  else
    achado OK "luz noturna está desligada" "nada a migrar" "—"
  fi
else
  nota "gsettings não encontrado — não verificável aqui"
fi

# ========================================================= 14. autostart =====
sec "14. Autostart restrito ao GNOME"
LISTA=""
for d in /etc/xdg/autostart "$HOME/.config/autostart"; do
  [ -d "$d" ] || continue
  while IFS= read -r f; do
    LISTA="$LISTA ${f/#$HOME/~}"
  done < <(grep -rl '^OnlyShowIn=.*GNOME' "$d" 2>/dev/null || true)
done
if [ -n "${LISTA// /}" ]; then
  # Três grupos: daemons internos do GNOME (o Xfce tem substituto próprio),
  # o chaveiro (importa de verdade) e o resto (terceiros, precisa olhar).
  N_GNOME=0; CHAVEIRO=""; OUTROS=""
  for f in $LISTA; do
    b="${f##*/}"
    case "$b" in
      org.gnome.SettingsDaemon.*|gnome-initial-setup*|tracker-miner*|orca-autostart*|\
      gnome-shell-overrides*|gnome-software-service*|update-notifier*)
        N_GNOME=$((N_GNOME+1)) ;;
      gnome-keyring-*)
        CHAVEIRO="$CHAVEIRO $b" ;;
      *)
        OUTROS="$OUTROS $b" ;;
    esac
  done

  if [ "$N_GNOME" -gt 0 ]; then
    achado OK "$N_GNOME daemons internos do GNOME não sobem — e não precisam" \
      "são org.gnome.SettingsDaemon.*, tracker, orca e afins; o Xfce usa os equivalentes dele (xfsettingsd, xfce4-power-manager, xfce4-notifyd)" \
      "nenhuma ação: substituição é o comportamento esperado"
  fi
  if [ -n "${CHAVEIRO// /}" ]; then
    achado DEGRADA "autostart do chaveiro é restrito ao GNOME:${CHAVEIRO}" \
      "esses .desktop têm OnlyShowIn com GNOME; no Xfce quem precisa iniciar o gnome-keyring é o PAM do gerenciador de login" \
      "com GDM + libpam-gnome-keyring o daemon já sobe no login; se algo pedir senha do chaveiro, copie o .desktop para ~/.config/autostart sem a linha OnlyShowIn"
  fi
  if [ -n "${OUTROS// /}" ]; then
    N_OUT="$(printf '%s\n' $OUTROS | wc -w)"
    achado MUDA "$N_OUT autostart(s) de terceiros restritos ao GNOME:${OUTROS}" \
      "têm OnlyShowIn=...GNOME... e o Xfce respeita esse campo, então não sobem" \
      "se algum for essencial, copie para ~/.config/autostart removendo a linha OnlyShowIn"
  fi
else
  achado OK "nenhum autostart restrito ao GNOME" "nada deixa de subir por causa de OnlyShowIn" "—"
fi

# ==================================================== 15. snaps e flatpaks ===
sec "15. Snaps e Flatpaks"
if tem snap; then
  SNAPS="$(snap list 2>/dev/null | awk 'NR>1 {print $1}' | grep -vE '^(core|core18|core20|core22|core24|bare|snapd|snapd-desktop-integration|gtk-common-themes|gnome-3-38-2004|gnome-42-2204|gnome-46-2404|mesa-2404|firmware-updater)$' | tr '\n' ' ' || true)"
  nota "snaps de aplicativo: ${SNAPS:-nenhum}"
  if [ -n "${SNAPS// /}" ]; then
    achado MUDA "snaps rodam, mas seguem ignorando o tema do Kali:${SNAPS}" \
      "snaps leem temas do próprio snap (gtk-common-themes), não de ~/.themes — isso vale em Wayland e em Xorg" \
      "para o Firefox snap: no Xorg ele roda em X11 nativamente, sem precisar de MOZ_ENABLE_WAYLAND"
  fi
else
  nota "snapd não encontrado"
fi
if tem flatpak; then
  FLAT="$(flatpak list --app --columns=application 2>/dev/null | tr '\n' ' ' || true)"
  if [ -n "${FLAT// /}" ]; then
    achado MUDA "flatpaks instalados:${FLAT}" \
      "usam o portal e o próprio runtime; o tema precisa ser exposto com flatpak override" \
      "flatpak override --user --filesystem=\$HOME/.themes:ro e GTK_THEME conforme necessário"
  else
    nota "nenhum flatpak de aplicativo instalado"
  fi
fi

# ================================================ 16. apps electron/chromium ==
sec "16. Aplicativos Electron e Chromium"
ELEC=""
for p in code brave-browser google-chrome-stable microsoft-edge-stable slack-desktop \
         bitwarden discord obsidian postman dbeaver-ce spotify-client teams-for-linux; do
  inst "$p" && ELEC="$ELEC $p" || true
done
if tem postman && [[ "$ELEC" != *postman* ]]; then ELEC="$ELEC postman(snap)"; fi
if [ -n "${ELEC// /}" ]; then
  nota "detectados:${ELEC}"
  if [ "$ACHOU_VAR" -eq 0 ]; then
    achado OK "Electron/Chromium seguem funcionando no Xorg" \
      "sem flag \"wayland\" fixada, eles usam X11 automaticamente — é o modo padrão desses apps" \
      "bônus: no Xorg a captura de tela desses apps não depende do portal, o que costuma resolver problema de compartilhar tela"
  else
    achado DEGRADA "Electron/Chromium com flag Wayland detectada" \
      "as flags encontradas na seção 3 forçam Wayland e impedem o app de subir no Xorg" \
      "remova as flags apontadas antes de entrar na sessão Xfce"
  fi
fi

# ================================================================ 17. disco ===
sec "17. Espaço em disco"
LIVRE_KB="$(df -Pk / | awk 'NR==2 {print $4}')"
LIVRE_GB=$((LIVRE_KB / 1024 / 1024))
USO="$(df -Ph / | awk 'NR==2 {print $5}')"
nota "/ com $LIVRE_GB GB livres ($USO em uso)"
if [ "$LIVRE_GB" -lt 5 ]; then
  achado QUEBRA "menos de 5 GB livres em /" \
    "instalar o Xfce (~400 MB) mais os assets (~95 MB) e o cache do apt pode encher o disco" \
    "libere espaço antes: sudo apt clean; sudo journalctl --vacuum-size=200M"
elif [ "$LIVRE_GB" -lt 15 ]; then
  achado DEGRADA "espaço apertado: $LIVRE_GB GB livres" \
    "cabe, mas sem folga para cache de apt e initramfs" \
    "considere sudo apt clean antes de instalar"
else
  achado OK "espaço suficiente: $LIVRE_GB GB livres" "Xfce + assets pedem cerca de 500 MB" "—"
fi

# ================================================================= resumo =====
TOTAL=$((N_QUEBRA + N_DEGRADA + N_MUDA + N_MELHORA + N_OK))
{
  printf '\n## Resumo\n\n'
  printf '| Severidade | Achados |\n|---|---|\n'
  printf '| QUEBRA | %s |\n' "$N_QUEBRA"
  printf '| DEGRADA | %s |\n' "$N_DEGRADA"
  printf '| MUDA | %s |\n' "$N_MUDA"
  printf '| MELHORA | %s |\n' "$N_MELHORA"
  printf '| OK | %s |\n' "$N_OK"
  printf '| **total** | **%s** |\n\n' "$TOTAL"
  printf 'Leitura recomendada: `docs/guias/13-wayland-vs-xorg.md` e `docs/guias/11-problemas-e-solucoes.md`.\n'
} >> "$MD"

if [ "$MOSTRAR" -eq 1 ]; then
  printf '\n%s== Resumo ==%s\n' "$C_BOLD$C_AZUL" "$C_RESET"
  printf '  %sQUEBRA %s%-3s%s  deixa de funcionar\n'      "$C_VERM"  "$C_BOLD" "$N_QUEBRA"  "$C_RESET"
  printf '  %sDEGRADA%s %s%-3s%s funciona pior\n'          "$C_AMBAR" "$C_RESET" "$C_BOLD" "$N_DEGRADA" "$C_RESET"
  printf '  %sMUDA   %s %s%-3s%s precisa reconfigurar\n'   "$C_AZUL"  "$C_RESET" "$C_BOLD" "$N_MUDA"    "$C_RESET"
  printf '  %sMELHORA%s %s%-3s%s melhora no Xorg\n'        "$C_VERDE" "$C_RESET" "$C_BOLD" "$N_MELHORA" "$C_RESET"
  printf '  %sOK     %s %s%-3s%s indiferente\n'            "$C_DIM"   "$C_RESET" "$C_BOLD" "$N_OK"      "$C_RESET"
  printf '  total: %s achados\n' "$TOTAL"
fi

if [ "$GRAVAR" -eq 1 ]; then
  mkdir -p "$REL_DIR"
  ARQ="$REL_DIR/analise-wayland-xorg-$(date +%Y%m%d-%H%M%S).md"
  cp "$MD" "$ARQ"
  if [ "$MOSTRAR" -eq 1 ]; then
    printf '\n  relatório salvo em: %s\n' "${ARQ/#$HOME/~}"
  else
    printf '%s\n' "$ARQ"
  fi
fi
