# Memória — interface-kali

Índice. **Uma linha por entrada, no máximo 200 linhas**; o detalhe vai no arquivo por
tópico em `memory/<topico>.md`. Se uma entrada não cabe numa linha, ela não pertence
aqui.

Irmãos: `AGENTS.md` (contrato) · `docs/guias/` (a documentação real).

## Entradas

- [Pacotes de aparência do Kali](pacotes-do-kali.md) — pool, versões extraídas e os `Breaks` que decidem o que é instalável neste Ubuntu.
- [Tela de login e as etapas](tela-de-login-e-etapas.md) — por que `instalar` não aplica, por que o greeter não lê o `$HOME`, e o `grep -q` que mente sob `pipefail`.
- [Teclado ABNT2 e a precedência do xfconf](teclado-e-a-precedencia-do-xfconf.md) — o canal da sessão sobrescreve o `/etc`; diagnostique na sessão e leia o mapa ativo com `xkbcomp`.

## Regras

- Data relativa vira data absoluta ("na semana passada" → `2026-08-17`).
- Não registre o que o repositório já conta: estrutura de código, histórico do git,
  conteúdo do `AGENTS.md`.
- Nunca registre segredo, token, hostname real, PII ou nome de cliente.
- Entrada errada é apagada, não corrigida por acréscimo.

