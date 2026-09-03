# Documentação — interface da Kali no Ubuntu 24.04

Toda a documentação deste material mora aqui.

| Pasta | Conteúdo |
|---|---|
| [`guias/`](guias/) | Os 13 guias, na ordem de leitura e execução |
| [`capturas/`](capturas/) | Comparativos visuais antes/depois dos três ambientes, com os fontes HTML e os assets usados |
| [`referencia/`](referencia/) | Arquivos de configuração **originais** do Kali, extraídos dos `.deb` oficiais |

Fora de `docs/`: [`../scripts/`](../scripts/) (automação, com `kali-look.sh` como
ponto de entrada), `../relatorios/` (saída do analisador Wayland → Xorg) e
[`../README.md`](../README.md) (índice geral do projeto).

## Os 13 guias

| Guia | Conteúdo |
|---|---|
| [`01-analise-do-sistema-atual.md`](guias/01-analise-do-sistema-atual.md) | O que existe hoje nesta máquina e o que isso implica |
| [`02-especificacao-visual-do-kali.md`](guias/02-especificacao-visual-do-kali.md) | A "planta" do visual do Kali: cada valor e sua origem no pacote |
| [`03-obter-os-assets-oficiais.md`](guias/03-obter-os-assets-oficiais.md) | Baixar temas, ícones e wallpapers do Kali com segurança |
| [`04-ambiente-xfce.md`](guias/04-ambiente-xfce.md) | Ambiente 1: Xfce — o desktop padrão do Kali |
| [`05-ambiente-kde-plasma.md`](guias/05-ambiente-kde-plasma.md) | Ambiente 2: KDE Plasma |
| [`06-ambiente-gnome.md`](guias/06-ambiente-gnome.md) | Ambiente 3: GNOME — o desktop atual desta máquina |
| [`07-terminal-e-prompt.md`](guias/07-terminal-e-prompt.md) | Paleta do terminal e o prompt de duas linhas |
| [`08-boot-login-e-logos.md`](guias/08-boot-login-e-logos.md) | GRUB, Plymouth, GDM/LightDM/SDDM, logos e avatar |
| [`09-fidelidade-e-limitacoes.md`](guias/09-fidelidade-e-limitacoes.md) | Item a item: idêntico, próximo e impossível |
| [`10-rollback.md`](guias/10-rollback.md) | Desfazer as **configurações** aplicadas |
| [`11-problemas-e-solucoes.md`](guias/11-problemas-e-solucoes.md) | Sintoma → causa → solução, e diagnóstico rápido |
| [`12-remover-ambientes.md`](guias/12-remover-ambientes.md) | Desativar e **desinstalar** ambientes, assets e camadas |
| [`13-wayland-vs-xorg.md`](guias/13-wayland-vs-xorg.md) | Sair do GNOME/Wayland para Xorg: o que quebra, degrada e melhora |

Recorte entre os quatro últimos: **10** reverte configuração · **11** conserta
defeito · **12** remove software · **13** antecipa o que a troca de servidor
gráfico afeta.

## Convenções

- Caminhos citados nos textos são relativos à raiz do projeto
  (`docs/referencia/…`, `scripts/…`).
- Cada valor de aparência afirmado nos guias tem origem rastreável em um arquivo
  de `referencia/` — nada foi inferido.
- Material **pessoal**: sem branding corporativo e sem cabeçalho de
  classificação.

## Deliberadamente ausente

- **Ferramentas de pentest.** O pedido era só a interface; `kali-menu`,
  `kali-tools-*` e `kali-undercover` ficaram fora, e o guia 09 registra o que
  isso custa em fidelidade.
- **Tradução en-US.** As árvores `pt-br/` e `en-us/` abaixo vieram do
  `harness-bootstrap` e continuam vazias de conteúdo próprio; este material é
  monolíngue em pt-BR por decisão, não por esquecimento.
