# 5. Ambiente 2 — KDE Plasma

O Kali mantém um sabor Plasma (`kali-desktop-kde`) com tema global próprio,
`org.kali.kalidark.desktop`. Aqui a fidelidade é boa, mas há **uma limitação
estrutural** que precisa estar clara antes de começar.

Tempo estimado: 40–50 min. Espaço: ~700 MB (Plasma) + ~95 MB (assets).

## 5.1 A limitação: Plasma 5 aqui, Plasma 6 no Kali

| | Kali atual | Ubuntu 24.04 |
|---|---|---|
| Plasma | 6.x (Qt 6) | **5.27.12 (Qt 5)** |
| KWin | `kwin-x11`/`kwin-wayland` 6.x | 5.27.11 |
| Decoração de janela do Kali | pacote `kwin-style-kali` | **não existe** |

Consequência prática: a **decoração de janela** do Kali (`library=org.kali.kali`,
`theme=Kali`) é um plugin C++ compilado contra o KDecoration da versão 6. Não
existe no Ubuntu 24.04 e o `.deb` do Kali não carrega no Plasma 5. Você usará a
decoração **Breeze** com as cores KaliDark — a diferença fica nos cantos e na
espessura da barra de título, não nas cores.

Todo o resto é declarativo e funciona:

| Componente | Formato | Funciona no Plasma 5.27? |
|---|---|---|
| Esquema de cores `KaliDark` | `.colors` (INI) | Sim |
| Tema do Plasma `kali` | pacote SVG, `X-Plasma-API: 5.0` | Sim |
| Tema global `org.kali.kalidark.desktop` | `Plasma/LookAndFeel` | Sim (ele só aponta para os outros) |
| Ícones `Flat-Remix-Blue-Dark` | tema de ícones | Sim |
| Perfil/esquema do Konsole | INI | Sim |
| Decoração `Kali` | plugin binário Qt6 | **Não** |

Se decoração idêntica for indispensável, o caminho honesto é o Xfce (ambiente 1),
não o Plasma.

## 5.2 Instalar o Plasma

```bash
sudo apt install --no-install-recommends \
  kde-plasma-desktop plasma-desktop plasma-workspace kwin-x11 \
  plasma-nm plasma-pa powerdevil kscreen \
  konsole dolphin kate gwenview ark kcalc okular \
  plasma-systemmonitor kde-spectacle breeze breeze-gtk-theme \
  systemsettings kde-config-gtk-style
```

`kde-plasma-desktop` é o conjunto mínimo do Plasma no Debian/Ubuntu — evita
arrastar todo o `kubuntu-desktop`.

Sobre o gerenciador de login: o Kali usa **SDDM** no sabor Plasma. Instalar
`sddm` no Ubuntu **substitui o GDM** (o `apt` pergunta qual usar), e isso muda a
tela de login de *todas* as sessões, inclusive a sua sessão GNOME. Recomendação:
**não instale o SDDM**. O GDM lista a sessão "Plasma (X11)" sem problema.

Depois de instalar, a sessão aparece em `/usr/share/xsessions/plasmax11.desktop`
(e `plasma.desktop` em `wayland-sessions`, se você instalar `kwin-wayland`).

## 5.3 Instalar os assets do Kali

Para o Plasma, **prefira o modo B** (`dpkg -i`, veja
`03-obter-os-assets-oficiais.md`). O Plasma procura temas globais, esquemas de
cor e temas de área de trabalho em caminhos padronizados, e os arquivos do Kali
usam caminhos absolutos.

Se quiser manter tudo por usuário, os destinos são:

```
~/.local/share/plasma/look-and-feel/org.kali.kalidark.desktop/
~/.local/share/plasma/desktoptheme/kali/
~/.local/share/color-schemes/KaliDark.colors
~/.local/share/konsole/Kali-Dark.{profile,colorscheme}
~/.local/share/icons/Flat-Remix-Blue-Dark/
~/.local/share/wallpapers/KaliCubes/
```

## 5.4 Aplicar o tema global

Na sessão Plasma:

```bash
# tema global (aplica esquema de cores, ícones, tema do Plasma e wallpaper)
plasma-apply-lookandfeel -a org.kali.kalidark.desktop

# se preferir aplicar peça por peça:
plasma-apply-colorscheme KaliDark
plasma-apply-desktoptheme kali
plasma-apply-wallpaperimage /usr/share/wallpapers/KaliCubes/
```

