# Os conjuntos de wallpaper do Kali

Levantado em 2026-09-03, ao procurar alternativa ao `kali-cubes`.

## O pool tem nove conjuntos e dois pacotes vazios

`https://kali.download/kali/pool/main/k/kali-wallpapers/` publica, todos na
mesma versão (`2026.1.0` nesta data):

- por lançamento: `2026`, `2025`, `2024`, `2023`, `2022`, `2020.4`, `2019.4`
- `kali-wallpapers-legacy` (~126 MB, histórico do BackTrack em diante)
- `kali-wallpapers-mobile-2023` (proporção de celular, NetHunter)

**Cuidado com os dois de ~5 KB:** `kali-wallpapers-all` é metapacote (só
`Depends:` os oito de desktop) e `kali-legacy-wallpapers` é pacote de transição.
Nenhum dos dois contém imagem. Baixar um deles esperando wallpaper é o erro
óbvio, e o tamanho é a única pista.

## Onde as imagens caem

Todo conjunto instala em três lugares, e cada ambiente lê de um:

| Caminho no `.deb` | Para quê |
|---|---|
| `usr/share/backgrounds/kali/*.jpg\|png` | as imagens; é daqui que o Xfce e o GNOME leem |
| `usr/share/wallpapers/<Nome>/contents/images/` | pacote de wallpaper do Plasma |
| `usr/share/gnome-background-properties/kali-backgrounds_<ano>.xml` | faz o conjunto aparecer em *Configurações → Aparência* do GNOME |

`usr/share/backgrounds/kali-16x9/` vem vazio ou só com o link `default`.

## O que não cravar em script

A lista de conjuntos e a versão vêm do pool a cada execução
(`11-wallpapers-kali.sh`). Versão cravada em script é o que faz um runbook
envelhecer sem avisar — e aqui envelheceria a cada lançamento do Kali.

## Aplicar o fundo é diferente em cada ambiente

- Xfce: uma propriedade por monitor **e** por área de trabalho, em
  `xfce4-desktop` (`.../last-image`, `.../image-path`). Trocar só a primeira
  deixa o fundo antigo nos outros monitores.
- GNOME: `picture-uri` **e** `picture-uri-dark` — só a primeira não muda nada
  no tema escuro.
- Plasma: `plasma-apply-wallpaperimage` (vem em `plasma-workspace`).

Ver [[pacotes-do-kali]] para os `Breaks` que decidem o que é instalável aqui.
