# Manual — interface-kali

O manual deste projeto **não** mora nesta árvore.

A documentação real é o runbook em [`docs/guias/`](../../guias/): treze guias na ordem
de execução, de `01-analise-do-sistema-atual.md` a `13-wayland-vs-xorg.md`, com o
índice em [`docs/README.md`](../../README.md).

Esta árvore veio do template `harness-bootstrap`, que separa `architecture/`, `specs/`,
`decisions/` e `manual/` por língua. Aqui ela permanece sem conteúdo próprio de
propósito: o material é monolíngue em pt-BR e a numeração dos guias já é a ordem em que
se executa o trabalho — dividi-lo entre quatro árvores acrescentaria índice, não
clareza. Ausência declarada vale mais que árvore vazia.

Para começar: `scripts/kali-look.sh` (menu) ou `scripts/kali-look.sh status`.
