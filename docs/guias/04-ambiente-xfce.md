# 4. Ambiente 1 — Xfce (o desktop padrão do Kali)

Este é o ambiente de maior fidelidade: o desktop padrão do Kali **é** o Xfce 4
com os temas Kali. Instalamos o Xfce como sessão paralela, aplicamos as
configurações originais do Kali e passamos a escolher no GDM se queremos entrar
no "Ubuntu" ou no "Xfce".

O GNOME atual não é alterado em nada.

Tempo estimado: 30–40 min. Espaço: ~400 MB (Xfce) + ~95 MB (assets).

## 4.1 Pré-requisitos

1. Assets do Kali instalados — `03-obter-os-assets-oficiais.md`. Para este
   ambiente, prefira o **modo B** (`dpkg -i`): os arquivos de configuração do
   Xfce do Kali citam caminhos absolutos em `/usr/share`, e assim funcionam sem
   edição.
2. Fontes: `sudo apt install fonts-cantarell fonts-firacode`.
3. Backup do estado atual: `scripts/00-backup.sh`.

## 4.2 Instalar o Xfce e os plugins que o Kali usa

A lista abaixo é o `Depends`/`Recommends` de `kali-desktop-xfce` filtrado para o
que existe no Ubuntu 24.04 e para o que tem efeito visual (nada de ferramentas
de pentest):

```bash
sudo apt install --no-install-recommends \
  xfce4 xfce4-goodies xfce4-terminal xfce4-notifyd xfce4-screensaver \
  xfce4-whiskermenu-plugin xfce4-genmon-plugin xfce4-cpugraph-plugin \
  xfce4-pulseaudio-plugin xfce4-power-manager-plugins xfce4-taskmanager \
  xfce4-screenshooter xfce4-panel-profiles xfce4-clipman-plugin \
  thunar thunar-archive-plugin thunar-volman ristretto parole mousepad \
  network-manager-gnome nm-connection-editor blueman \
  mate-polkit gvfs-backends gvfs-fuse \
  xdg-user-dirs-gtk gtk2-engines-pixbuf dconf-cli
```

`xfce4-goodies` já traz vários plugins de painel de uma vez. Se algum pacote não
existir na sua versão, o `apt` aborta a linha inteira: rode
`apt-cache policy <pacote>` e remova o que não tiver candidato.

Seis desses pacotes não são enfeite — eles cobrem funções que hoje vêm do GNOME
Shell e que **não existem** numa sessão Xfce:

| Pacote | Por que está aqui |
|---|---|
| `mate-polkit` | agente gráfico do polkit. Sem ele, o diálogo de senha nunca aparece e ações privilegiadas (gerenciador de discos, GParted, atualizações) falham em silêncio |
| `xfce4-clipman-plugin` | histórico da área de transferência — substitui a extensão `clipboard-indicator` |
| `thunar-volman` | montagem automática de pendrive e cartão no Thunar |
| `gvfs-backends`, `gvfs-fuse` | acesso a mídia removível, rede, MTP e lixeira pelo gerenciador de arquivos |
| `blueman` | gerenciamento de Bluetooth na bandeja (no lugar das extensões de bateria BT) |

Outros opcionais que o Kali recomenda e existem aqui: `catfish`,
`gnome-disk-utility`, `onboard`, `lightdm-gtk-greeter-settings`, `cherrytree`.

Sua sessão atual é GNOME em **Wayland** e a do Xfce é **Xorg**. Antes do primeiro
login no Xfce, leia `13-wayland-vs-xorg.md` e rode
`scripts/50-analise-wayland-xorg.sh`: ele lista o que da sua sessão atual deixa de
funcionar, o que muda de lugar e o que passa a funcionar melhor — inclusive as 13
extensões do GNOME que você usa hoje, luz noturna, gestos de touchpad e captura
de tela.

Deliberadamente **fora**: `kali-menu`, `kali-undercover`, `kali-hidpi-mode` e
tudo de `kali-tools-*` — são ligados às ferramentas de pentest ou dependem de
`kali-defaults`.

## 4.3 Aplicar as configurações do Kali no seu usuário

Copie os XMLs de referência para o seu perfil xfconf (eles só passam a valer na
sessão Xfce; a sessão GNOME ignora):

```bash
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
cp docs/referencia/xfce-perchannel-xml/*.xml \
   ~/.config/xfce4/xfconf/xfce-perchannel-xml/
```

O que cada um define:

| Arquivo | Efeito |
|---|---|
| `xsettings.xml` | tema `Kali-Dark`, ícones `Flat-Remix-Blue-Dark`, cursor `Adwaita` 24, `Cantarell 11`, `Fira Code Medium 10`, hinting |
| `xfwm4.xml` | tema de janela `Kali-Dark`, botões `O|HMC`, título `Cantarell Bold 9`, 4 áreas de trabalho |
| `xfce4-desktop.xml` | wallpaper `/usr/share/backgrounds/kali-16x9/default` (zoom) e ícones de desktop 48 px |
| `xfce4-keyboard-shortcuts.xml` | atalhos do Kali |
| `xfce4-session.xml`, `xfce4-power-manager.xml`, `xfce4-screensaver.xml`, `thunar.xml` | comportamento de sessão, energia, protetor de tela e gerenciador de arquivos |

