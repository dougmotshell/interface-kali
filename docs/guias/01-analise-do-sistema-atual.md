# 1. A máquina de referência

Todo valor deste guia foi medido em **uma** máquina, em 3 de setembro de 2026 — a
máquina onde este material foi escrito e validado. Ela não é a sua: serve para
você saber sob quais premissas as conclusões dos outros guias valem, e para
comparar com o que a sua reporta.

O equivalente da sua máquina sai de dois comandos, e é o primeiro passo
recomendado:

```bash
scripts/kali-look.sh status              # aparência, assets, sessões, fontes
scripts/50-analise-wayland-xorg.sh       # o que muda ao sair do Wayland
```

Se a sua base divergir muito do que está abaixo — outra versão de Ubuntu, outro
desktop, outro gerenciador de login — leia o guia 09 antes de aplicar qualquer
coisa: parte das ressalvas depende dessas premissas.

## 1.1 Sistema e sessão gráfica

| Item | Valor detectado |
|---|---|
| Distribuição | Ubuntu 24.04.4 LTS (Noble Numbat) |
| Kernel | 7.0.0-30-generic |
| Desktop | GNOME Shell 46.0 (`XDG_CURRENT_DESKTOP=ubuntu:GNOME`) |
| Servidor gráfico | Wayland (`XDG_SESSION_TYPE=wayland`) |
| Gerenciador de login | GDM 3 (`/usr/sbin/gdm3`) |
| Sessões disponíveis | `ubuntu.desktop`, `ubuntu-xorg.desktop`, `ubuntu-wayland.desktop` |
| Shell do usuário | `/usr/bin/zsh` (há `~/.zshrc` e `~/.bashrc` próprios) |
| Terminal | `gnome-terminal` |

Confira o seu espaço livre com `df -h /` antes de começar: o material pede ~95 MB
de assets, mais ~400 MB se você instalar o Xfce ou ~700 MB no caso do Plasma.

## 1.2 Aparência atual

| Item | Valor |
|---|---|
| Tema GTK | `Yaru-purple-dark` |
| Tema de ícones | `Yaru-purple` |
| Tema de cursor | `Yaru` |
| Fonte de interface | `Ubuntu Sans 11` |
| Fonte monoespaçada | `Ubuntu Sans Mono 13` |
| Tema do gerenciador de janelas | `Adwaita` |
| Temas instalados | apenas variantes `Yaru*` e `Adwaita*` |
| Ícones instalados | `Yaru*`, `Adwaita`, `Humanity*`, cursores DMZ |

Nenhum tema, ícone ou wallpaper do Kali está presente — tudo será adicionado.

## 1.3 Extensões do GNOME ativas

Na máquina de referência (`gnome-extensions list --enabled` mostra as suas):
`bluetooth-battery`, `emoji-copy`, `ubuntu-dock`, `dash-to-dock`,
`Bluetooth-Battery-Meter`, `clipboard-indicator`, `ubuntu-appindicators`,
`tiling-assistant`.

A lista importa por dois motivos: extensões concorrem entre si dentro do GNOME, e
**nenhuma delas existe** fora do GNOME Shell — o guia 13 trata do que acontece
com cada uma numa sessão Xfce ou Plasma.

Dois pontos relevantes para o ambiente GNOME:

- **`dash-to-dock` já está instalado** (em `~/.local/share/gnome-shell/extensions/`).
  É exatamente a extensão que o Kali usa no sabor GNOME — não precisa instalar nada.
- `ubuntu-dock` está ativo em paralelo. Os dois no ar ao mesmo tempo brigam pelo
  mesmo espaço; no guia do GNOME o `ubuntu-dock` é desativado.

Também já estão instaladas extensões de efeito (`burn-my-windows`,
`compiz-windows-effect`, `compiz-alike-magic-lamp-effect`) que não existem no
Kali. Elas não impedem nada, mas afastam o resultado do visual original —
considere desativá-las durante a comparação.

## 1.4 Fontes

As fontes do Kali **não** estão instaladas com os nomes exatos que ele usa:

