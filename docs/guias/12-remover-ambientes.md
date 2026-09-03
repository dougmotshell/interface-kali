# 12. Desativar, remover e desinstalar

Recorte dos documentos vizinhos:

- **[`10-rollback.md`](10-rollback.md)** = reverter **configuração** (o desktop
  volta ao visual anterior, mas os pacotes continuam instalados);
- **este arquivo (12)** = remover **software e arquivos**: sessões, pacotes de
  ambiente, assets do Kali e as alterações de boot/login;
- **[`11-problemas-e-solucoes.md`](11-problemas-e-solucoes.md)** = quando algo
  quebrou e você precisa consertar em vez de remover.

A ordem abaixo vai do **menos invasivo ao mais invasivo**. Pare no nível que
resolve o seu caso — não há obrigação de chegar ao fim.

| Nível | O que faz | Reversível? | Risco |
|---|---|---|---|
| 1 | Deixar de usar a sessão | Sim, é só escolher outra no login | nenhum |
| 2 | Apagar a configuração do usuário | Sim, se você tiver backup | baixo |
| 3 | Desinstalar os pacotes do ambiente | Sim, reinstalando | médio |
| 4 | Remover os assets do Kali | Sim, rodando `10-baixar-assets.sh` de novo | baixo |
| 5 | Reverter boot e login | Sim | **alto** — mexe em GRUB/Plymouth/DM |

---

## 12.1 Nível 1 — só deixar de usar a sessão

Instalar Xfce ou Plasma **não** altera a sua sessão GNOME. Basta escolher
"Ubuntu" na engrenagem da tela de login e nada dos outros ambientes é carregado:
sem processos, sem consumo de memória, apenas alguns MB em disco.

Confira o que está oferecido no GDM:

```bash
ls /usr/share/xsessions /usr/share/wayland-sessions
```

Hoje esta máquina lista apenas `ubuntu.desktop` / `ubuntu-xorg.desktop` (Xorg) e
`ubuntu.desktop` / `ubuntu-wayland.desktop` (Wayland). Depois de instalar os
ambientes, aparecem `xfce.desktop` e `plasmax11.desktop`.

Para esconder uma sessão do seletor **sem desinstalar** nada:

```bash
sudo mv /usr/share/xsessions/xfce.desktop{,.disabled}
# reverter:
sudo mv /usr/share/xsessions/xfce.desktop{.disabled,}
```

Se você quiser garantir que a sessão padrão é a do Ubuntu, o GDM guarda a última
escolha por usuário em `~/.dmrc` ou em `AccountsService`; confirme com
`cat /var/lib/AccountsService/users/$USER 2>/dev/null`.

---

## 12.2 Nível 2 — apagar a configuração do usuário

Isto zera o ambiente sem tocar nos pacotes. Na próxima entrada, a sessão volta
ao padrão de fábrica dela (Xfce genérico, Plasma Breeze, GNOME Ubuntu).

**Sempre mova antes de apagar** — o `mv` é reversível, o `rm -rf` não:

```bash
# Xfce
mv ~/.config/xfce4 ~/.config/xfce4.removido-$(date +%F)

# Plasma
mkdir -p ~/plasma-removido-$(date +%F)
mv ~/.config/kdeglobals ~/.config/kwinrc ~/.config/plasmarc \
   ~/.config/konsolerc ~/.config/kscreenlockerrc \
   ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
   ~/plasma-removido-$(date +%F)/ 2>/dev/null
mv ~/.local/share/plasma ~/plasma-removido-$(date +%F)/ 2>/dev/null

# GNOME (configuração, não pacotes) — ver 10-rollback.md §10.1
bash ~/Desktop/interface-kali/scripts/41-reverter-gnome.sh
```

Arquivos compartilhados entre ambientes, que podem ter sobrado do processo
(veja `11-problemas-e-solucoes.md` §11.10):

```bash
mv ~/.config/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini.bak 2>/dev/null
mv ~/.config/gtk-4.0/settings.ini ~/.config/gtk-4.0/settings.ini.bak 2>/dev/null
```

E o bloco do prompt: remova a seção `--- prompt estilo Kali ---` do `~/.zshrc`,
depois `exec zsh`.

---

## 12.3 Nível 3 — desinstalar os pacotes do ambiente

### Antes: descubra o que é seu e o que é dependência

