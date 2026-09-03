# Scripts

`kali-look.sh` é o **ponto de entrada único**: ele orquestra todos os outros,
checa pré-requisitos antes de agir, registra tudo em log e sabe desfazer o que
fez. Os scripts numerados continuam funcionando isoladamente — o gerenciador
apenas os chama na ordem certa e com as verificações necessárias.

```bash
cd <repo>/scripts         # onde você clonou este repositório
./kali-look.sh            # menu interativo
./kali-look.sh --help     # todos os comandos
./kali-look.sh status     # inclui o caminho do projeto detectado
```

Todos os scripts resolvem os caminhos a partir da própria localização
(`docs/referencia/`, `relatorios/`), então o repositório funciona em qualquer
diretório e para qualquer usuário — não há nada preso a `$HOME`. As únicas
exceções são deliberadas: backup e log ficam em
`~/.local/state/kali-look-backup/` e o cache de download em
`~/.cache/kali-assets/`, porque são estado do usuário, não do projeto.

## Inventário

| Script | Função | Precisa de sudo? | Reversível por |
|---|---|---|---|
| `kali-look.sh` | Gerenciador: menu + CLI para instalar, aplicar, reverter e remover tudo | só nas ações de sistema, sempre anunciado | ele mesmo (`reverter`, `remover`, `boot reverter`) |
| `00-backup.sh` | Salva `dconf` completo, configs (`xfce4`, `kdeglobals`, `.zshrc`…), lista de pacotes e tema de Plymouth em `~/.local/state/kali-look-backup/<data>/` | não | — (é o próprio ponto de retorno) |
| `10-baixar-assets.sh` | Baixa os `.deb` oficiais do Kali, confere checksums, extrai e instala os arquivos por usuário (`--instalar-usuario`) ou no sistema (`--instalar-sistema`). Versões e espelho ajustáveis por variável de ambiente — veja `--help` | só com `--instalar-sistema` | `kali-look.sh remover assets` |
| `20-aplicar-xfce.sh` | Tema `Kali-Dark`, ícones, fontes, xfwm4, wallpaper, `terminalrc`, Whisker Menu e script do genmon — via `xfconf-query` | não | `kali-look.sh reverter xfce` |
| `30-aplicar-plasma.sh` | Tema global `org.kali.kalidark.desktop`, esquema `KaliDark`, ícones, decoração Breeze com a ordem de botões do Kali, Konsole e tela de bloqueio | não | `kali-look.sh reverter plasma` |
| `40-aplicar-gnome.sh` | `adw-gtk3-dark` + tema de shell `Kali-Dark`, ícones, fontes, wallpaper, dash-to-dock, `ding`, extensões, terminal e monitor do sistema | não | `41-reverter-gnome.sh` |
| `41-reverter-gnome.sh` | Reverte o GNOME: restaura os valores do backup de `00-backup.sh` quando existe e, sem backup, aplica `gsettings reset` (padrão do schema, sem cravar tema de nenhuma distribuição) | não | — |
| `50-analise-wayland-xorg.sh` | **Somente leitura.** Analisa o que da sessão GNOME/Wayland atual quebra, degrada ou muda numa sessão Xfce/Xorg: extensões, escala, portais, polkit, chaveiro, gestos, OBS, ferramentas Wayland/X11, autostart. Grava relatório em `relatorios/` | não | nada a desfazer |

Arquivos `.py` que aparecerem nesta pasta vêm do *harness* de IA adotado pelo
repositório (projeção do contrato de agentes para cada CLI) e **não** participam
do fluxo de aparência: nenhum script acima depende deles.

## Ordem recomendada

```bash
# 1. entender e proteger o estado atual
./kali-look.sh status
./kali-look.sh analisar        # o que muda ao trocar Wayland por Xorg (só leitura)
./kali-look.sh backup

# 2. trazer os arquivos de aparência do Kali (modo reversível)
./kali-look.sh assets --usuario

# 3a. caminho recomendado: sessão Xfce paralela
./kali-look.sh instalar xfce
#    faça logout, escolha "Xfce Session" no GDM, entre e então:
./kali-look.sh aplicar xfce
xfce4-panel-profiles load ../docs/referencia/painel/Kali.tar.bz2

# 3b. ou: vestir o GNOME atual de Kali (15 min, reversível em um comando)
./kali-look.sh --dry-run aplicar gnome     # ensaio primeiro
./kali-look.sh aplicar gnome

# 3c. ou: sessão KDE Plasma
./kali-look.sh instalar plasma
#    entre na sessão Plasma e então:
./kali-look.sh aplicar plasma

# 4. peças opcionais
./kali-look.sh prompt aplicar               # prompt ┌──(user㉿host)-[~]
./kali-look.sh terminal gnome               # só a paleta do terminal
./kali-look.sh assets --sistema             # necessário para o passo seguinte
./kali-look.sh boot aplicar                 # GRUB + Plymouth + logo do GDM (risco alto)
```

## Desfazendo

```bash
./kali-look.sh reverter gnome         # restaura do backup, ou reseta ao padrão
./kali-look.sh reverter xfce          # ~/.config/xfce4 vira .bak-<data>
./kali-look.sh reverter plasma        # kdeglobals/kwinrc/... viram .bak-<data>
./kali-look.sh boot reverter          # remove tema de GRUB/Plymouth e logo do GDM
./kali-look.sh prompt remover         # remove o bloco delimitado do ~/.zshrc
./kali-look.sh remover xfce           # desinstala os pacotes do Xfce
./kali-look.sh remover plasma         # desinstala os pacotes do Plasma
./kali-look.sh remover assets --usuario
./kali-look.sh remover assets --sistema
```

