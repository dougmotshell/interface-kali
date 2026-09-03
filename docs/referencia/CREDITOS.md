# Créditos e licenças — `docs/referencia/`

Os arquivos desta pasta **não** são autoria deste projeto. São arquivos de
configuração extraídos, sem modificação, dos pacotes oficiais do Kali Linux, e
estão aqui para que cada valor afirmado nos guias tenha origem verificável.

| Arquivos | Pacote de origem | Versão extraída |
|---|---|---|
| `xfce-perchannel-xml/*.xml`, `painel/xfce4-panel-default.xml`, `painel/whiskermenu-defaults.rc`, `shell/xfce4-terminalrc`, `gnome/gtk-3.0-settings.ini`, `gnome/21_kali-themes.gschema.override`, `lightdm-gtk-greeter.conf`, `grub-kali-themes.cfg`, `kde/{kdeglobals,kwinrc,plasmarc,konsolerc,kscreenlockerrc}` | `kali-themes` | 2026.3.0 |
| `painel/Kali.tar.bz2`, `painel/Kali compact.tar.bz2`, `painel/xfce4-panel-genmon-vpnip.sh`, `kde/KaliDark.colors`, `kde/Kali-Dark.{profile,colorscheme}`, `kde/kali-panel-customizations.js` | `kali-themes-common` | 2026.3.0 |
| `shell/kali-zshrc` | `kali-defaults` (`/etc/skel/.zshrc`) | 2026.3.2 |

**Licença:** GPL-3.0+ — © Kali Devel Team (`devel@kali.org`). Consulte
`usr/share/doc/<pacote>/copyright` dentro de cada `.deb` para o texto integral.

A licença MIT deste repositório cobre apenas o conteúdo próprio (guias, scripts,
índices). Estes arquivos permanecem sob GPL-3.0+ e não são relicenciados.

"Kali Linux" e o logotipo do dragão são marcas da OffSec. Este projeto é
independente e não afiliado à OffSec nem ao projeto Kali Linux.

Para baixar e inspecionar os pacotes você mesmo, sem instalar nada:
`scripts/10-baixar-assets.sh` (só baixa e extrai, sem `--instalar-*`) ou o
utilitário `deb-fetch`.
