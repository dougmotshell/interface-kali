# 6. Ambiente 3 — GNOME (o seu desktop atual)

O Kali também tem um sabor GNOME (`kali-desktop-gnome`), e é dele que sai a
configuração oficial abaixo. Este é o caminho que **não instala novo desktop**:
o GNOME 46 que você já usa é revestido com os temas do Kali.

Fidelidade: ~65%. É o mesmo GNOME, com as cores, ícones, fontes e o wallpaper do
Kali. A estrutura da tela (barra superior única, visão de Atividades, dock) segue
sendo GNOME — no Kali padrão, quem manda é o painel do Xfce.

Tempo estimado: 15–20 min. Espaço: ~95 MB.

## 6.1 A configuração oficial do Kali para GNOME

Vem do arquivo `21_kali-themes.gschema.override` (em `docs/referencia/gnome/`), que é
o que o pacote `kali-themes` instala em uma máquina Kali:

| Chave | Valor |
|---|---|
| `org.gnome.desktop.interface color-scheme` | `prefer-dark` |
| `org.gnome.desktop.interface gtk-theme` | `adw-gtk3-dark` |
| `org.gnome.desktop.interface icon-theme` | `Flat-Remix-Blue-Dark` |
| `org.gnome.desktop.interface font-name` | `Cantarell 11` |
| `org.gnome.desktop.interface document-font-name` | `Cantarell 11` |
| `org.gnome.desktop.interface monospace-font-name` | `Fira Code Medium 10` |
| `org.gnome.shell.extensions.user-theme name` | `Kali-Dark` |
| `org.gnome.desktop.wm.preferences button-layout` | `appmenu:minimize,maximize,close` |
| `org.gnome.desktop.background picture-uri` | `…/kali-theme/wallpaper/gnome-background.xml` |
| `org.gnome.desktop.background picture-options` | `zoom` |

Repare: no GNOME o Kali **não** usa o tema GTK `Kali-Dark` — usa `adw-gtk3-dark`
para os aplicativos e reserva o `Kali-Dark` para o **shell** (barra superior,
menus do sistema, visão de Atividades), via extensão `user-theme`.

## 6.2 Passo a passo

### 1. Assets e fontes

```bash
sudo apt install fonts-cantarell fonts-firacode gnome-shell-extensions gnome-tweaks
bash ~/Desktop/interface-kali/scripts/10-baixar-assets.sh --instalar-usuario
```

O modo por usuário (`~/.themes`, `~/.local/share/icons`) basta para tudo nesta
seção, exceto o logo do GDM (§8.3).

### 2. Extensão user-theme

O tema de shell só é aplicável com a extensão `user-theme` ativa:

```bash
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gnome-extensions list | grep -i user-theme     # confirme o nome exato
```

Se ela não aparecer, é porque `gnome-shell-extensions` não está instalado.
Depois de ativar, faça logout/login (em Wayland não há como recarregar o shell
sem reiniciar a sessão).

### 3. Aplicar tema, ícones e fontes

```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Flat-Remix-Blue-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code Medium 10'
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.shell.extensions.user-theme name 'Kali-Dark'
```

O Ubuntu 24.04 tem cor de destaque própria (o roxo do Yaru). Ao trocar para
`adw-gtk3-dark` ela deixa de ser aplicada nos apps GTK3; nos apps GTK4/libadwaita
ela continua valendo — se quiser neutralizar:

```bash
gsettings set org.gnome.desktop.interface accent-color 'blue'
```

### 4. Wallpaper

```bash
W="$HOME/.local/share/backgrounds/kali/kali-cubes-16x9.jpg"   # modo usuário
# W=/usr/share/backgrounds/kali/kali-cubes-16x9.jpg           # modo sistema
gsettings set org.gnome.desktop.background picture-uri      "file://$W"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$W"
gsettings set org.gnome.desktop.background picture-options  'zoom'
gsettings set org.gnome.desktop.screensaver picture-uri     "file://$W"
gsettings set org.gnome.desktop.screensaver picture-options 'zoom'
```

O Kali usa `kali-cubes` no desktop e `kali-cubes2` na tela de bloqueio.

### 5. Dock

O Kali usa `dash-to-dock` (já instalado aqui) na posição padrão da extensão, à
esquerda, com indicadores em ponto e sem lixeira. O `ubuntu-dock` é uma
bifurcação da mesma extensão e não deve rodar em paralelo:

```bash
gnome-extensions disable ubuntu-dock@ubuntu.com
gnome-extensions enable dash-to-dock@micxgx.gmail.com

gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS'
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink false
gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true
```

