#!/usr/bin/env bash
# 11-wallpapers-kali.sh — todos os conjuntos de wallpaper oficiais do Kali, não
# só o do ano corrente.
#
# Uso:
#   bash 11-wallpapers-kali.sh listar                 # conjuntos, tamanho, estado
#   bash 11-wallpapers-kali.sh baixar CONJUNTO...     # ou: baixar todos
#   bash 11-wallpapers-kali.sh instalar CONJUNTO...   # copia para o $HOME
#   bash 11-wallpapers-kali.sh galeria [--html]       # o que está instalado
#   bash 11-wallpapers-kali.sh aplicar NOME|CAMINHO|--aleatorio
#   bash 11-wallpapers-kali.sh escolher               # lista numerada e aplica
#
# CONJUNTO é o ano (2026, 2025, …, 2019.4) ou `legacy`; `todos` baixa o que o
# metapacote kali-wallpapers-all declara.
#
# O que este script existe para resolver:
#
# 1. `10-baixar-assets.sh` traz UM conjunto (kali-wallpapers-2026, o do ano) —
#    é o que a aparência padrão precisa. Quem não gosta do kali-cubes fica sem
#    alternativa, e as outras estão todas no mesmo pool.
# 2. A lista de conjuntos e a versão NÃO estão cravadas aqui: são lidas do pool
#    a cada execução. Cravar versão em script é o que faz um runbook envelhecer
#    sem avisar.
# 3. `kali-wallpapers-all` e `kali-legacy-wallpapers` têm ~5 KB: são
#    metapacote e pacote de transição, não contêm imagem nenhuma. Baixá-los
#    esperando wallpaper é erro fácil de cometer.
# 4. `kali-wallpapers-legacy` tem ~130 MB (todo o histórico do BackTrack em
#    diante). O tamanho é mostrado antes de baixar, e `todos` pede confirmação.
#
# NÃO adiciona repositório do Kali ao APT nem instala pacote com dpkg: os
# arquivos são extraídos do `.deb` e copiados para o $HOME.
set -euo pipefail

BASE="${KALI_MIRROR:-https://kali.download/kali/pool/main}"
POOL="$BASE/k/kali-wallpapers/"
CACHE="${KALI_ASSETS_CACHE:-$HOME/.cache/kali-assets}/wallpapers"
STAGE="$CACHE/extraido"
DEST_IMG="$HOME/.local/share/backgrounds/kali"
DEST_KDE="$HOME/.local/share/wallpapers"
DRY_RUN="${DRY_RUN:-0}"

if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_VERDE=$'\033[38;5;42m'; C_AMBAR=$'\033[38;5;214m'; C_VERM=$'\033[38;5;160m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_VERDE=""; C_AMBAR=""; C_VERM=""
fi
ok()    {
  if [ "$DRY_RUN" -eq 1 ]; then
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

# Metapacote e pacote de transição: aparecem no pool, não trazem imagem.
SEM_IMAGEM="kali-wallpapers-all kali-legacy-wallpapers"

# O 10-baixar-assets.sh já pode ter baixado o conjunto do ano no diretório pai;
# um .deb em cache serve para saber o que o conjunto contém sem baixar de novo.
CACHE_PAI="${KALI_ASSETS_CACHE:-$HOME/.cache/kali-assets}"
deb_em_cache() {
  local arquivo="$1" d
  for d in "$CACHE" "$CACHE_PAI"; do
    [ -s "$d/$arquivo" ] && { printf '%s' "$d/$arquivo"; return 0; }
  done
  return 1
}

# "pacote|arquivo.deb" para cada pacote de wallpaper do pool, com a maior versão
# de cada. Sem rede, cai no que já está em cache. O resultado é memoizado: um
# `instalar todos` consultaria o pool uma vez por conjunto sem isto.
POOL_MEMO=""
pool_lista() {
  if [ -n "$POOL_MEMO" ]; then printf '%s\n' "$POOL_MEMO"; return 0; fi
  POOL_MEMO="$(pool_lista_crua)"
  printf '%s\n' "$POOL_MEMO"
}

pool_lista_crua() {
  local html arquivo pacote
  html="$(curl -sL --max-time 60 "$POOL" 2>/dev/null || true)"
  if [ -z "$html" ]; then
    for arquivo in "$CACHE"/*.deb "$CACHE_PAI"/*wallpapers*.deb; do
      [ -e "$arquivo" ] || continue
      arquivo="${arquivo##*/}"
      printf '%s|%s\n' "${arquivo%%_*}" "$arquivo"
    done | sort -u
    return 0
  fi
  # nome de pacote tem `_`, `.` e maiúscula: regex de caractere solto não casa
  printf '%s' "$html" | grep -oE 'href="[^"]+\.deb"' | sed 's/href="//;s/"//' \
    | sort -V | while read -r arquivo; do
        pacote="${arquivo%%_*}"
        printf '%s|%s\n' "$pacote" "$arquivo"
      done | awk -F'|' '{u[$1]=$2} END{for (p in u) print p "|" u[p]}' | sort
}

