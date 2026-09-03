# 10. Rollback — desfazer a configuração

Este documento devolve o **visual** ao estado anterior. Os pacotes continuam
instalados: nada aqui desinstala software.

Recorte dos documentos vizinhos:

- **este arquivo (10)** = reverter **configuração** (`dconf`, `xfconf`,
  `kdeglobals`, terminal, prompt, boot/login);
- **[`12-remover-ambientes.md`](12-remover-ambientes.md)** = desinstalar
  **pacotes** e apagar os arquivos dos assets;
- **[`11-problemas-e-solucoes.md`](11-problemas-e-solucoes.md)** = sintoma →
  causa → solução, quando algo quebrou em vez de simplesmente ficar feio.

Ordem segura: **boot/login primeiro, depois desktop, depois assets** — o inverso
da aplicação. Assim você nunca fica com uma tela de login apontando para um
arquivo que já foi apagado.

## 10.0 Mapa: o que cada camada tocou e como desfazer

| Camada | Onde foi escrito | Como desfazer | Precisa de sudo? |
|---|---|---|---|
| Tema, ícones, fontes do GNOME | `dconf` (`org.gnome.desktop.interface`) | §10.1 ou `scripts/41-reverter-gnome.sh` | não |
| Tema do GNOME Shell | `dconf` (`…user-theme name`) | `gsettings set org.gnome.shell.extensions.user-theme name ''` | não |
| Dock, ícones de desktop, extensões | `dconf` (`org.gnome.shell.extensions.*`) | §10.1 | não |
| Wallpaper e tela de bloqueio | `dconf` (`…background`, `…screensaver`) | §10.1 | não |
| Paleta e fonte do terminal | `dconf` (perfil do gnome-terminal) | §10.2 | não |
| Prompt do shell | `~/.zshrc` | §10.2 (remover o bloco) | não |
| Sessão Xfce | `~/.config/xfce4/**` | §10.3 | não |
| Sessão Plasma | `~/.config/{kdeglobals,kwinrc,plasmarc,konsolerc,kscreenlockerrc}` | §10.4 | não |
| GTK compartilhado entre sessões | `~/.config/gtk-{3.0,4.0}/settings.ini` | §10.3 / `11-…` §11.10 | não |
| Logo do GDM | `/etc/dconf/db/gdm.d/95-kali-logo` | §10.5 | sim |
| Plymouth | alternativa `default.plymouth` + initramfs | §10.5 | sim |
| GRUB | `/etc/default/grub.d/kali-themes.cfg` | §10.5 | sim |
| Gerenciador de login | `debconf` / `/etc/X11/default-display-manager` | §10.5 | sim |
| Assets (arquivos de tema) | `~/.themes`, `~/.local/share/…` ou `/usr/share/…` | `12-remover-ambientes.md` §12.4 | depende |

## 10.1 GNOME (volta ao Yaru-purple-dark)

```bash
bash ~/Desktop/interface-kali/scripts/41-reverter-gnome.sh
```

Ou manualmente:

```bash
gsettings set org.gnome.desktop.interface gtk-theme   'Yaru-purple-dark'
gsettings set org.gnome.desktop.interface icon-theme  'Yaru-purple'
gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
gsettings set org.gnome.desktop.interface font-name           'Ubuntu Sans 11'
gsettings set org.gnome.desktop.interface document-font-name  'Ubuntu Sans 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Sans Mono 13'
gsettings set org.gnome.shell.extensions.user-theme name ''
gsettings reset org.gnome.desktop.background picture-uri
gsettings reset org.gnome.desktop.background picture-uri-dark
gsettings reset org.gnome.desktop.wm.preferences button-layout
gnome-extensions enable  ubuntu-dock@ubuntu.com
gnome-extensions disable dash-to-dock@micxgx.gmail.com
gsettings reset-recursively org.gnome.shell.extensions.dash-to-dock
gsettings reset-recursively org.gnome.shell.extensions.ding
```

Em Wayland, o tema do shell só volta ao normal depois de logout/login.

Alternativa radical, se você não souber mais o que foi mudado: `dconf reset -f
/org/gnome/` devolve **todo** o GNOME ao padrão do Ubuntu — inclusive
preferências suas que não têm nada a ver com este material. Prefira a
restauração seletiva de §10.7.

## 10.2 Terminal e prompt

