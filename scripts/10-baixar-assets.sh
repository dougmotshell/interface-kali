#!/usr/bin/env bash
# Baixa os pacotes de aparência do Kali e (opcionalmente) instala os arquivos.
#
# Uso:
#   bash 10-baixar-assets.sh                     # só baixa e extrai em ~/.cache/kali-assets
#   bash 10-baixar-assets.sh --instalar-usuario  # copia para o $HOME (reversível, recomendado)
#   bash 10-baixar-assets.sh --instalar-sistema  # dpkg -i (necessário p/ GRUB, Plymouth, GDM)
#   bash 10-baixar-assets.sh --help
#
# Variáveis de ambiente (para fixar ou atualizar versões sem editar o script):
#   KALI_THEMES_VER      versão de kali-themes-common     (padrão 2026.3.0)
#   KALI_WALLPAPERS_VER  versão de kali-wallpapers-2026    (padrão 2026.1.0)
#   ADW_GTK3_VER         versão de adw-gtk3-kali           (padrão 2026.2.0)
#   KALI_WALLPAPERS_PKG  nome do pacote de wallpapers      (padrão kali-wallpapers-2026)
#   KALI_MIRROR          base do pool                      (padrão https://kali.download/kali/pool/main)
#   KALI_ASSETS_CACHE    onde baixar/extrair               (padrão ~/.cache/kali-assets)
#
# Para descobrir versões novas, liste o diretório do pool:
#   curl -sL https://kali.download/kali/pool/main/k/kali-themes/ | grep -oE 'href="[^"]+\.deb"'
#
# NÃO adiciona repositório do Kali ao APT.
set -euo pipefail

BASE="${KALI_MIRROR:-https://kali.download/kali/pool/main}"
CACHE="${KALI_ASSETS_CACHE:-$HOME/.cache/kali-assets}"
STAGE="$CACHE/extraido"
MODO="${1:-}"

KALI_THEMES_VER="${KALI_THEMES_VER:-2026.3.0}"
KALI_WALLPAPERS_PKG="${KALI_WALLPAPERS_PKG:-kali-wallpapers-2026}"
KALI_WALLPAPERS_VER="${KALI_WALLPAPERS_VER:-2026.1.0}"
ADW_GTK3_VER="${ADW_GTK3_VER:-2026.2.0}"

DEBS=(
  "$BASE/k/kali-themes/kali-themes-common_${KALI_THEMES_VER}_all.deb"
  "$BASE/k/kali-wallpapers/${KALI_WALLPAPERS_PKG}_${KALI_WALLPAPERS_VER}_all.deb"
  "$BASE/a/adw-gtk3-kali/adw-gtk3-kali_${ADW_GTK3_VER}_all.deb"
)

if [ "$MODO" = "--help" ] || [ "$MODO" = "-h" ]; then
  sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  echo "Pacotes que serão baixados:"
  printf '  %s\n' "${DEBS[@]}"
  exit 0
fi

mkdir -p "$CACHE" "$STAGE"
cd "$CACHE"

echo "== baixando =="
for u in "${DEBS[@]}"; do
  f="${u##*/}"
  if [ -s "$f" ]; then echo "  já existe: $f"; continue; fi
  echo "  $f"
  curl -fL --retry 3 --max-time 600 -o "$f" "$u"     # -L é obrigatório (redireciona p/ espelho)
done
sha256sum ./*.deb > SHA256SUMS.txt
echo "  checksums em $CACHE/SHA256SUMS.txt"

echo "== extraindo =="
for f in ./*.deb; do dpkg-deb -x "$f" "$STAGE"; done
echo "  em $STAGE"

case "$MODO" in
  --instalar-usuario)
    echo "== instalando no \$HOME =="
    mkdir -p "$HOME/.themes" "$HOME/.local/share/icons" \
             "$HOME/.local/share/backgrounds/kali" "$HOME/.local/share/kali-logos" \
             "$HOME/.local/share/wallpapers"

    for t in Kali-Dark Kali-Light adw-gtk3 adw-gtk3-dark; do
      [ -d "$STAGE/usr/share/themes/$t" ] && cp -a "$STAGE/usr/share/themes/$t" "$HOME/.themes/"
    done
    for i in Flat-Remix-Blue-Dark Flat-Remix-Blue-Light Adwaita+Flat-Remix-Blue; do
      [ -d "$STAGE/usr/share/icons/$i" ] && cp -a "$STAGE/usr/share/icons/$i" "$HOME/.local/share/icons/"
    done
    cp -aL "$STAGE"/usr/share/backgrounds/kali/*.jpg "$HOME/.local/share/backgrounds/kali/" 2>/dev/null || true
    cp -a  "$STAGE"/usr/share/images/kali-logos/*    "$HOME/.local/share/kali-logos/"        2>/dev/null || true
    cp -a  "$STAGE"/usr/share/wallpapers/KaliCubes*  "$HOME/.local/share/wallpapers/"        2>/dev/null || true

    for v in 3.0 4 5; do
      s="$STAGE/usr/share/gtksourceview-$v/styles"
      [ -d "$s" ] && mkdir -p "$HOME/.local/share/gtksourceview-$v/styles" \
        && cp -a "$s"/* "$HOME/.local/share/gtksourceview-$v/styles/"
    done

    # Plasma (só tem efeito se você usar a sessão Plasma)
    mkdir -p "$HOME/.local/share/plasma" "$HOME/.local/share/color-schemes" "$HOME/.local/share/konsole"
    cp -a "$STAGE"/usr/share/plasma/*                "$HOME/.local/share/plasma/"        2>/dev/null || true
    cp -a "$STAGE"/usr/share/color-schemes/*.colors  "$HOME/.local/share/color-schemes/" 2>/dev/null || true
    cp -a "$STAGE"/usr/share/konsole/*               "$HOME/.local/share/konsole/"       2>/dev/null || true

    gtk-update-icon-cache -q -f "$HOME/.local/share/icons/Flat-Remix-Blue-Dark" 2>/dev/null || true
    echo "  ok — temas em ~/.themes, ícones em ~/.local/share/icons"
    ;;
  --instalar-sistema)
    echo "== instalando com dpkg (pede sudo) =="
    sudo dpkg -i "$CACHE/${KALI_WALLPAPERS_PKG}_${KALI_WALLPAPERS_VER}_all.deb" \
                 "$CACHE/kali-themes-common_${KALI_THEMES_VER}_all.deb" || true
    # adw-gtk3-kali declara Breaks: libgtk-4-1 (<< 4.16); no Ubuntu 24.04 (GTK4 4.14)
    # instalamos o tema no $HOME em vez de forçar o dpkg
    mkdir -p "$HOME/.themes"
    for t in adw-gtk3 adw-gtk3-dark; do
      [ -d "$STAGE/usr/share/themes/$t" ] && cp -a "$STAGE/usr/share/themes/$t" "$HOME/.themes/"
    done
    sudo gtk-update-icon-cache -q -f /usr/share/icons/Flat-Remix-Blue-Dark 2>/dev/null || true
    echo "  ok — arquivos em /usr/share, adw-gtk3* em ~/.themes"
    ;;
  "")
    echo "Nada instalado. Rode de novo com --instalar-usuario ou --instalar-sistema."
    ;;
  *)
    echo "Opção desconhecida: $MODO"; exit 1 ;;
esac