# "2026" -> kali-wallpapers-2026 ; "legacy" -> kali-wallpapers-legacy
nome_pacote() {
  case "$1" in
    kali-wallpapers-*|kali-legacy-wallpapers) printf '%s' "$1" ;;
    *) printf 'kali-wallpapers-%s' "$1" ;;
  esac
}

rotulo() { printf '%s' "${1#kali-wallpapers-}"; }

tamanho_remoto() {
  local url="$1" bytes
  bytes="$(curl -sIL --max-time 30 "$url" 2>/dev/null \
    | grep -i '^content-length' | tail -1 | tr -dc '0-9' || true)"
  [ -n "$bytes" ] || { printf '?'; return 0; }
  if [ "$bytes" -gt 1048576 ]; then printf '%s MB' "$((bytes / 1048576))"
  else printf '%s KB' "$((bytes / 1024))"; fi
}

# Quantas imagens de um conjunto já estão no $HOME. A lista de nomes vem do
# .deb em cache ou do diretório extraído — sem uma das duas coisas não há como
# saber a que conjunto uma imagem pertence, e aí a resposta honesta é "?".
instalado_de() { # pacote arquivo.deb -> "N" ou "?"
  local pacote="$1" arquivo="${2:-}" n=0 nomes="" f deb
  if [ -d "$STAGE/$pacote/usr/share/backgrounds" ]; then
    nomes="$(find "$STAGE/$pacote/usr/share/backgrounds" -type f -printf '%f\n' 2>/dev/null || true)"
  elif deb="$(deb_em_cache "$arquivo")"; then
    nomes="$(dpkg-deb -c "$deb" 2>/dev/null \
      | awk '$6 ~ /^\.\/usr\/share\/backgrounds\/.+[^\/]$/ {n=split($6,a,"/"); print a[n]}' || true)"
  else
    printf '?'; return 0
  fi
  [ -n "$nomes" ] || { printf '0'; return 0; }
  while read -r f; do
    [ -n "$f" ] || continue
    { [ -e "$DEST_IMG/$f" ] || [ -e "/usr/share/backgrounds/kali/$f" ]; } && n=$((n + 1))
  done <<< "$nomes"
  printf '%s' "$n"
}

