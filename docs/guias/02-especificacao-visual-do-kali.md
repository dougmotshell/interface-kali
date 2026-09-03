# 2. Especificação visual do Kali Linux

Esta é a "planta" do visual. Cada valor abaixo saiu de um arquivo dentro dos
pacotes oficiais do Kali (versões 2026.3.x / wallpapers 2026.1.0). A coluna
*origem* diz de onde; os arquivos estão em `docs/referencia/`.

## 2.1 Identidade central

| Elemento | Valor no Kali | Origem |
|---|---|---|
| Tema GTK (Xfce) | `Kali-Dark` | `xsettings.xml`, `gtk-3.0/settings.ini` |
| Tema GTK (GNOME) | `adw-gtk3-dark` | `21_kali-themes.gschema.override` |
| Tema do GNOME Shell | `Kali-Dark` (extensão `user-theme`) | idem |
| Tema do xfwm4 (janelas) | `Kali-Dark` | `xfwm4.xml` |
| Tema de ícones | `Flat-Remix-Blue-Dark` | `xsettings.xml` / override |
| Tema de cursor | `Adwaita`, tamanho 24 | `xsettings.xml`, `Kali-Dark/index.theme` |
| Esquema de cor | `prefer-dark` | override |
| Variante clara | `Kali-Light` + `Flat-Remix-Blue-Light` | pacote `kali-themes-common` |

O pacote `kali-themes-common` traz, além do par Dark/Light, variantes de cor
(`Kali-Blue-*`, `Kali-Purple-*`, `Kali-Teal-*`, `Kali-Yellow-*`, `Kali-Slate-*`,
`Kali-Green-*`, `Kali-Red-*`, `Kali-Pink-*`, `Kali-Orange-*`) e as versões
`-xHiDPI` dos temas de janela. O padrão de fábrica é o `Kali-Dark`.

### Cores do tema Kali-Dark

Extraídas de `Kali-Dark/gtk-3.0/gtk.css` (as mais frequentes):

| Uso | Hex |
|---|---|
| Fundo mais escuro (barras, cabeçalhos) | `#0d0e11` |
| Fundo de janela / conteúdo | `#23252e` |
| Fundo alternativo / linhas | `#272a34`, `#242731`, `#303340` |
| Texto principal | `#eeeeec` |
| Texto secundário / desativado | `#888a8d` |
| **Azul de destaque (accent)** | `#2777ff` |
| Azul pressionado / seleção forte | `#005af3`, `#00348d` |
| Bordas | `#43495a` |

## 2.2 Tipografia

| Uso | Fonte |
|---|---|
| Interface (`font-name`) | `Cantarell 11` |
| Documentos (`document-font-name`) | `Cantarell 11` |
| Monoespaçada (`monospace-font-name`) | `Fira Code Medium 10` |
| Título de janela (xfwm4) | `Cantarell Bold 9` |
| Relógio do painel | `Cantarell 11` |
| Plugin genmon (IP da VPN) | `Fira Code Medium 8` |

Renderização (`xsettings.xml`): antialias ligado, `HintStyle=hintslight`,
`RGBA=rgb`.

## 2.3 Wallpapers e imagens

Pacote `kali-wallpapers-2026` instala em `/usr/share/backgrounds/kali/`:

| Arquivo | Papel |
|---|---|
| `kali-cubes-16x9.jpg` | **wallpaper padrão do desktop** |
| `kali-cubes2-16x9.jpg` | fundo da tela de login e de bloqueio |
| `kali-cubes-purple-16x9.jpg` | variante roxa (Kali Purple) |
| `kali-glitch-16x9.jpg`, `kali-hack-16x9.jpg`, `kali-net-16x9.jpg` | alternativos |
| `login-blurred`, `login.svg` | fundo desfocado do greeter |

Os apontamentos "oficiais" ficam em `/usr/share/desktop-base/kali-theme/`, que
é só uma camada de symlinks:

```
wallpaper/gnome-background.xml  -> /usr/share/backgrounds/kali/kali-cubes.xml
lockscreen/gnome-background.xml -> /usr/share/backgrounds/kali/kali-cubes2.xml
login/background                -> /usr/share/backgrounds/kali/kali-cubes2-16x9.jpg
plymouth                        -> /usr/share/plymouth/themes/kali
grub/grub-16x9.png              -> /usr/share/grub/themes/kali/grub-16x9.png
```

E `/usr/share/backgrounds/kali-16x9/default -> kali-cubes.jpg -> ../kali/kali-cubes-16x9.jpg`
é o caminho que o Xfce usa como papel de parede.

### Logos (`/usr/share/images/kali-logos/`)