- `Cantarell` — ausente. Está disponível no Ubuntu como `fonts-cantarell` (0.303.1-1).
- `Fira Code Medium` — ausente. Há `FiraCode Nerd Font` instalada, que é uma
  variante *patched* com nome diferente; o pacote oficial é `fonts-firacode` (6.2-2).

Ou seja: as duas fontes do Kali vêm dos repositórios normais do Ubuntu, não é
preciso pegar nada do Kali para isso.

## 1.5 Pacotes já verificados nos repositórios do Ubuntu 24.04

Disponíveis (versão candidata):

`xfce4` 4.18 · `xfce4-whiskermenu-plugin` 2.8.3 · `xfce4-genmon-plugin` 4.1.1 ·
`xfce4-cpugraph-plugin` 1.2.10 · `xfce4-panel-profiles` 1.0.14 · `xfce4-terminal` 1.1.3 ·
`thunar` 4.18.8 · `mousepad` 0.6.1 · `qterminal` 1.4.0 · `lightdm` 1.30 ·
`lightdm-gtk-greeter` 2.0.9 · `fonts-cantarell` · `fonts-firacode` ·
`gtk2-engines-pixbuf` · `plymouth-label` · `dconf-cli` · `gnome-shell-extensions` 46.1 ·
`cherrytree` 1.1.2

Do lado KDE: `kde-plasma-desktop` 5:146 · `plasma-desktop` 4:5.27.12 ·
`kwin-x11` 4:5.27.11 · `konsole` 23.08.5 · `dolphin` 23.08.5 ·
`plasma-nm` · `plasma-systemmonitor` · `kde-spectacle` · `breeze` ·
`sddm` + `sddm-theme-breeze`

**Não** disponíveis no Ubuntu 24.04:

- `gnome-shell-extension-dashtodock` — irrelevante, a extensão já está instalada
  localmente pelo usuário.
- `adw-gtk3` — o tema GTK3 que o Kali usa no GNOME. Vem do `.deb`
  `adw-gtk3-kali` (137 KB), tratado em `03-obter-os-assets-oficiais.md`.
- `kwin-style-kali` — a decoração de janela do sabor Plasma do Kali. É um
  plugin binário para Plasma 6; não há versão para o Plasma 5.27 do Ubuntu.
- `gnome-shell-extension-system-monitor` e `gnome-shell-extension-vpnip` —
  o primeiro faz parte de `gnome-shell-extensions` no Ubuntu 46 (confirme com
  `gnome-extensions list`); o segundo é específico do Kali e depende de rede VPN,
  logo é opcional.

## 1.6 Implicações práticas

1. **Xfce e Plasma rodam em Xorg.** As sessões novas aparecem no GDM e usam Xorg; sua
   sessão GNOME Wayland continua disponível na mesma tela de login.
2. **Versão do Xfce.** Ubuntu 24.04 traz Xfce 4.18; o Kali atual usa 4.20. Os
   temas Kali-Dark funcionam nos dois, mas há diferenças pequenas de espaçamento
   e de opções no painel.
3. **Versão do Plasma.** O Ubuntu 24.04 traz Plasma **5.27 (Qt 5)**, enquanto o
   Kali já usa Plasma 6. Cores, ícones, tema do Plasma e perfis do Konsole são
   declarativos e funcionam; a decoração de janela do Kali (`kwin-style-kali`) é
   um plugin binário para Plasma 6 e **não** tem equivalente aqui. Detalhes em
   `05-ambiente-kde-plasma.md`.
4. **Versão do GNOME.** O tema de shell `Kali-Dark` acompanha o GNOME do Kali
   (48/49). No GNOME 46 daqui ele carrega e estiliza o essencial — o CSS já
   contém as regras de *quick settings* — mas pode haver detalhes fora de lugar.
5. **Espaço.** Assets do Kali ocupam ~95 MB descompactados (55 MB só o tema de
   ícones `Flat-Remix-Blue-Dark`). Com o Xfce completo, some ~400 MB; com o
   Plasma, ~700 MB. Confira com `df -h /` antes de instalar um ambiente inteiro.
6. **Snaps.** Aplicativos snap (ex.: Firefox no Ubuntu) não leem temas de
   `~/.themes`; ficarão fora do tema até você usar as versões `.deb`/Flatpak ou
   fazer o *bind* de tema para o snap.
