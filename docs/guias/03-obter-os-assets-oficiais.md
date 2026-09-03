# 3. Obter os assets oficiais do Kali

> **Convenção dos comandos.** Os comandos dos guias assumem que você está na
> **raiz do repositório clonado** — daí `cp docs/referencia/…` e
> `bash scripts/…` funcionarem como escritos. Caminhos de sistema
> (`/usr/share/…`, `~/.themes`, `~/.config/…`) são absolutos de propósito.

## 3.1 Regra número um: não adicione o repositório do Kali ao Ubuntu

Existe a tentação de escrever `deb http://http.kali.org/kali kali-rolling main`
em `/etc/apt/sources.list.d/` e rodar `apt install kali-themes`. **Não faça
isso.** O Kali é Debian *testing/unstable* com base própria; misturá-lo ao
Ubuntu 24.04 é o caso clássico de "FrankenDebian":

- o APT passa a ver versões mais novas de `libc6`, `libgtk-3-0`, `systemd` e
  companhia e tenta atualizar meio sistema;
- o `kali-defaults` reescreve padrões que o Ubuntu também define, e os dois
  pacotes disputam os mesmos arquivos de configuração;
- uma atualização parcial nesse estado deixa a máquina sem sessão gráfica, e a
  recuperação é manual;
- não há caminho de volta suportado.

Como só queremos arquivos de aparência, a rota segura é baixar `.deb` avulsos e
usar apenas o conteúdo deles.

## 3.2 Quais pacotes interessam

| Pacote | Tamanho | O que traz | Dependências |
|---|---|---|---|
| `kali-themes-common` | 7 MB (~85 MB instalado) | temas GTK/xfwm/gnome-shell, ícones Flat-Remix, logos, tema do GRUB e do Plymouth, estilos de editor, perfis de painel | só `kali-wallpapers-2026` |
| `kali-wallpapers-2026` | 6,2 MB | wallpapers e fundos de login | nenhuma |
| `adw-gtk3-kali` | 137 KB | `adw-gtk3` / `adw-gtk3-dark` (tema GTK3 do sabor GNOME) | nenhuma |
| `kali-themes` | 31 KB | **apenas arquivos de configuração** (xfconf, painel, terminalrc, override de gsettings) | `kali-defaults`, `plymouth-label`, … |

Fora da lista de propósito: `kwin-style-kali` (decoração de janela do Plasma) é
um plugin compilado para Plasma 6 e não funciona no Plasma 5.27 do Ubuntu — veja
`05-ambiente-kde-plasma.md` §5.1.

O `kali-themes` tem ainda um impedimento técnico duro, revelado pelo próprio
pacote: ele declara `Breaks: gnome-shell (>= 51~), gnome-shell (<< 48~)`, isto é,
só aceita GNOME Shell 48 a 50. Esta máquina tem o **46** — o `dpkg` recusaria a
instalação, e é por isso que o tema de shell `Kali-Dark` é assumidamente feito
para um GNOME mais novo (veja o guia 06 §6.3).

Os três primeiros são pacotes de dados: mexem só em `/usr/share`, sem scripts de
pós-instalação que reconfigurem o sistema. O quarto **não deve ser instalado** —
ele aplicaria os padrões do Kali para todos os usuários e exigiria
`kali-defaults`, que conflita com o Ubuntu. Dele usamos só os arquivos, que já
estão copiados em `docs/referencia/`.

## 3.3 Dois modos de instalar os assets

### Modo A — por usuário (recomendado, 100% reversível)

Extrai os `.deb` sem `dpkg` e copia para o seu `$HOME`:

```
~/.themes/                      Kali-Dark, Kali-Light, adw-gtk3, adw-gtk3-dark…
~/.local/share/icons/           Flat-Remix-Blue-Dark, Flat-Remix-Blue-Light
~/.local/share/backgrounds/kali/  wallpapers
~/.local/share/kali-logos/      logos
~/.local/share/gtksourceview-*/styles/  Kali-Dark.xml
```

GTK 3/4, xfwm4 e a extensão `user-theme` do GNOME leem esses caminhos. Desfazer
é apagar as pastas.

Limitação: telas que rodam **antes** do login (GDM, LightDM, Plymouth, GRUB) não
leem `$HOME`. Se você quiser o boot e o login temáticos, precisará também do modo B
para esses arquivos.

### Modo B — do sistema (necessário para boot/login)

```bash
sudo dpkg -i kali-wallpapers-2026_*.deb kali-themes-common_*.deb adw-gtk3-kali_*.deb
```

Os arquivos vão para `/usr/share/...`, exatamente onde estão no Kali, o que
mantém os caminhos absolutos dos arquivos de configuração válidos. Continua
reversível (`sudo apt remove kali-themes-common kali-wallpapers-2026 adw-gtk3-kali`).

Pontos de atenção:
- `adw-gtk3-kali` declara `Breaks: libgtk-4-1 (<< 4.16)`. O Ubuntu 24.04 tem
  GTK4 4.14, ou seja, **abaixo do exigido**: o `dpkg -i` vai reclamar. Nesse
  caso instale esse pacote pelo modo A (é só um tema em `/usr/share/themes`),
  ou use `dpkg -i --force-depends` sabendo que o tema GTK4 dele pode ter
  detalhes fora de lugar no GTK 4.14.
- `kali-themes-common` depende de `kali-wallpapers-2026`; instale os dois na
  mesma linha de comando.
- Ele instala 20 variantes do Flat-Remix (~85 MB). Se quiser economizar, prefira
  o modo A, que copia só as duas variantes usadas.

## 3.4 Baixando

`scripts/10-baixar-assets.sh` faz o download e a extração para
`~/.cache/kali-assets/`, e opcionalmente a instalação no modo A.

Manualmente:

```bash
BASE=https://kali.download/kali/pool/main
mkdir -p ~/.cache/kali-assets && cd ~/.cache/kali-assets
curl -fLO $BASE/k/kali-themes/kali-themes-common_2026.3.0_all.deb
curl -fLO $BASE/k/kali-wallpapers/kali-wallpapers-2026_2026.1.0_all.deb
curl -fLO $BASE/a/adw-gtk3-kali/adw-gtk3-kali_2026.2.0_all.deb
```

Use `curl -L`: `http.kali.org` redireciona para um espelho (`kali.download`), e
sem seguir redirecionamento você baixa um arquivo de 0 byte.

Para conferir se há versão mais nova, liste o diretório do pool:

```bash
curl -sL https://kali.download/kali/pool/main/k/kali-themes/ | grep -o 'kali-themes[^"]*\.deb'
```

Registre o checksum do que baixou, para saber se um `.deb` mudou entre execuções:

```bash
sha256sum *.deb > SHA256SUMS.txt
```

## 3.5 As fontes vêm do Ubuntu

```bash
sudo apt install fonts-cantarell fonts-firacode
```

`Cantarell 11` e `Fira Code Medium 10` são exatamente os nomes que o Kali usa;
os pacotes do Ubuntu fornecem as mesmas famílias. Não use a `FiraCode Nerd Font`
já instalada aqui para isso — o nome da família é diferente e as configurações
que citam `Fira Code Medium` não a encontrariam.
