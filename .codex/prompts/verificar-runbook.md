<!-- managed-by:interface-kali/sync-ai-surfaces — do not edit by hand -->
<!-- source: skills/verificar-runbook/SKILL.md -->

Prova que o material continua íntegro: nenhum script quebrado, nenhum link morto,
nenhum caminho apontando para pasta que mudou de lugar, nenhum pacote inexistente.

Fonte autorada. Projetada em `.claude/skills/`, `.agents/skills/`,
`.claude/commands/`, `.github/prompts/` e `.codex/prompts/` por
`scripts/sync-ai-surfaces.py`.

Irmãos: `.claude/agents/runbook-auditor.md` (quem executa) · `AGENTS.md` (armadilhas
conhecidas).

## Quando usar

Depois de mover ou renomear pasta, editar script, mudar lista de pacotes ou reescrever
guia. E antes de qualquer commit que toque em mais de um arquivo.

Não use para aplicar, reverter ou diagnosticar aparência: isso é `scripts/kali-look.sh`
e o guia 11.

## Passos

1. `make test` — roda `bash -n` em todo `scripts/*.sh` e checa os links relativos de
   todo Markdown versionado.
2. `make lint` — `shellcheck` nos scripts, se estiver instalado (o alvo avisa e passa
   quando não está).
3. `scripts/kali-look.sh status` — prova que o gerenciador ainda resolve os caminhos de
   `docs/referencia/` e lê o estado da máquina.
4. `scripts/kali-look.sh --dry-run aplicar gnome` — prova que o caminho de aplicação
   monta os comandos sem executar nada.
5. `python3 scripts/sync-ai-surfaces.py --check` — prova que nenhuma superfície gerada
   ficou fora de sincronia com a sua fonte.
6. `grep -rn 'interface-kali/\(guias\|capturas\|referencia\)' docs scripts` — deve voltar
   vazio; qualquer resultado é caminho de antes da migração para `docs/`.

## Verificação

Cole a saída de cada passo. `make test` termina em `ok`; os passos 3 e 4 terminam sem
erro; os passos 5 e 6 não imprimem achado. Nunca afirme um check que não rodou.