`logo.svg`, `logo-text.svg`, `logo-text-version.svg` e os PNGs em 64/128/256 px
de cada um. O `logo-text-128.png` é o que aparece na tela de login do GDM; o
dragão em `kali-dragon-icon.svg` (pacote `kali-defaults-desktop`) é o ícone da
página inicial do navegador.

O ícone do menu do painel é `kali-panel-menu` (existe dentro do próprio tema de
ícones, em `Flat-Remix-Blue-Dark/apps/scalable/kali-panel-menu.svg`).

## 2.4 Painel do Xfce (o traço mais reconhecível)

De `docs/referencia/painel/xfce4-panel-default.xml`:

- **Um único painel no topo**, `position=p=6;x=0;y=0`, largura 100%, altura 34 px,
  posição travada.
- Ordem dos plugins:

| # | Plugin | Detalhe |
|---|---|---|
| 1 | `whiskermenu` | menu principal, ícone `kali-panel-menu` |
| 2 | `separator` | |
| 3 | `showdesktop` | |
| 4 | `directorymenu` | ícone `system-file-manager` |
| 5 | `launcher` | editor de texto |
| 6 | `launcher` | navegador |
| 7 | `launcher` | terminal (+ terminal root, + pwsh) |
| 8 | `separator` | |
| 9 | `pager` | 4 áreas de trabalho, sem miniatura |
| 10 | `separator` | |
| 11 | `tasklist` | **sem rótulos**, agrupado |
| 12 | `separator` | expansível (empurra o resto para a direita) |
| 13 | `cpugraph` | gradiente azul `#2777ff` → ciano `#00e0e0` |
| 14 | `systray` | ícones de 22 px, quadrados, não simbólicos |
| 15 | `genmon` | script `xfce4-panel-genmon-vpnip.sh` (IP da VPN), fonte Fira Code Medium 8 |
| 16 | `pulseaudio` | |
| 17 | `notification-plugin` | |
| 18 | `power-manager-plugin` | |
| 19 | `clock` | digital, formato `%_H:%M`, Cantarell 11 |
| 20-21 | `separator` | |
| 22 | `actions` | só `lock-screen` e `logout` visíveis |

O mesmo layout está empacotado como perfil pronto em
`docs/referencia/painel/Kali.tar.bz2` (e `Kali compact.tar.bz2`, a variante de painel
fino de 28 px), carregáveis com `xfce4-panel-profiles`.

### Whisker Menu (`docs/referencia/painel/whiskermenu-defaults.rc`)

`menu-width=570`, `menu-height=700`, ícones de item tamanho 2 e de categoria 1,
categorias e perfil em posição alternada, troca de categoria ao passar o mouse,
sem descrição nos lançadores, e apenas os comandos "configurações" e "logout"
visíveis. Os favoritos do Kali apontam para itens de pentest — no nosso caso
substitua por terminal, arquivos, editor e navegador.

## 2.5 Gerenciador de janelas (xfwm4)

| Propriedade | Valor |
|---|---|
| `theme` | `Kali-Dark` |
| `button_layout` | `O|HMC` (menu à esquerda; ocultar/maximizar/fechar à direita) |
| `title_font` | `Cantarell Bold 9` |
| `easy_click` | `Super` |
| `workspace_count` | 4 |
| `borderless_maximize` | false |

No GNOME o equivalente é `button-layout = 'appmenu:minimize,maximize,close'`.

## 2.6 Desktop do Xfce

Ícones de área de trabalho ativos (`style=2`), tamanho 48 px, mostrando Home,
sistema de arquivos, removíveis e lixeira; papel de parede
`/usr/share/backgrounds/kali-16x9/default` com estilo 5 (*zoomed*).

No GNOME (extensão `ding`) o Kali faz o oposto: ícones `small`, **sem** home,
lixeira ou volumes.

## 2.7 Terminal

Paleta de 16 cores idêntica no `xfce4-terminal`, `gnome-terminal`, `tilix`,
`qterminal`, `alacritty` e `terminator`:

```
#1F2229  #D41919  #5EBDAB  #FEA44C  #367BF0  #9755B3  #49AEE6  #E6E6E6
#198388  #EC0101  #47D4B9  #FF8A18  #277FFF  #962AC3  #05A1F7  #FFFFFF
```

Mais: fundo transparente com `BackgroundDarkness=0.95` (5% de transparência),
cores herdadas do tema (`ColorUseTheme=TRUE`), `bold-is-bright`, histórico
ilimitado e `confirm-close=false`.

## 2.8 Prompt do shell

O `/etc/skel/.zshrc` do Kali (copiado em `docs/referencia/shell/kali-zshrc`) define o
prompt de duas linhas com o símbolo `㉿`:

