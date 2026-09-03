#!/usr/bin/env bash
# Guarda o estado visual atual antes de qualquer mudança.
# Uso: bash 00-backup.sh
set -euo pipefail

DEST="$HOME/.local/state/kali-look-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEST"
echo "Backup em: $DEST"

# dconf completo (GNOME, extensões, terminal)
dconf dump / > "$DEST/dconf-completo.ini"

# valores individuais mais importantes, para conferência rápida
{
  echo "# gerado em $(date -Is)"
  for k in gtk-theme icon-theme cursor-theme font-name document-font-name \
           monospace-font-name color-scheme; do
    printf 'org.gnome.desktop.interface %s = %s\n' "$k" \
      "$(gsettings get org.gnome.desktop.interface "$k" 2>/dev/null || echo '?')"
  done
  printf 'org.gnome.desktop.wm.preferences theme = %s\n' \
    "$(gsettings get org.gnome.desktop.wm.preferences theme 2>/dev/null || echo '?')"
  printf 'org.gnome.desktop.background picture-uri = %s\n' \
    "$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null || echo '?')"
  printf 'org.gnome.shell enabled-extensions = %s\n' \
    "$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo '?')"
} > "$DEST/aparencia-antes.txt"

# arquivos de configuração que os guias tocam
for p in .config/xfce4 .config/kdeglobals .config/kwinrc .config/plasmarc \
         .config/konsolerc .config/gtk-3.0 .config/gtk-4.0 .zshrc .bashrc .face; do
  [ -e "$HOME/$p" ] && cp -a "$HOME/$p" "$DEST/" 2>/dev/null || true
done

# arquivos de sistema relevantes (só leitura)
mkdir -p "$DEST/sistema"
for p in /etc/default/grub /etc/default/grub.d /etc/lightdm \
         /etc/dconf/db/gdm.d /etc/X11/default-display-manager; do
  [ -e "$p" ] && cp -a "$p" "$DEST/sistema/" 2>/dev/null || true
done

# inventário
dpkg -l | awk '/^ii/{print $2, $3}' > "$DEST/pacotes.txt"
{ ls /usr/share/themes; echo "---"; ls /usr/share/icons; } > "$DEST/temas-e-icones.txt"
update-alternatives --query default.plymouth 2>/dev/null | head -5 \
  > "$DEST/plymouth-atual.txt" || true

echo "Pronto. Para restaurar o dconf inteiro:"
echo "  dconf load / < $DEST/dconf-completo.ini"