```bash
# o que VOCÊ pediu explicitamente (o resto veio como dependência)
apt-mark showmanual | grep -E 'xfce|thunar|mousepad|plasma|kde|konsole|dolphin|lightdm|sddm'

# simulação: o que sairia junto, sem executar nada
sudo apt autoremove --purge --dry-run | sed -n '1,40p'
sudo apt remove --purge --dry-run xfce4 | sed -n '1,40p'
```

Leia a lista de "os seguintes pacotes serão REMOVIDOS" com atenção antes de
confirmar. Se aparecer algo que você usa (drivers, `network-manager`, um
aplicativo do dia a dia), cancele e remova em pacotes menores.

### Xfce

```bash
sudo apt remove --purge \
  xfce4 xfce4-goodies xfce4-session xfce4-panel xfdesktop4 xfwm4 \
  xfce4-whiskermenu-plugin xfce4-genmon-plugin xfce4-cpugraph-plugin \
  xfce4-pulseaudio-plugin xfce4-power-manager-plugins xfce4-panel-profiles \
  xfce4-notifyd xfce4-screensaver xfce4-taskmanager xfce4-screenshooter
sudo apt autoremove --purge
```

**Não remova sem pensar:** `thunar` (gerenciador de arquivos leve, útil sozinho),
`mousepad`, `ristretto`, `parole`, `xfce4-terminal`, `catfish`, `gvfs-backends`,
`network-manager-gnome`. Nenhum deles depende do resto do Xfce para funcionar.

Também não remova `gtk2-engines-pixbuf` nem `dconf-cli` — outros pacotes os usam.

### KDE Plasma

```bash
sudo apt remove --purge \
  kde-plasma-desktop plasma-desktop plasma-workspace kwin-x11 \
  systemsettings plasma-nm plasma-pa powerdevil kscreen
sudo apt autoremove --purge
```

**Não remova sem pensar:** `konsole`, `dolphin`, `kate`, `okular`, `gwenview`,
`ark`, `kcalc`, `kde-spectacle` — todos rodam fora do Plasma. E cuidado com
`breeze`/`breeze-icon-theme`: se você instalou o `breeze-icon-theme` para
completar a herança dos ícones Flat-Remix
(`11-problemas-e-solucoes.md` §11.3), mantenha-o.

Se você instalou o **SDDM**, acerte o gerenciador de login **antes** de remover
qualquer coisa:

```bash
sudo dpkg-reconfigure gdm3      # escolha gdm3
cat /etc/X11/default-display-manager   # confirme /usr/sbin/gdm3
sudo apt remove --purge sddm sddm-theme-breeze
```

Remover o SDDM sem antes devolver o posto ao GDM é a receita para ficar sem tela
de login.

### GNOME

O GNOME é o desktop desta máquina — **não desinstale**. O que se remove aqui são
apenas os extras que os guias sugeriram, se você não os quiser:

```bash
sudo apt remove --purge gnome-shell-extensions gnome-tweaks
# a extensão dash-to-dock instalada pelo usuário fica em:
ls ~/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
# para removê-la de fato (isto apaga a extensão do seu usuário):
# rm -rf ~/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
```

Só remova `gnome-shell-extensions` se nenhuma das extensões dele estiver em uso —
`gnome-extensions list --enabled` mostra.

### Depois: confirme

```bash
ls /usr/share/xsessions            # a sessão removida saiu da lista?
systemctl status display-manager --no-pager | head -3
df -h /                            # quanto voltou de espaço
```

---

## 12.4 Nível 4 — remover os assets do Kali

### Modo por usuário

```bash
rm -rf ~/.themes/Kali-* ~/.themes/adw-gtk3*
rm -rf ~/.local/share/icons/Flat-Remix-* ~/.local/share/icons/Adwaita+Flat-Remix-Blue
rm -rf ~/.local/share/backgrounds/kali ~/.local/share/kali-logos
rm -rf ~/.local/share/wallpapers/KaliCubes*
rm -f  ~/.local/share/gtksourceview-*/styles/Kali-*.xml
rm -rf ~/.local/share/color-schemes/Kali*.colors
rm -f  ~/.local/share/konsole/Kali-Dark.{profile,colorscheme}
rm -rf ~/.local/share/kali-themes
rm -rf ~/.cache/kali-assets              # os .deb baixados
```

**Reverta a configuração antes de apagar os arquivos.** Se o `gsettings` ainda
apontar para `Flat-Remix-Blue-Dark` e o tema desaparecer, os ícones caem para o
`Adwaita` sem aviso — funciona, mas fica feio. Ordem correta: `10-rollback.md`
primeiro, depois este bloco.