Nada é apagado às cegas: configurações do usuário são **movidas** para
`*.bak-<data>`, remoções de pacote rodam primeiro em simulação (`apt remove -s`)
para você conferir o que sairia, e `~/.zshrc` é copiado antes de qualquer edição.

## Opções globais

| Opção | Efeito |
|---|---|
| `--dry-run` | Só imprime os comandos, não altera nada. Vale para qualquer subcomando; no menu, a tecla `d` liga e desliga. |
| `--sim` | Responde "sim" a todas as confirmações. Use com consciência — inclui as ações de sistema. |
| `-h`, `--help` | Ajuda completa com todos os comandos e exemplos. |

Exemplos de ensaio:

```bash
./kali-look.sh --dry-run aplicar xfce
./kali-look.sh --dry-run remover plasma
./kali-look.sh --dry-run boot aplicar
```

Limitação conhecida do `--dry-run`: ele mostra a chamada aos scripts numerados,
mas não expande os comandos que estão **dentro** deles (o script avisa isso na
tela). Para ver linha por linha, leia o script correspondente ou o guia do
ambiente.

## Proteções embutidas

- **Sessão certa.** `aplicar xfce` recusa rodar fora da sessão Xfce (o mesmo para
  Plasma e GNOME), explicando que xfconf/kconfig só gravam dentro do próprio
  ambiente. Em `--dry-run` a checagem só avisa.
- **Assets presentes.** As ações de aplicar exigem os temas do Kali instalados e
  dizem qual comando resolve.
- **Gerenciador de login.** `sddm` e `lightdm` ficam fora das listas de
  instalação; o script só os oferece depois de explicar que trocar o gerenciador
  afeta *todas* as sessões, e pede confirmação dupla.
- **Boot.** `boot aplicar` exige confirmação dupla, checa os assets de sistema e
  guarda `grub.cfg.bak-<data>` antes de rodar `update-grub`.
- **Log.** Toda invocação, confirmação e comando fica em
  `~/.local/state/kali-look-backup/kali-look.log`.

## Usando em outra máquina

O material foi construído e testado em **Ubuntu 24.04** (GNOME 46, Xfce 4.18,
Plasma 5.27). Em outra base os passos continuam valendo — o que muda são nomes e
versões de pacote. O `status`, o `instalar` e o `aplicar` avisam quando o sistema
não é o testado, sem abortar.

Pré-requisitos:

| Para | Precisa de |
|---|---|
| Rodar os scripts | `bash`, `curl`, `dpkg-deb`, `coreutils` — presentes em qualquer Debian/Ubuntu |
| Aplicar no GNOME | `gsettings` (`libglib2.0-bin`), `gnome-shell-extensions` para o tema de shell |
| Aplicar no Xfce | `xfconf-query` (vem com o Xfce), `xfce4-panel-profiles` para o painel |
| Aplicar no Plasma | `kwriteconfig5` ou `kwriteconfig6` e os `plasma-apply-*` |
| Camada de boot | `sudo`, `update-grub`, `plymouth-label`, e os assets instalados no sistema |
| Regerar os mockups | `google-chrome` (ou Brave/Edge) — só para `docs/capturas/`, nada do fluxo depende disso |

Em distribuição não-Debian (Fedora, Arch, openSUSE) os temas e os arquivos de
`docs/referencia/` funcionam igual, mas `10-baixar-assets.sh --instalar-sistema`
não serve: use `--instalar-usuario`, que só copia arquivos para o `$HOME`, e
instale Xfce/Plasma pelo gerenciador de pacotes da sua distribuição.

## Documentação

Os guias completos estão um nível acima: `../README.md` é o índice,
`../docs/guias/04-ambiente-xfce.md`, `../docs/guias/05-ambiente-kde-plasma.md` e
`../docs/guias/06-ambiente-gnome.md` cobrem os três ambientes,
`../docs/guias/10-rollback.md` detalha o rollback manual,
`../docs/guias/13-wayland-vs-xorg.md` explica a troca de servidor gráfico
e `../docs/referencia/` guarda os arquivos de configuração originais do Kali
que estes scripts copiam.

## Análise Wayland → Xorg

Se a sessão atual é GNOME em **Wayland** e você vai para Xfce ou Plasma, entra em
**Xorg**. A troca mexe em coisas que não são tema: extensões do GNOME, escala de tela,
compartilhamento de tela via portal, agente de autenticação, chaveiro, gestos de
touchpad e ferramentas amarradas a um dos dois servidores gráficos.

```bash
./kali-look.sh analisar                  # terminal + markdown em ../relatorios/
./50-analise-wayland-xorg.sh --sem-md    # só terminal
./50-analise-wayland-xorg.sh --md-apenas # só o arquivo, imprime o caminho
```

Cada achado sai classificado como **QUEBRA**, **DEGRADA**, **MUDA**, **MELHORA**
ou **OK**, com motivo e ação. O detalhamento conceitual está em
`../docs/guias/13-wayland-vs-xorg.md`.
