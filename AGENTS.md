# interface-kali

Runbook **pessoal** para deixar a interface de um Ubuntu 24.04 visualmente igual à do
Kali Linux — nos três ambientes que o Kali distribui (Xfce, KDE Plasma, GNOME) e sem
instalar nenhuma ferramenta de pentest. Projeto de uma pessoa, para uma máquina: sem
branding corporativo, sem cabeçalho de classificação de informação.

Este arquivo é o **contrato canônico**. `CLAUDE.md` e `.github/copilot-instructions.md`
o importam; nunca duplique conteúdo neles. Codex, Copilot, Cursor e Gemini CLI leem
este arquivo nativamente.

Irmãos: `.claude/agents/` (agentes) · `skills/` (procedimentos) · `.claude/rules/`
(regras por caminho) · `docs/` (guias, capturas, referência) · `memory/`.

## Estrutura

| Caminho | O que é |
|---|---|
| `docs/guias/01..13` | Os guias, na ordem de leitura e execução |
| `docs/capturas/` | Comparativos antes/depois + os fontes HTML e assets que os geram |
| `docs/referencia/` | Arquivos de configuração **originais** do Kali, extraídos dos `.deb` |
| `scripts/` | Automação; `kali-look.sh` é a entrada única |
| `relatorios/` | Saída do analisador Wayland → Xorg — gerado, fora do git |

## Stack

Bash 5 e Markdown. `python3` aparece só no gerador de superfícies de IA e em
utilitários pontuais. Não há build, não há dependência de runtime, não há pacote a
instalar para ler ou rodar este projeto.

## Comandos

| Ação | Comando |
|---|---|
| Instalar | nada a instalar; opcionalmente `pre-commit install` |
| Rodar | `scripts/kali-look.sh` (menu) ou `scripts/kali-look.sh status` |
| Testar | `make test` — `bash -n` em todo script e links de todo Markdown |
| Lint / formatar | `make lint` (shellcheck, se instalado) · `make format` |
| Sincronizar superfícies de IA | `python3 scripts/sync-ai-surfaces.py` |

## Convenções que diferem do padrão da ferramenta

- **Monolíngue em pt-BR, por decisão.** Prosa, nomes de guia e mensagens de script em
  português. As árvores `docs/pt-br/` e `docs/en-us/` vieram do template e seguem sem
  conteúdo próprio: a documentação real mora em `docs/guias/`, e o `manual/index.md` de
  cada árvore aponta para lá. Ausência declarada vale mais que árvore vazia.
- **Caminhos citados em texto são relativos à raiz** (`docs/referencia/…`,
  `scripts/…`), inclusive dentro de `docs/guias/`.
- **Todo valor de aparência afirmado num guia tem origem rastreável** em um arquivo de
  `docs/referencia/` — nome de tema, hex de paleta, fonte, layout de painel. Se não dá
  para citar a origem, o valor não entra.
- Guias são numerados pela ordem de execução, não por assunto. O recorte dos últimos é
  fixo: **10** reverte configuração · **11** conserta defeito · **12** remove software
  · **13** antecipa o efeito de trocar Wayland por Xorg.
- Script novo entra em `scripts/` com prefixo numérico da sua etapa e é chamado pelo
  `kali-look.sh`, nunca só documentado.

## Armadilhas

- `curl` sem `-L` baixa `.deb` de **0 byte**: o pool do Kali redireciona para espelho e
  não há erro visível.
- Listar o pool exige `grep -oE 'href="[^"]+\.deb"'` — nome de pacote tem `_` e
  maiúscula, então regex de caractere solta não casa.
- `kali-themes` declara `Breaks: gnome-shell (>= 51~), gnome-shell (<< 48~)`: o `dpkg`
  recusa instalá-lo em GNOME 46.
- `adw-gtk3-kali` declara `Breaks: libgtk-4-1 (<< 4.16)` e o Ubuntu 24.04 tem GTK4
  4.14 — o tema vai para `~/.themes`, não pelo `dpkg`.
- `network-manager-applet` **não existe** no Ubuntu 24.04; o pacote é
  `network-manager-gnome`.
- `Flat-Remix-Blue-Dark` herda `breeze-dark`, que não está instalado aqui: ícone
  faltando é herança quebrada, não tema errado.
- GNOME 46 em Wayland bloqueia captura de tela por linha de comando (`grim` sem
  wlr-screencopy, `org.gnome.Shell.Screenshot` com `AccessDenied`). Comparativo visual
  se faz renderizando HTML com Chrome headless.
- Renomear ou mover pasta quebra caminho citado em prosa **e** em script — já
  aconteceu na migração de `guias/` para `docs/guias/`. Depois de mover, reescreva as
  referências e valide os links.
- Em script com `set -e`, `[ teste ] && comando` isolado e `$(… | grep …)` sem
  correspondência abortam a execução. Use `if`, ou termine com `|| true`.

## Nunca

- Adicionar o repositório `kali-rolling` ao APT deste Ubuntu, nem instalar
  `kali-themes` / `kali-defaults`. Só se copiam arquivos dos `.deb`.
- Aplicar aparência sem rodar `scripts/00-backup.sh` antes.
- Tocar em GRUB, Plymouth ou gerenciador de login sem confirmação explícita do usuário
  — é a camada que deixa a máquina sem boot ou sem tela de entrada.
- Editar arquivo com o banner `managed-by:` — edite a fonte e rode o gerador.
- Escrever segredo, token, hostname real ou PII nos guias e relatórios versionados.
- Marcar este material com branding de empresa ou classificação de informação: é
  projeto pessoal, e rotular como corporativo atribui a outro dono o que não é dele.

## Documentação

Índice em `docs/README.md`. Os guias em `docs/guias/`; a referência crua em
`docs/referencia/`; as imagens e seus fontes em `docs/capturas/`. Detalhe fica lá, não
aqui.

## Memória

`memory/MEMORY.md` é o índice (uma linha por entrada, até 200 linhas); o detalhe vai
nos arquivos por tópico.


## Recomendações

seja inteligente pensando em estratégias para economizar tokens sem perder a qualidade e sem encher desnecessariamente o contexto.

Sempre aprenda, anote o que aprendeu para não ter retrabalho no futuro, note os erros para evitar que se repita.

Sempre que necessário, crie scripts e/ou skills e/ou agents etc... tudo para facilitar e otimizar os trabalhos.

sempre documente tudo.

use subagents sempre que possível para dividir tarefas complexas e otimizar o uso de tokens.