Seu dock hoje está em `BOTTOM`; a linha acima o move para a esquerda, como no
Kali. É preferência sua — se gostar embaixo, mantenha `BOTTOM`.

### 6. Ícones na área de trabalho

O Kali deixa a área de trabalho quase limpa:

```bash
gsettings set org.gnome.shell.extensions.ding icon-size 'small'
gsettings set org.gnome.shell.extensions.ding show-home false
gsettings set org.gnome.shell.extensions.ding show-trash false
gsettings set org.gnome.shell.extensions.ding show-volumes false
```

### 7. Extensões que compõem a barra do Kali

O sabor GNOME do Kali habilita, além do dock: `apps-menu`, `places-menu`,
`drive-menu`, `system-monitor`, `ding`, `user-theme`, `appindicators`,
`tiling-assistant` e a específica `top-panel-vpnip@kali.org`.

As sete primeiras vêm de `gnome-shell-extensions` / do Ubuntu:

```bash
for e in apps-menu places-menu drive-menu system-monitor; do
  gnome-extensions enable "$e@gnome-shell-extensions.gcampax.github.com" 2>/dev/null \
    || echo "não encontrada: $e"
done
gnome-extensions list        # confira os nomes reais antes
```

`apps-menu` é a que mais muda a percepção: coloca um menu de aplicativos no
canto superior esquerdo, aproximando a barra do GNOME de um painel tradicional.

A extensão de IP de VPN é específica do Kali e não está no Ubuntu; ignore.

### 8. Esquema de cor dos editores

Se instalou os assets, os estilos `Kali-Dark` para GtkSourceView já estão em
`~/.local/share/gtksourceview-{3.0,4,5}/styles/`:

```bash
gsettings set org.gnome.TextEditor style-scheme 'Kali-Dark'
gsettings set org.gnome.TextEditor show-grid true
gsettings set org.gnome.TextEditor highlight-current-line true
gsettings set org.gnome.TextEditor show-line-numbers true
```

### 9. Terminal

Veja `07-terminal-e-prompt.md` — paleta, transparência e prompt de duas linhas.

### 10. Monitor do sistema (opcional, mas é detalhe do Kali)

```bash
gsettings set org.gnome.gnome-system-monitor cpu-stacked-area-chart true
gsettings set org.gnome.gnome-system-monitor mem-color '#B8174C'
gsettings set org.gnome.gnome-system-monitor net-in-color '#367BF0'
gsettings set org.gnome.gnome-system-monitor net-out-color '#D41919'
gsettings set org.gnome.gnome-system-monitor swap-color '#19a187'
```

Tudo isso está automatizado em `scripts/40-aplicar-gnome.sh`, e revertido em
`scripts/41-reverter-gnome.sh`.

## 6.3 O que não fica igual

- **Barra superior e Atividades.** O tema `Kali-Dark` pinta a barra do GNOME com
  as cores do Kali, mas ela continua sendo a barra do GNOME: um item à esquerda,
  relógio ao centro, *quick settings* à direita. O Kali original tem painel com
  pager, lista de janelas, gráfico de CPU e IP de VPN.
- **Apps GTK4/libadwaita** (Nautilus, Configurações, Text Editor) ignoram
  `gtk-theme`. Eles seguem o `color-scheme: prefer-dark`, ou seja, ficam escuros,
  porém em cinza Adwaita e não no azul-escuro do Kali. Para forçar, é preciso
  sobrescrever com CSS em `~/.config/gtk-4.0/gtk.css`, o que quebra a cada
  atualização do GNOME — não recomendo.
- **Tema de shell feito para GNOME mais novo.** O `Kali-Dark/gnome-shell` do
  pacote atual acompanha o GNOME do Kali (48/49). Aqui é 46: ele carrega e
  estiliza barra, menus e diálogos, mas pode haver espaçamentos estranhos em
  telas específicas. Se algo ficar ilegível, volte o shell ao padrão com
  `gsettings set org.gnome.shell.extensions.user-theme name ''` — o resto
  continua aplicado.
- **Snaps.** Aplicativos snap não leem `~/.themes`.

## 6.4 Verificação

- [ ] Barra superior escura azulada, não preta/cinza do Yaru
- [ ] Janelas GTK3 com fundo `#23252E`-ish e destaque azul `#2777FF`
- [ ] Ícones azuis Flat-Remix no dock e nos menus
- [ ] Fonte Cantarell na interface, Fira Code no terminal
- [ ] Wallpaper `kali-cubes`
- [ ] Dock à esquerda com indicadores de ponto e sem lixeira
