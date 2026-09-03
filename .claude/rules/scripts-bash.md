---
paths:
  - "scripts/**"
---

Script deste projeto mexe na sessão gráfica de uma máquina real: ele avisa, oferece
ensaio e guarda o que sobrescreve.

Carrega só quando um arquivo de `scripts/` é lido; por isso mora aqui e não em
`AGENTS.md`. Projetada em `.github/instructions/scripts-bash.instructions.md`
(`applyTo:`) por `scripts/sync-ai-surfaces.py`.

## Regra

- Abra com `#!/usr/bin/env bash` e `set -euo pipefail`, e valide com `bash -n` antes de
  considerar pronto.
- Com `set -e`, não deixe `[ teste ] && comando` solto nem `$(… | grep …)` que pode não
  casar: use `if`, ou feche com `|| true`. Foi isso que abortou o analisador três vezes.
- Toda ação que altera o sistema honra `--dry-run` imprimindo o comando em vez de
  executá-lo.
- Nada de `sudo` silencioso: anuncie o comando privilegiado antes de rodar.
- Configuração do usuário se move para `.bak-<data>`; nunca se apaga direto.
- Antes de aplicar, exija o backup (`scripts/00-backup.sh`); antes de tocar em GRUB,
  Plymouth ou gerenciador de login, exija confirmação explícita.
- Cor só quando a saída é TTY.

## Por quê

O usuário roda isso na própria máquina de trabalho, muitas vezes na sessão que está
sendo modificada. Um script que aplica sem ensaio, sem backup e sem avisar do `sudo`
transforma um erro de digitação em uma máquina sem tela de login.
