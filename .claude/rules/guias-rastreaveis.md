---
paths:
  - "docs/guias/**"
---

Todo valor de aparência afirmado num guia tem origem citável em `docs/referencia/`.

Carrega só quando um guia é lido; por isso mora aqui e não em `AGENTS.md`. Projetada em
`.github/instructions/guias-rastreaveis.instructions.md` (`applyTo:`) por
`scripts/sync-ai-surfaces.py`.

## Regra

- Nome de tema, hex de paleta, fonte, layout de painel, chave de `gsettings`: cada um
  vem de um arquivo de `docs/referencia/` (extraído dos `.deb` oficiais do Kali). Se
  não dá para apontar a origem, o valor não entra no texto.
- Pacote citado em bloco `apt install` precisa existir no Ubuntu 24.04 — confirme com
  `apt-cache policy <pacote>` antes de escrever.
- Caminho citado em prosa é relativo à raiz do projeto (`docs/referencia/…`,
  `scripts/…`), mesmo dentro de `docs/guias/`.
- Guia é numerado pela ordem de execução. O recorte de 10 a 13 é fixo: reverter
  configuração, consertar defeito, remover software, antecipar Wayland → Xorg.
- O que não foi verificado nesta máquina se escreve como "confirme com …", nunca como
  afirmação.

## Por quê

O valor deste material é ser exato: ele foi extraído de pacote, não deduzido de
tutorial. Uma única afirmação sem origem contamina a confiança em todas as outras, e o
leitor não tem como saber quais conferir.
