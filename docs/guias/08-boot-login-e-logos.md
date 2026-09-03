# 8. Boot, login e logos

Esta é a camada que roda **antes** do seu login, e por isso é a única que exige
arquivos no sistema (`/usr/share`, `/etc`) — o modo por usuário não alcança aqui.
É também a camada de maior risco: erro em GRUB ou em gerenciador de login pode
deixar a máquina sem boot ou sem tela de entrada.

Faça nesta ordem: logos → GDM → Plymouth → GRUB. E só siga adiante se estiver
tranquilo em recuperar via console (`Ctrl+Alt+F3`) ou live USB.

## 8.1 O que o Kali usa

| Camada | Configuração |
|---|---|
| GRUB | tema `/boot/grub/themes/kali/theme.txt`, `GRUB_GFXMODE=1280x720,1280x800,auto`, `splash` |
| Plymouth | tema `kali` (`/usr/share/plymouth/themes/kali`) |
| GDM (GNOME) | `org/gnome/login-screen logo='/usr/share/images/kali-logos/logo-text-128.png'` |
| LightDM (Xfce) | tema `Kali-Light`, ícones `Flat-Remix-Blue-Light`, fundo `kali-cubes2`, relógio `%d %b, %H:%M` |
| SDDM (Plasma) | tema `breeze` |
| Avatar do usuário | `/etc/skel/.face` e `.face.icon` |

Os arquivos vêm de `kali-themes-common` (temas de GRUB e Plymouth, logos) e de
`kali-wallpapers-2026` (fundos). Instale-os no **modo B**
(`03-obter-os-assets-oficiais.md`) antes de continuar.

## 8.2 Logos e avatar (risco nenhum)

```bash
# avatar do usuário na tela de login e no menu
cp /usr/share/images/kali-logos/logo-256.png ~/.face
cp ~/.face ~/.face.icon
```

Os logos ficam em `/usr/share/images/kali-logos/` (SVG e PNG 64/128/256).

## 8.3 Logo do GDM (risco baixo)

O GDM lê configuração `dconf` própria:

```bash
sudo mkdir -p /etc/dconf/db/gdm.d
sudo tee /etc/dconf/db/gdm.d/95-kali-logo >/dev/null <<'CFG'
[org/gnome/login-screen]
logo='/usr/share/images/kali-logos/logo-text-128.png'
CFG
sudo dconf update
```

Para reverter: `sudo rm /etc/dconf/db/gdm.d/95-kali-logo && sudo dconf update`.

**Fundo da tela do GDM:** no GNOME 46 do Ubuntu, o plano de fundo do GDM está
compilado dentro de `/usr/share/gnome-shell/gnome-shell-theme.gresource`. Trocar
exige recompilar o gresource e apontar uma *alternativa* do dpkg para o arquivo
novo. É intrusivo, quebra em qualquer atualização do `gnome-shell` e, se der
errado, a tela de login fica sem tema. **Não recomendo** — o logo do Kali já
identifica a tela.

## 8.4 LightDM, se você for de Xfce (risco médio)

O Kali usa LightDM. Trocar o gerenciador de login afeta **todas** as sessões,
inclusive o GNOME.

```bash
sudo apt install lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
# durante a instalação, o dpkg pergunta qual gerenciador usar
sudo cp /usr/share/kali-themes/etc/lightdm/lightdm-gtk-greeter.conf \
        /etc/lightdm/lightdm-gtk-greeter.conf     # se instalou no modo B
```

(O mesmo arquivo está em `docs/referencia/lightdm-gtk-greeter.conf`.)

Para escolher o gerenciador depois: `sudo dpkg-reconfigure gdm3`.
Para voltar ao GDM: `sudo dpkg-reconfigure gdm3` e selecione `gdm3`; ou
`sudo systemctl disable lightdm && sudo systemctl enable gdm3`.

Se a tela de login não subir, entre em um console com `Ctrl+Alt+F3`, faça login
em texto e rode o `dpkg-reconfigure`.

## 8.5 Plymouth — a animação de boot (risco médio)

```bash
sudo apt install plymouth-themes plymouth-label
# o tema kali vem de kali-themes-common (modo B)
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
     default.plymouth /usr/share/plymouth/themes/kali/kali.plymouth 200
sudo update-alternatives --config default.plymouth   # escolha o kali
sudo update-initramfs -u
```

Reverter: rode o `--config` novamente e escolha o tema anterior
(`bgrt`/`spinner`/`ubuntu-logo`), depois `sudo update-initramfs -u`.

O tema do Kali precisa do módulo `label` (daí o `plymouth-label`), senão o texto
não aparece.

## 8.6 GRUB — a tela de escolha do sistema (risco mais alto)

```bash
sudo cp -r /usr/share/grub/themes/kali /boot/grub/themes/
sudo tee /etc/default/grub.d/kali-themes.cfg >/dev/null <<'CFG'
GRUB_GFXMODE="1280x720,1280x800,auto"
GRUB_THEME="/boot/grub/themes/kali/theme.txt"
if ! echo "$GRUB_CMDLINE_LINUX_DEFAULT" | grep -q splash; then
    GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT splash"
fi
CFG
sudo update-grub
```

(É o mesmo conteúdo de `docs/referencia/grub-kali-themes.cfg`.)

Antes de rodar `update-grub`, guarde uma cópia:
`sudo cp /boot/grub/grub.cfg /boot/grub/grub.cfg.bak`.

Reverter: `sudo rm /etc/default/grub.d/kali-themes.cfg && sudo update-grub`.

Observação: o Ubuntu esconde o menu do GRUB quando há só um sistema instalado —
o tema pode nunca aparecer. Segure `Shift` (BIOS) ou `Esc` (UEFI) no boot para
ver.

## 8.7 Aplicativos Qt fora do Plasma

Para que apps Qt (VLC, qBittorrent…) acompanhem o tema escuro nas sessões
Xfce/GNOME, o Kali exporta:

```sh
# /etc/profile.d/kali-themes.sh (do pacote kali-themes)
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_AUTO_SCREEN_SCALE_FACTOR=0
```

Instale `qt5ct` (e `qt6ct`) e configure o estilo dentro deles. Se preferir não
mexer em `/etc`, ponha o `export` no seu `~/.profile`.