```bash
P=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
G="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P/"
gsettings reset $G palette
gsettings reset $G use-theme-colors
gsettings reset $G bold-is-bright
gsettings reset $G scrollback-unlimited
gsettings reset $G use-transparent-background
gsettings reset $G background-transparency-percent
gsettings reset $G font
gsettings reset $G use-system-font
gsettings reset org.gnome.Terminal.Legacy.Settings theme-variant
gsettings reset org.gnome.Terminal.Legacy.Settings confirm-close
```

Prompt: remova do `~/.zshrc` o bloco entre
`# --- prompt estilo Kali ---` e `# ---------------------------------------`,
depois `exec zsh`. Se você tinha Powerlevel10k ou Starship e comentou a
inicialização deles, descomente agora.

Konsole e xfce4-terminal guardam a paleta em arquivo próprio; apagar o arquivo
volta ao padrão:

```bash
rm -f ~/.config/xfce4/terminal/terminalrc
rm -f ~/.local/share/konsole/Kali-Dark.{profile,colorscheme}
```

## 10.3 Xfce

A sessão Xfce pode simplesmente deixar de ser usada — escolha "Ubuntu" no GDM e
nada do Xfce é carregado. Para zerar a configuração dela (sem desinstalar):

```bash
mv ~/.config/xfce4 ~/.config/xfce4.bak-$(date +%F)
```

No próximo login, a sessão Xfce sobe com os padrões do Xfce, não do Kali. Se
quiser voltar atrás, `mv` de novo no sentido inverso.

Painel: se você carregou o perfil `Kali.tar.bz2` e quer o painel padrão do Xfce
de volta, com a sessão Xfce aberta:

```bash
xfce4-panel --quit
rm -f ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
xfce4-panel &
```

Camada GTK compartilhada (afeta também a sessão GNOME):

```bash
mv ~/.config/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini.bak 2>/dev/null
mv ~/.config/gtk-4.0/settings.ini ~/.config/gtk-4.0/settings.ini.bak 2>/dev/null
```

Para desinstalar os pacotes do Xfce, veja `12-remover-ambientes.md` §12.3.

## 10.4 KDE Plasma

```bash
mkdir -p ~/plasma-config.bak-$(date +%F)
mv ~/.config/kdeglobals ~/.config/kwinrc ~/.config/plasmarc \
   ~/.config/konsolerc ~/.config/kscreenlockerrc \
   ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
   ~/plasma-config.bak-$(date +%F)/ 2>/dev/null
mv ~/.local/share/plasma ~/plasma-config.bak-$(date +%F)/ 2>/dev/null
```

Ou volte só a aparência, mantendo o resto da sua configuração do Plasma:

```bash
plasma-apply-lookandfeel -a org.kde.breeze.desktop   # tema global padrão
plasma-apply-colorscheme BreezeDark                  # ou Breeze, se preferir claro
kwriteconfig5 --file kdeglobals --group Icons --key Theme breeze-dark
qdbus org.kde.KWin /KWin reconfigure
```

Confirme os nomes disponíveis com `plasma-apply-lookandfeel --list` e
`plasma-apply-colorscheme --list-schemes` antes de aplicar — eles variam com os
pacotes instalados.

Para desinstalar o Plasma (e acertar o gerenciador de login antes),
`12-remover-ambientes.md` §12.3.

## 10.5 Boot e login

Camada de maior risco. Um item por vez.

```bash
# GRUB
sudo rm -f /etc/default/grub.d/kali-themes.cfg
sudo update-grub

# Plymouth
sudo update-alternatives --config default.plymouth      # escolha o tema anterior (aqui era: bgrt)
sudo update-initramfs -u

# logo do GDM
sudo rm -f /etc/dconf/db/gdm.d/95-kali-logo
sudo dconf update

# LightDM -> GDM (encerra a sessão gráfica)
sudo dpkg-reconfigure gdm3
cat /etc/X11/default-display-manager                    # confirme /usr/sbin/gdm3
```

O backup de `scripts/00-backup.sh` guarda os originais em `sistema/` — use-os se
tiver editado `/etc/default/grub` ou `/etc/lightdm` à mão:

```bash
B=~/.local/state/kali-look-backup/<data>/sistema
diff -u "$B/grub" /etc/default/grub          # veja o que mudou antes de restaurar
sudo cp "$B/grub" /etc/default/grub && sudo update-grub
```