```
┌──(usuário㉿máquina)-[~/caminho]
└─$
```

Verde para usuário comum, vermelho/`#` para root, caminho abreviado após 6
níveis, linha em branco antes de cada prompt (`NEWLINE_BEFORE_PROMPT=yes`) e as
alternativas `twoline` (padrão), `oneline` e `backtrack`.

## 2.9 Login, boot e integração Qt

| Camada | Configuração do Kali |
|---|---|
| GDM (sabor GNOME) | `org/gnome/login-screen logo='/usr/share/images/kali-logos/logo-text-128.png'` |
| LightDM (sabor Xfce) | tema `Kali-Light`, ícones `Flat-Remix-Blue-Light`, fonte Cantarell 11, fundo `desktop-base/kali-theme/login/background`, relógio `%d %b, %H:%M`, avatar `#emblem-kali` |
| Plymouth (boot) | tema `kali` (`/usr/share/plymouth/themes/kali`) |
| GRUB | `GRUB_THEME=/boot/grub/themes/kali/theme.txt`, `GRUB_GFXMODE=1280x720,1280x800,auto`, `splash` no cmdline |
| Apps Qt | `QT_QPA_PLATFORMTHEME=qt5ct` + configs `qt5ct`/`qt6ct` apontando para o tema |
| Editores | esquema de cor `Kali-Dark` no gedit, GNOME Text Editor e Mousepad (estilos em `/usr/share/gtksourceview-{3.0,4,5}/styles/`) |
| Monitor do sistema | paleta própria de 12 cores por CPU, `mem-color=#B8174C`, `net-in=#367BF0`, `net-out=#D41919` |

## 2.10 Extensões do GNOME no sabor GNOME do Kali

`apps-menu`, `dash-to-dock`, `ProxySwitcher`, `ding`, `user-theme`,
`ubuntu-appindicators`, `tiling-assistant`, `system-monitor`, `drive-menu`,
`places-menu`, `top-panel-vpnip@kali.org`.

Ajustes do dock: `custom-theme-shrink=false`, `show-trash=false`,
`running-indicator-style='DOTS'`, `disable-overview-on-startup=true`.

## 2.11 KDE Plasma (sabor `kali-desktop-kde`)

O Kali mantém um sabor Plasma com tema global próprio. Valores de
`kali-themes-common` e dos arquivos em `/usr/share/kali-themes/etc/xdg/`:

| Elemento | Valor |
|---|---|
| Tema global (*look and feel*) | `org.kali.kalidark.desktop` (há `kalilight`, `kalipurpledark`, `kalipurplelight`) |
| Esquema de cores | `KaliDark` (`/usr/share/color-schemes/KaliDark.colors`) |
| Tema do Plasma (*desktop theme*) | `kali` (`plasmarc: name=kali`, com o ícone `start.svgz` do dragão) |
| Estilo de widgets | `Breeze` |
| Decoração de janela | `library=org.kali.kali`, `theme=Kali` (do pacote **`kwin-style-kali`**) |
| Botões da decoração | esquerda `M` (menu); direita `IAX` (minimizar, maximizar, fechar) |
| Tema de ícones | `Flat-Remix-Blue-Dark` |
| Fonte monoespaçada | `Fira Code, 10` |
| Áreas de trabalho | 2 |
| Konsole | perfil padrão `Kali-Dark.profile`, esquema `Kali-Dark.colorscheme` |
| Tela de bloqueio | `/usr/share/desktop-base/kali-theme/login/background` |
| Wallpaper | pacote `KaliCubes` |
| SDDM | tema `breeze` |

Cores do esquema `KaliDark` (RGB, de `kdeglobals`):

| Papel | RGB | Hex |
|---|---|---|
| Fundo de janela/visão/botão | `35,37,46` | `#23252E` |
| Texto normal | `255,255,255` | `#FFFFFF` |
| Texto inativo | `92,98,108` | `#5C626C` |
| Destaque/foco/link | `39,119,255` | `#2777FF` |
| Seleção alternativa | `43,98,192` | `#2B62C0` |
| Positivo | `25,161,135` | `#19A187` |
| Neutro | `253,125,0` | `#FD7D00` |
| Negativo | `212,25,25` | `#D41919` |
| Ativo (realce de texto) | `74,174,230` | `#4AAEE6` |

Aplicativos do sabor Plasma: `konsole`, `dolphin`, `kate`, `gwenview`,
`dragonplayer`, `ark`, `kcalc`, `okular`, `plasma-systemmonitor`,
`kde-spectacle`, `plasma-nm`, com `sddm` + `sddm-theme-breeze` no login.
