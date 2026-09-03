# Pacotes de aparência do Kali

Origem de tudo que este runbook afirma. Pool:
`https://kali.download/kali/pool/main/<inicial>/<pacote>/` — `http.kali.org`
redireciona para lá, e `curl` **sem `-L`** grava 0 byte sem erro.

Versões usadas na extração de `docs/referencia/` (2026-09-03):

| Pacote | Versão | Papel |
|---|---|---|
| `kali-themes-common` | 2026.3.0 | temas GTK/xfwm/gnome-shell, ícones Flat-Remix, logos, GRUB, Plymouth, perfis de painel, estilos de editor |
| `kali-wallpapers-2026` | 2026.1.0 | wallpapers e fundos de login (`kali-cubes` é o padrão) |
| `adw-gtk3-kali` | 2026.2.0 | `adw-gtk3` / `adw-gtk3-dark`, o tema GTK3 do sabor GNOME |
| `kali-themes` | 2026.3.0 | **só configuração** — não instalar, apenas copiar arquivos |
| `kali-defaults` / `-desktop` | 2026.3.2 | prompt do zsh, overrides de gsettings |
| `kali-desktop-{xfce,kde,gnome}` | 2026.3.3 | listas de pacotes de cada sabor |

Restrições que os próprios pacotes declaram, e que decidem o que é instalável aqui:

- `kali-themes`: `Breaks: gnome-shell (>= 51~), gnome-shell (<< 48~)` — recusa o GNOME
  46 desta máquina.
- `adw-gtk3-kali`: `Breaks: libgtk-4-1 (<< 4.16)` — o Ubuntu 24.04 tem GTK4 4.14.
- `kali-themes-common`: `Depends: kali-wallpapers-2026` — instale os dois juntos.
- `kwin-style-kali` (decoração do sabor Plasma): plugin binário para Plasma 6; o Ubuntu
  24.04 tem 5.27, então não há como usá-lo.

Inspecionar sem instalar: `dpkg-deb -f` (metadados), `-c` (conteúdo), `-x` (extrair).
Listar o pool: `curl -sL <dir> | grep -oE 'href="[^"]+\.deb"'`.