## 10.6 Assets

Reverter a configuração **antes** de apagar os arquivos: se o `gsettings` ainda
apontar para um tema que deixou de existir, o desktop cai silenciosamente para o
`Adwaita`.

Os comandos de remoção dos assets (modo usuário e modo sistema) estão em
`12-remover-ambientes.md` §12.4.

## 10.7 Restaurando a partir do backup

`scripts/00-backup.sh` grava em `~/.local/state/kali-look-backup/<data>/`:

| Arquivo | Conteúdo |
|---|---|
| `dconf-completo.ini` | dump de **todo** o `dconf` do usuário |
| `aparencia-antes.txt` | os valores-chave em texto, para conferência rápida |
| `xfce4/`, `kdeglobals`, `kwinrc`, `.zshrc`, … | cópias dos arquivos de configuração |
| `sistema/` | `grub`, `grub.d`, `lightdm`, `dconf/db/gdm.d`, display-manager |
| `pacotes.txt`, `temas-e-icones.txt`, `plymouth-atual.txt` | inventário |

Liste os backups disponíveis:

```bash
ls -1 ~/.local/state/kali-look-backup/
B=~/.local/state/kali-look-backup/$(ls -1 ~/.local/state/kali-look-backup/ | tail -1)
echo "$B"
```

### Restauração completa do dconf (força bruta)

```bash
dconf load / < "$B/dconf-completo.ini"
```

Isto reverte **tudo** que mudou no `dconf` desde o backup — inclusive
preferências suas sem relação com o tema (janelas, atalhos, aplicativos). Use
quando quiser voltar ao ponto zero.

### Restauração seletiva (recomendada)

Restaure apenas a árvore que interessa. O `dconf load` aceita um caminho como
prefixo, e o `dconf dump` do mesmo caminho no arquivo de backup serve de fonte:

```bash
# 1) extrair do dump só a seção desejada
awk '/^\[org\/gnome\/desktop\/interface\]/{f=1} f&&/^\[/&&!/interface\]/{f=0} f' \
    "$B/dconf-completo.ini" > /tmp/interface.ini
sed -i '1s|.*|[/]|' /tmp/interface.ini          # o load espera o grupo raiz

# 2) aplicar apenas nessa árvore
dconf load /org/gnome/desktop/interface/ < /tmp/interface.ini

# 3) conferir
dconf dump /org/gnome/desktop/interface/
```

Árvores úteis para restaurar isoladamente:

| Árvore | O que cobre |
|---|---|
| `/org/gnome/desktop/interface/` | tema, ícones, cursor, fontes |
| `/org/gnome/desktop/background/` | wallpaper |
| `/org/gnome/desktop/wm/preferences/` | botões e fonte de título |
| `/org/gnome/shell/` | extensões habilitadas, favoritos |
| `/org/gnome/shell/extensions/dash-to-dock/` | dock |
| `/org/gnome/terminal/` | perfis do terminal |

Chave por chave, sem mexer em arquivo nenhum, também funciona:

```bash
grep -E "gtk-theme|icon-theme|font-name" "$B/aparencia-antes.txt"
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-purple-dark'   # o valor de lá
```

### Arquivos de configuração

```bash
cp -a "$B/xfce4" ~/.config/            # devolve a config Xfce de antes
cp -a "$B/kdeglobals" "$B/kwinrc" ~/.config/ 2>/dev/null
cp -a "$B/.zshrc" ~/.zshrc             # cuidado: sobrescreve mudanças posteriores
```

Compare antes de sobrescrever: `diff -u "$B/.zshrc" ~/.zshrc`.

## 10.8 Se a sessão não abrir

Resumo — o passo a passo completo está em `11-problemas-e-solucoes.md` §11.1.

1. `Ctrl+Alt+F3` para um console em texto e faça login.
2. Reverter o dconf: `dconf reset -f /org/gnome/` (GNOME) ou
   `mv ~/.config/xfce4 ~/.config/xfce4.bak` (Xfce).
3. Reiniciar o gerenciador de login: `sudo systemctl restart gdm3`.
4. Em último caso, crie um usuário limpo (`sudo adduser teste-kali`) e confirme
   se o problema é da configuração do seu usuário ou do sistema.