# ----------------------------------------------------------------- listar -----
cmd_listar() {
  etapa "Conjuntos de wallpaper oficiais do Kali"
  local par pacote arquivo tam est n
  local sem_rede=0
  curl -sL --max-time 20 -o /dev/null "$POOL" 2>/dev/null || sem_rede=1
  [ "$sem_rede" -eq 1 ] && aviso "sem acesso ao pool: mostrando só o que já está em cache"
  printf '  %-14s %-9s %-12s %s\n' "CONJUNTO" "TAMANHO" "CACHE" "INSTALADO NO \$HOME"
  while IFS='|' read -r pacote arquivo; do
    [ -n "${pacote:-}" ] || continue
    case " $SEM_IMAGEM " in *" $pacote "*) continue ;; esac
    local deb=""
    deb="$(deb_em_cache "$arquivo" || true)"
    if [ -n "$deb" ]; then est="baixado"; tam="$(du -h "$deb" | cut -f1)"
    elif [ "$sem_rede" -eq 1 ]; then est="—"; tam="?"
    else est="—"; tam="$(tamanho_remoto "$POOL$arquivo")"; fi
    n="$(instalado_de "$pacote" "$arquivo")"
    case "$n" in
      0) n="—" ;;
      \?) n="? (sem o .deb para conferir)" ;;
      *) n="$n imagem(ns)" ;;
    esac
    printf '  %-14s %-9s %-12s %s\n' "$(rotulo "$pacote")" "$tam" "$est" "$n"
  done < <(pool_lista)
  echo
  info "Metapacote e transição ficam fora da lista (não trazem imagem):"
  info "  $SEM_IMAGEM"
  echo
  info "Baixar e instalar um conjunto:  bash 11-wallpapers-kali.sh instalar 2019.4"
  info "Ver o que já está instalado:    bash 11-wallpapers-kali.sh galeria --html"
}

# ----------------------------------------------------------------- baixar -----
resolve_conjuntos() {
  local alvo pacote par p a
  if [ "$#" -eq 0 ]; then morre "diga o conjunto: 2026, 2025, …, 2019.4, legacy ou todos"; fi
  for alvo in "$@"; do
    if [ "$alvo" = "todos" ]; then
      while IFS='|' read -r p a; do
        [ -n "${p:-}" ] || continue
        case " $SEM_IMAGEM " in *" $p "*) continue ;; esac
        printf '%s|%s\n' "$p" "$a"
      done < <(pool_lista)
      continue
    fi
    pacote="$(nome_pacote "$alvo")"
    par="$(pool_lista | grep "^$pacote|" || true)"
    [ -n "$par" ] || morre "conjunto desconhecido: $alvo (veja: 11-wallpapers-kali.sh listar)"
    printf '%s\n' "$par"
  done
}

