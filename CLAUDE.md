@AGENTS.md

`AGENTS.md` é canônico: tudo que vale para Claude Code, Codex e Copilot vive lá. Aqui
fica só o que é específico do Claude Code. Se uma seção serviria para as três CLIs,
ela está no lugar errado.

## Subagentes

- `runbook-auditor` — audita a integridade do material: afirmação sem origem em
  `docs/referencia/`, caminho quebrado depois de mover pasta, pacote que não existe no
  apt, script que não passa no `bash -n`. Acione antes de commitar mudança grande nos
  guias.

Dois agentes usados neste trabalho moram no **nível do usuário**
(`~/.claude/agents/`), não neste repositório, porque servem qualquer projeto:
`kali-desktop-theming` (aplicar/reverter aparência) e `linux-session-doctor`
(diagnóstico de sessão gráfica). Um clone novo não os terá — e não precisa.

## Comandos de barra

Gerados por `scripts/sync-ai-surfaces.py` a partir de `skills/` e `.claude/agents/`:

- `/verificar-runbook` — valida o repositório de ponta a ponta antes de um commit.
- `/runbook-auditor` — chama o agente auditor.

## Servidores MCP

Nenhum. `.mcp.json` fica com `mcpServers` vazio: este projeto não fala com serviço
externo, e um servidor declarado sem uso é superfície de ataque sem retorno.

## Gerado vs. autorado

`.claude/skills/` e `.claude/commands/` são **gerados**. Edite `skills/<n>/SKILL.md`
ou `.claude/agents/<n>.md` e rode `python3 scripts/sync-ai-surfaces.py`.
Nunca edite um arquivo que abre com `managed-by:`.