Ícones, fontes e decoração pelo `kwriteconfig5`:

```bash
kwriteconfig5 --file kdeglobals --group Icons  --key Theme  Flat-Remix-Blue-Dark
kwriteconfig5 --file kdeglobals --group General --key fixed "Fira Code,10,-1,5,50,0,0,0,0,0,Regular"
kwriteconfig5 --file kdeglobals --group General --key font  "Cantarell,11,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file kdeglobals --group KDE     --key widgetStyle Breeze

# decoração: Breeze escuro com os botões na ordem do Kali
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft  M
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight IAX
kwriteconfig5 --file kwinrc --group Desktops --key Number 2

qdbus org.kde.KWin /KWin reconfigure
```

(No Plasma 6 os comandos seriam `kwriteconfig6`/`plasma-apply-*` iguais; aqui é
5.27, então `kwriteconfig5`.)

Alternativa manual, sem comandos: copie os arquivos de `docs/referencia/kde/` para
`~/.config/` (`kdeglobals`, `kwinrc`, `plasmarc`, `konsolerc`,
`kscreenlockerrc`) **com a sessão Plasma fechada**, trocando antes
`library=org.kali.kali` por `library=org.kde.breeze` em `kwinrc`.

## 5.5 Painel

O layout do painel do Kali no Plasma é o painel padrão do Plasma com dois
ajustes, feitos pelo script
`docs/referencia/kde/kali-panel-customizations.js`:

1. o ícone do menu (`org.kde.plasma.kickoff`) passa a ser `kali-panel-menu-large`
   — o dragão;
2. os lançadores fixos do `org.kde.plasma.icontasks` passam a ser Dolphin, Kate,
   Firefox ESR e Konsole.

Para rodar o mesmo ajuste aqui:

```bash
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  "$(cat docs/referencia/kde/kali-panel-customizations.js)"
```

Se o `evaluateScript` não estiver disponível, faça pela interface: clique direito
no menu → *Configurar* → ícone → escolher `kali-panel-menu-large`.

O painel do Kali fica **embaixo**, com a altura padrão do Plasma, relógio digital
em duas linhas (hora + data) e bandeja à direita — é o padrão do Plasma, não
precisa de ajuste.

## 5.6 Konsole

```bash
mkdir -p ~/.local/share/konsole
cp docs/referencia/kde/Kali-Dark.profile \
   docs/referencia/kde/Kali-Dark.colorscheme \
   ~/.local/share/konsole/
kwriteconfig5 --file konsolerc --group "Desktop Entry" --key DefaultProfile Kali-Dark.profile
```

Depois, no Konsole: *Configurações → Editar perfil atual → Aparência* e confirme
o esquema `Kali-Dark`, mais 5% de transparência em *Plano de fundo*.

## 5.7 Tela de bloqueio

```bash
kwriteconfig5 --file kscreenlockerrc \
  --group Greeter --group Wallpaper --group org.kde.image --group General \
  --key Image /usr/share/desktop-base/kali-theme/login/background
```

## 5.8 Aplicativos GTK dentro do Plasma

Instale `kde-config-gtk-style` e, em *Configurações do sistema → Aparência →
Estilo de aplicativos → GNOME/GTK*, escolha o tema `Kali-Dark` e os ícones
`Flat-Remix-Blue-Dark`. Sem isso, apps GTK ficam claros dentro do Plasma escuro.

## 5.9 Atalho: script

Os passos 5.4 a 5.7 estão automatizados em `scripts/30-aplicar-plasma.sh` — rode-o
**dentro da sessão Plasma**.

## 5.10 Verificação

- [ ] Tema global "Kali-Dark" listado em *Aparência → Tema global*
- [ ] Fundo de janela `#23252E` e seleção azul `#2777FF`
- [ ] Ícone do dragão no menu do painel
- [ ] Ícones Flat-Remix azuis no Dolphin
- [ ] Konsole com a paleta do Kali e o prompt de duas linhas
- [ ] Duas áreas de trabalho
- [ ] Barra de título com menu à esquerda e minimizar/maximizar/fechar à direita

Diferença esperada: a decoração é Breeze, não a `Kali` — cantos e altura de
barra de título ligeiramente diferentes.