cmd_baixar() {
  local pares; pares="$(resolve_conjuntos "$@")"
  etapa "Baixando"
  mkdir -p "$CACHE" "$STAGE"
  local pacote arquivo
  while IFS='|' read -r pacote arquivo; do
    [ -n "${pacote:-}" ] || continue
    local deb=""
    deb="$(deb_em_cache "$arquivo" || true)"
    if [ -n "$deb" ]; then
      info "  já em cache: $deb"
      [ "$deb" = "$CACHE/$arquivo" ] || run cp -n "$deb" "$CACHE/$arquivo"
    else
      info "  $arquivo ($(tamanho_remoto "$POOL$arquivo"))"
      # -L é obrigatório: o pool redireciona para espelho e sem ele o .deb sai
      # com 0 byte, sem erro visível
      run curl -fL -# --retry 3 --max-time 900 -o "$CACHE/$arquivo" "$POOL$arquivo"
    fi
    if [ "$DRY_RUN" -eq 0 ]; then
      [ -s "$CACHE/$arquivo" ] || morre "$arquivo saiu vazio — tente de novo"
      rm -rf "$STAGE/$pacote"
      mkdir -p "$STAGE/$pacote"
      dpkg-deb -x "$CACHE/$arquivo" "$STAGE/$pacote"
    fi
    ok "$(rotulo "$pacote") extraído em $STAGE/$pacote"
  done <<< "$pares"
  if [ "$DRY_RUN" -eq 0 ]; then
    ( cd "$CACHE" && sha256sum ./*.deb > SHA256SUMS.txt 2>/dev/null || true )
  fi
}

# --------------------------------------------------------------- instalar -----
cmd_instalar() {
  cmd_baixar "$@"
  etapa "Instalando no \$HOME"
  local pares; pares="$(resolve_conjuntos "$@")"
  run mkdir -p "$DEST_IMG" "$DEST_KDE"
  local pacote arquivo origem n=0
  while IFS='|' read -r pacote arquivo; do
    [ -n "${pacote:-}" ] || continue
    origem="$STAGE/$pacote/usr/share/backgrounds"
    if [ -d "$origem" ]; then
      # cp -a do conteúdo de cada subdiretório: kali/ tem as imagens 16x9,
      # kali-16x9/ costuma trazer só o link `default`
      local sub
      for sub in "$origem"/*; do
        [ -d "$sub" ] || continue
        run cp -an "$sub"/. "$DEST_IMG/" 2>/dev/null || true
      done
      n=$((n + 1))
    else
      aviso "$(rotulo "$pacote") não traz /usr/share/backgrounds — nada a copiar"
    fi
    if [ -d "$STAGE/$pacote/usr/share/wallpapers" ]; then
      run cp -an "$STAGE/$pacote/usr/share/wallpapers"/. "$DEST_KDE/" 2>/dev/null || true
    fi
  done <<< "$pares"
  ok "$n conjunto(s) copiado(s) para $DEST_IMG"
  info "O que ficou disponível:  bash 11-wallpapers-kali.sh galeria"
  info "Aplicar um:              bash 11-wallpapers-kali.sh escolher"
}

# ---------------------------------------------------------------- galeria -----
# Imagens instaladas, um caminho por linha. Só formato que dá para pôr no fundo.
imagens_instaladas() {
  local d f
  for d in "$DEST_IMG" /usr/share/backgrounds/kali; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      [ -f "$f" ] || continue
      case "${f,,}" in *.jpg|*.jpeg|*.png|*.webp) printf '%s\n' "$f" ;; esac
    done
  done | sort -u
}

cmd_galeria() {
  local html=0
  [ "${1:-}" = "--html" ] && html=1
  local imgs; imgs="$(imagens_instaladas)"
  [ -n "$imgs" ] || morre "nenhum wallpaper instalado — bash 11-wallpapers-kali.sh instalar todos"
  if [ "$html" -eq 0 ]; then
    etapa "Wallpapers instalados"
    local i=1 f
    while read -r f; do
      printf '  %3d) %-42s %s%s%s\n' "$i" "$(basename "$f")" "$C_DIM" "$(dirname "$f")" "$C_RESET"
      i=$((i + 1))
    done <<< "$imgs"
    echo
    info "Aplicar:  bash 11-wallpapers-kali.sh aplicar <nome ou número>"
    return 0
  fi

  # Página local com as miniaturas. É o único jeito de "olhar antes de escolher"
  # sem depender de visualizador de imagem instalado — e o GNOME em Wayland não
  # deixa nem tirar captura por linha de comando.
  local pag="$CACHE/galeria.html"
  mkdir -p "$CACHE"
  {
    printf '<!doctype html><meta charset="utf-8"><title>Wallpapers do Kali instalados</title>\n'
    printf '<style>body{margin:0;background:#1f2229;color:#e6e6e6;font:14px system-ui,sans-serif}'
    printf 'h1{font-size:18px;padding:16px 20px;margin:0;border-bottom:1px solid #367bf0}'
    printf '.g{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:14px;padding:20px}'
    printf 'figure{margin:0;background:#262a33;border-radius:8px;overflow:hidden}'
    printf 'img{width:100%%;display:block;aspect-ratio:16/9;object-fit:cover}'
    printf 'figcaption{padding:8px 10px;font-size:12px;line-height:1.5;word-break:break-all}'
    printf 'code{color:#5ebdab}</style>\n'
    printf '<h1>Wallpapers do Kali instalados nesta máquina</h1><div class="g">\n'
    local f b
    while read -r f; do
      b="$(basename "$f")"
      printf '<figure><img src="file://%s" alt="%s" loading="lazy">' "$f" "$b"
      printf '<figcaption>%s<br><code>aplicar %s</code></figcaption></figure>\n' "$b" "${b%.*}"
    done <<< "$imgs"
    printf '</div>\n'
  } > "$pag"
  ok "galeria em $pag"
  if command -v xdg-open >/dev/null 2>&1; then
    run xdg-open "$pag" >/dev/null 2>&1 || aviso "abra o arquivo à mão: $pag"
  fi
}

# ---------------------------------------------------------------- aplicar -----
# Resolve nome parcial, número da galeria ou caminho para um arquivo existente.
resolve_imagem() {
  local alvo="$1" imgs achado
  imgs="$(imagens_instaladas)"
  if [ -f "$alvo" ]; then printf '%s' "$alvo"; return 0; fi
  case "$alvo" in
    --aleatorio) printf '%s' "$(printf '%s' "$imgs" | shuf -n1)"; return 0 ;;
  esac
  if printf '%s' "$alvo" | grep -qE '^[0-9]+$'; then
    achado="$(printf '%s\n' "$imgs" | sed -n "${alvo}p")"
    [ -n "$achado" ] || morre "não há wallpaper número $alvo (veja: galeria)"
    printf '%s' "$achado"; return 0
  fi
  achado="$(printf '%s\n' "$imgs" | grep -i -- "$alvo" | head -1 || true)"
  [ -n "$achado" ] || morre "nenhum wallpaper instalado casa com \"$alvo\""
  printf '%s' "$achado"
}

cmd_aplicar() {
  [ "$#" -ge 1 ] || morre "uso: 11-wallpapers-kali.sh aplicar NOME|NÚMERO|CAMINHO|--aleatorio"
  local img; img="$(resolve_imagem "$1")"
  etapa "Aplicando $(basename "$img")"
  local feito=0
  case "${XDG_CURRENT_DESKTOP:-}" in
    *[Xx][Ff][Cc][Ee]*)
      command -v xfconf-query >/dev/null 2>&1 || morre "xfconf-query não encontrado"
      # cada monitor e cada área de trabalho tem a sua própria propriedade; sem
      # `|| true` o grep sem correspondência abortaria o script sob pipefail
      local props p
      props="$(xfconf-query -c xfce4-desktop -l 2>/dev/null \
        | grep -E 'last-image$|image-path$' || true)"
      [ -n "$props" ] || aviso "nenhuma propriedade de fundo no xfce4-desktop ainda"
      while read -r p; do
        [ -n "$p" ] && run xfconf-query -c xfce4-desktop -p "$p" -s "$img"
      done <<< "$props"
      feito=1
      ;;
    *[Kk][Dd][Ee]*)
      if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
        run plasma-apply-wallpaperimage "$img"; feito=1
      else
        aviso "plasma-apply-wallpaperimage não encontrado (pacote plasma-workspace)"
      fi
      ;;
    *[Gg][Nn][Oo][Mm][Ee]*|*[Uu][Bb][Uu][Nn][Tt][Uu]*)
      command -v gsettings >/dev/null 2>&1 || morre "gsettings não encontrado"
      run gsettings set org.gnome.desktop.background picture-uri "file://$img"
      run gsettings set org.gnome.desktop.background picture-uri-dark "file://$img"
      feito=1
      ;;
  esac
  if [ "$feito" -eq 0 ]; then
    aviso "sessão ${XDG_CURRENT_DESKTOP:-?} não reconhecida; o caminho é:"
    info "  $img"
    return 1
  fi
  ok "fundo: $img"
}

# --------------------------------------------------------------- escolher -----
cmd_escolher() {
  local imgs; imgs="$(imagens_instaladas)"
  [ -n "$imgs" ] || morre "nenhum wallpaper instalado — bash 11-wallpapers-kali.sh instalar todos"
  cmd_galeria
  local r
  read -r -p "$(printf '%snúmero (Enter=cancela, h=abrir galeria no navegador):%s ' "$C_BOLD" "$C_RESET")" r || return 0
  case "${r:-}" in
    "") info "cancelado"; return 0 ;;
    h|H) cmd_galeria --html; return 0 ;;
  esac
  cmd_aplicar "$r"
}

case "${1:-}" in
  listar)   shift; cmd_listar ;;
  baixar)   shift; cmd_baixar "$@" ;;
  instalar) shift; cmd_instalar "$@" ;;
  galeria)  shift; cmd_galeria "$@" ;;
  aplicar)  shift; cmd_aplicar "$@" ;;
  escolher) shift; cmd_escolher ;;
  *) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
