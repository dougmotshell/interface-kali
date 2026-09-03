# Capturas — antes e depois

## O que são estas imagens

| Arquivo | Conteúdo |
|---|---|
| `1-antes-ubuntu-gnome.png` | O estado atual: Ubuntu 24.04 / GNOME 46 / Yaru-purple-dark |
| `2-depois-xfce-kali.png` | Como fica no ambiente **Xfce** com os temas do Kali |
| `3-depois-plasma-kali.png` | Como fica no ambiente **KDE Plasma** com o tema global do Kali |
| `4-depois-gnome-kali.png` | Como fica no ambiente **GNOME** revestido de Kali |
| `assets/kali-plasma-preview-oficial.jpg` | Imagem oficial do Kali, extraída do pacote `kali-themes-common` (preview do tema global Plasma) |

**Importante: as quatro primeiras são simulações, não fotografias da tela.**

Elas foram montadas em HTML e renderizadas em 1600×900, usando os elementos
reais extraídos dos pacotes oficiais do Kali:

- o wallpaper `kali-cubes-16x9.jpg` (de `kali-wallpapers-2026`);
- os ícones do tema `Flat-Remix-Blue-Dark` e o logo do dragão
  (`kali-panel-menu.svg`, de `kali-themes-common`);
- as cores exatas dos temas (`#0d0e11`, `#23252e`, `#2777ff`) e a paleta de 16
  cores do terminal;
- as fontes Cantarell e Fira Code;
- o prompt de duas linhas com `㉿`;
- para a imagem "antes", as configurações lidas da máquina de referência do guia
  01 (Yaru-purple-dark, dock embaixo) e os ícones Yaru do próprio Ubuntu.

O que elas mostram fielmente: paleta, tipografia, ícones, wallpaper, disposição
do painel/barra/dock e densidade da interface. O que elas **não** garantem:
sombras, cantos arredondados, animações e o pixel exato de cada widget — isso só
aparece na sua máquina depois de aplicar.

Os fontes HTML estão em `html/`. Para regerar após editar:

```bash
cd docs/capturas
for f in 1-antes-ubuntu-gnome 2-depois-xfce-kali 3-depois-plasma-kali 4-depois-gnome-kali; do
  google-chrome --headless=new --disable-gpu --hide-scrollbars \
    --window-size=1600,900 --screenshot="$PWD/$f.png" "file://$PWD/html/$f.html"
done
```

## Tirando a sua própria captura real

Vale registrar o "antes" de verdade antes de mexer no sistema. O GNOME 46 em
Wayland bloqueia captura por linha de comando (a API `org.gnome.Shell.Screenshot`
responde `AccessDenied`, e o `grim` exige um compositor wlroots), então use a
interface:

- tecle **Print** para abrir o utilitário de captura do GNOME (tela inteira,
  janela ou área) — o arquivo vai para `~/Imagens/Capturas de tela/`;
- ou instale um utilitário: `sudo apt install gnome-screenshot` e depois
  `gnome-screenshot -f docs/capturas/antes-real.png`.

Na sessão Xfce (Xorg), o `xfce4-screenshooter` funciona por linha de comando:

```bash
xfce4-screenshooter -f -s docs/capturas/depois-real.png
```

E no Plasma, `spectacle -f -b -o arquivo.png`.

## Licenças dos assets

O wallpaper, o logo do dragão, os ícones Flat-Remix e Yaru e as duas fontes vêm
de terceiros e mantêm as licenças de origem (GPL-3.0+, CC-BY-SA-4.0 e OFL 1.1).
A relação completa, arquivo por arquivo, está em
[`CREDITOS.md`](CREDITOS.md) — leia antes de redistribuir estas imagens.

## Referência visual oficial

Para comparar com o Kali de verdade, além da imagem do pacote:

- <https://www.kali.org/> — capturas na página inicial
- <https://www.kali.org/docs/introduction/> — documentação com telas
- <https://www.kali.org/blog/> — os anúncios de release mostram o desktop novo a
  cada versão

As imagens do Kali são do Kali Devel Team, licenciadas em GPL-3.0+ (veja
`usr/share/doc/kali-themes-common/copyright` dentro do pacote).
