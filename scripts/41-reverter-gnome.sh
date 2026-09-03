#!/usr/bin/env bash
# Reverte a aparência do Kali no GNOME.
#
# Duas estratégias, nesta ordem:
#   1. se houver backup de scripts/00-backup.sh, restaura os valores que a
#      máquina tinha antes (é o único jeito de acertar o tema original, que
#      varia por distribuição: Yaru no Ubuntu, Adwaita no Debian, etc.);
#   2. sem backup, usa `gsettings reset`, que devolve o padrão compilado do
#      schema — não crava valores de nenhuma distribuição específica.
#
# Uso: bash 41-reverter-gnome.sh
set -euo pipefail

STATE_DIR="$HOME/.local/state/kali-look-backup"
BACKUP_TXT=""
if [ -d "$STATE_DIR" ]; then
  # o backup mais recente que tenha o inventário de aparência
  for d in $(ls -1d "$STATE_DIR"/*/ 2>/dev/null | sort -r); do
    if [ -f "$d/aparencia-antes.txt" ]; then BACKUP_TXT="$d/aparencia-antes.txt"; break; fi
  done
fi

if [ -n "$BACKUP_TXT" ]; then
  echo "== restaurando do backup: $BACKUP_TXT =="
else
  echo "== sem backup encontrado em $STATE_DIR — usando gsettings reset =="
fi

# Restaura uma chave do backup; se não estiver lá, reseta ao padrão do schema.
restaura() {
  local schema="$1" chave="$2" val=""
  if [ -n "$BACKUP_TXT" ]; then
    val="$(grep -F "$schema $chave = " "$BACKUP_TXT" 2>/dev/null | head -1 | sed "s/^$schema $chave = //")"
  fi
  if [ -n "$val" ] && [ "$val" != "?" ]; then
    if gsettings set "$schema" "$chave" "$val" 2>/dev/null; then
      printf '  %-22s <- backup  %s\n' "$chave" "$val"; return 0
    fi
  fi
  gsettings reset "$schema" "$chave" 2>/dev/null || true
  printf '  %-22s <- padrão do schema\n' "$chave"
}

echo "== tema, ícones, fontes =="
for k in gtk-theme icon-theme cursor-theme font-name document-font-name \
         monospace-font-name color-scheme; do
  restaura org.gnome.desktop.interface "$k"
done

echo "== shell, janelas e fundo =="
gsettings set org.gnome.shell.extensions.user-theme name '' 2>/dev/null || true
gsettings reset org.gnome.desktop.wm.preferences button-layout
restaura org.gnome.desktop.background picture-uri
gsettings reset org.gnome.desktop.background picture-uri-dark
gsettings reset org.gnome.desktop.background picture-options
gsettings reset org.gnome.desktop.screensaver picture-uri
gsettings reset org.gnome.desktop.screensaver picture-options

echo "== dock e extensões =="
# ubuntu-dock só existe no Ubuntu; em outras distros o dock do Kali é o
# dash-to-dock e não há nada a reativar no lugar dele.
if gnome-extensions list 2>/dev/null | grep -q '^ubuntu-dock@ubuntu.com$'; then
  gnome-extensions enable  ubuntu-dock@ubuntu.com        2>/dev/null || true
  gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
  echo "  ubuntu-dock reativado, dash-to-dock desativado"
else
  echo "  ubuntu-dock não existe aqui — dash-to-dock mantido como está"
fi
gsettings reset-recursively org.gnome.shell.extensions.dash-to-dock 2>/dev/null || true
gsettings reset-recursively org.gnome.shell.extensions.ding         2>/dev/null || true

for e in apps-menu places-menu drive-menu system-monitor; do
  gnome-extensions disable "$e@gnome-shell-extensions.gcampax.github.com" 2>/dev/null || true
done

echo "== terminal =="
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

echo
echo "GNOME revertido. Faça logout/login para o shell voltar ao tema padrão."
echo "Lembre de remover o bloco do prompt Kali do ~/.zshrc, se você o adicionou"
echo "(ou rode: scripts/kali-look.sh prompt remover)."
if [ -z "$BACKUP_TXT" ]; then
  echo
  echo "Sem backup, as chaves voltaram ao padrão do schema — que pode não ser o"
  echo "tema que você usava. Rode scripts/00-backup.sh antes de aplicar, na"
  echo "próxima vez."
fi