### Modo sistema

```bash
sudo apt remove --purge kali-themes-common kali-wallpapers-2026
# adw-gtk3-kali normalmente não foi instalado via dpkg nesta máquina
# (Breaks: libgtk-4-1 << 4.16); confirme com:
dpkg -l | grep -E 'kali-themes-common|kali-wallpapers|adw-gtk3-kali'
sudo apt autoremove --purge
```

`kali-themes-common` depende de `kali-wallpapers-2026`: removendo o primeiro, o
segundo fica órfão e sai no `autoremove`. Se você tinha instalado outros pacotes
de wallpaper do Kali, confirme com `dpkg -l | grep kali-wallpapers`.

Se em algum momento você instalou `kali-themes` ou `kali-defaults` (este
material recomenda **não** instalar — `03-obter-os-assets-oficiais.md` §3.2),
remova-os também e reveja `/etc/xdg`, `/etc/skel` e
`/usr/share/glib-2.0/schemas/` em busca de sobras:

```bash
dpkg -L kali-themes 2>/dev/null | head -30
sudo apt remove --purge kali-themes kali-defaults 2>/dev/null
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
```

### Fontes

Só remova se não estiver usando:

```bash
sudo apt remove --purge fonts-cantarell fonts-firacode
fc-cache -f
```

O `fonts-cantarell` é usado pelo GNOME upstream como fonte de interface; no
Ubuntu o padrão é a `Ubuntu Sans`, então removê-lo é seguro. Confirme com
`apt-cache rdepends --installed fonts-cantarell` antes.

---

## 12.5 Nível 5 — reverter boot e login

Esta é a camada de maior risco: erro aqui aparece **antes** de você ter um
desktop para consertá-lo. Tenha um pendrive live à mão e faça um item por vez,
reiniciando entre eles se possível.

### GRUB

```bash
sudo rm -f /etc/default/grub.d/kali-themes.cfg
sudo update-grub
```

Se você editou `/etc/default/grub` diretamente, restaure do backup de
`scripts/00-backup.sh` (`sistema/grub`) e rode `update-grub` de novo.

### Plymouth

```bash
sudo update-alternatives --config default.plymouth   # escolha o tema anterior
sudo update-initramfs -u
```

Nesta máquina, o tema registrado antes das mudanças era o `bgrt` (confirmado no
levantamento). Para remover completamente o registro do tema do Kali:

```bash
sudo update-alternatives --remove default.plymouth \
     /usr/share/plymouth/themes/kali/kali.plymouth
sudo update-initramfs -u
```

### Logo do GDM

```bash
sudo rm -f /etc/dconf/db/gdm.d/95-kali-logo
sudo dconf update
sudo systemctl restart gdm3     # feche seus programas antes: isto encerra a sessão
```

### LightDM de volta para GDM

```bash
sudo dpkg-reconfigure gdm3      # escolha gdm3
cat /etc/X11/default-display-manager
sudo apt remove --purge lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
```

### Variáveis de tema para apps Qt

```bash
sudo rm -f /etc/profile.d/kali-themes.sh    # se você criou esse arquivo
grep -n 'QT_QPA_PLATFORMTHEME' ~/.profile ~/.zshrc ~/.bashrc 2>/dev/null
sudo apt remove --purge qt5ct qt6ct         # opcional
```

### Avatar do usuário

```bash
rm -f ~/.face ~/.face.icon
```

---

## 12.6 Verificação final

```bash
# nenhum arquivo do Kali sobrou nos caminhos de tema
ls ~/.themes /usr/share/themes | grep -i kali
ls ~/.local/share/icons /usr/share/icons | grep -i flat-remix

# nenhum pacote do Kali instalado
dpkg -l | grep -iE 'kali-'

# sessões oferecidas no login
ls /usr/share/xsessions /usr/share/wayland-sessions

# gerenciador de login correto
cat /etc/X11/default-display-manager

# configuração do GNOME de volta ao padrão desta máquina
gsettings get org.gnome.desktop.interface gtk-theme    # 'Yaru-purple-dark'
gsettings get org.gnome.desktop.interface icon-theme   # 'Yaru-purple'

# espaço recuperado
df -h /
```

Se algo nessa lista ainda mostra resquício e você não sabe de onde veio,
`dpkg -S <caminho-do-arquivo>` diz qual pacote o instalou (ou informa que o
arquivo não pertence a pacote nenhum — nesse caso foi cópia manual, e apagar é
seguro).