Se você usou o **modo A** (assets por usuário), ajuste dois caminhos absolutos:
em `xfce4-desktop.xml`, troque `/usr/share/backgrounds/kali-16x9/default` por
`$HOME/.local/share/backgrounds/kali/kali-cubes-16x9.jpg` (escreva o caminho
completo; o Xfce não expande `$HOME`).

Para aplicar sem editar XML, com a sessão Xfce já aberta:

```bash
xfconf-query -c xsettings -p /Net/ThemeName      -s Kali-Dark
xfconf-query -c xsettings -p /Net/IconThemeName  -s Flat-Remix-Blue-Dark
xfconf-query -c xsettings -p /Gtk/FontName       -s "Cantarell 11"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Fira Code Medium 10"
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s Adwaita
xfconf-query -c xfwm4 -p /general/theme          -s Kali-Dark
xfconf-query -c xfwm4 -p /general/button_layout  -s "O|HMC"
xfconf-query -c xfwm4 -p /general/title_font     -s "Cantarell Bold 9"
```

## 4.4 O painel — a parte que mais entrega o visual

Duas opções.

**Opção 1 (mais fiel, recomendada):** carregar o perfil de painel que o próprio
Kali empacota. Dentro da sessão Xfce:

```bash
xfce4-panel-profiles load docs/referencia/painel/Kali.tar.bz2
```

(Se instalou pelo modo B, o mesmo arquivo está em
`/usr/share/xfce4-panel-profiles/layouts/Kali.tar.bz2`. Há também
`Kali compact.tar.bz2`, o painel fino de 28 px.)

**Opção 2:** copiar o `default.xml` do Kali antes do primeiro login no Xfce, para
que ele seja o padrão de fábrica do painel:

```bash
sudo mkdir -p /etc/xdg/xfce4/panel
sudo cp docs/referencia/painel/xfce4-panel-default.xml \
        /etc/xdg/xfce4/panel/default.xml
```

Isso só tem efeito em usuários que ainda não têm `~/.config/xfce4/panel`.

Complementos do painel:

```bash
# ícone do menu + dimensões do Whisker Menu
mkdir -p ~/.config/xfce4/panel
cp docs/referencia/painel/whiskermenu-defaults.rc \
   ~/.config/xfce4/panel/whiskermenu-1.rc

# script do plugin genmon que mostra o IP da VPN no painel
mkdir -p ~/.local/share/kali-themes
cp docs/referencia/painel/xfce4-panel-genmon-vpnip.sh \
   ~/.local/share/kali-themes/
chmod +x ~/.local/share/kali-themes/xfce4-panel-genmon-vpnip.sh
```

O `whiskermenu-1.rc` só vale se o plugin do Whisker tiver o id 1 (é o caso no
layout do Kali). Nos favoritos, troque as entradas de ferramentas
(`kali-tools.desktop`, `exploit-database.desktop`…) pelas suas: terminal,
arquivos, editor, navegador.

Se você carregou o perfil pronto, o genmon já vem apontando para
`/usr/share/kali-themes/xfce4-panel-genmon-vpnip.sh`. Com o modo A, edite o
comando do plugin (clique direito → Propriedades) para o caminho em
`~/.local/share/kali-themes/`.

## 4.5 Terminal

```bash
mkdir -p ~/.config/xfce4/terminal
cp docs/referencia/shell/xfce4-terminalrc \
   ~/.config/xfce4/terminal/terminalrc
```

Isso traz a paleta de 16 cores do Kali, o fundo transparente a 95% de opacidade
e o uso das cores do tema. Detalhes e o prompt de duas linhas em
`07-terminal-e-prompt.md`.

## 4.6 Escolher a sessão no login

Não é preciso configurar nada: instalar o `xfce4` cria
`/usr/share/xsessions/xfce.desktop`, e o GDM passa a oferecer "Xfce Session" no
seletor de engrenagem da tela de login. Sua sessão "Ubuntu" (Wayland) continua
ali, como padrão.

Para conferir: `ls /usr/share/xsessions/`.

O Kali usa LightDM em vez do GDM. Trocar de gerenciador de login **não é
necessário** e mexe em uma peça crítica do sistema; se você quiser mesmo a tela
de login do Kali, veja `08-boot-login-e-logos.md` §8.4 — e leia os avisos.

## 4.7 Atalho: script

Os passos 4.3 a 4.5 estão automatizados em `scripts/20-aplicar-xfce.sh` — rode-o
**dentro da sessão Xfce**, depois carregue o painel com o `xfce4-panel-profiles`.

## 4.8 Verificação

Entre na sessão Xfce e confira:

- [ ] Painel único no topo, 34 px, com ícone do dragão à esquerda
- [ ] Lista de janelas **sem texto**, apenas ícones
- [ ] Gráfico de CPU azul→ciano à direita, antes da bandeja
- [ ] Relógio em formato 24 h sem segundos (`%_H:%M`)
- [ ] Wallpaper `kali-cubes`
- [ ] Barra de título escura com fonte Cantarell Bold, botões à direita
- [ ] Ícones azuis (Flat-Remix) no Thunar e no menu
- [ ] Terminal levemente transparente com a paleta do Kali

O que falta em relação ao Kali de fábrica: o menu de categorias de ferramentas
(vem de `kali-menu`, ligado às ferramentas), a página inicial customizada do
navegador e o `kali-undercover`. Nada disso é aparência do desktop em si.
