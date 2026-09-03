# Atalhos de teclado ao trocar de ambiente

Registrado em 2026-09-03, ao migrar do GNOME 46/Wayland para o Xfce com o tema do
Kali já aplicado.

## O que quase fez o trabalho errado

**`dconf dump /` não serve para migrar atalhos.** Ele só grava o que desviou do
padrão do schema. Na máquina de referência o dump trazia apenas
`org/gnome/desktop/wm/keybindings/maximize=@as []` e `custom-keybindings=@as []` —
o que parece "nenhum atalho configurado", quando na verdade os 45 atalhos em uso
eram os **padrões do GNOME**. A leitura certa é `gsettings list-recursively`, que
devolve o valor efetivo.

Consequência prática: os backups de `00-backup.sh` feitos antes da migração não
continham os atalhos. Não faltou backup — faltava a fonte certa. Por isso o
`00-backup.sh` passou a chamar `23-atalhos-teclado.sh exportar`.

## O que salvou

**O `dconf` é do usuário, não da sessão.** Dentro do Xfce ainda se lê tudo que o
GNOME usava, então a migração de atalhos pode ser feita *depois* da troca. Não
existe janela perdida, e não há nada a salvar antes do logout — ao contrário do
que vale para aparência, que precisa ser aplicada de dentro da sessão.

## A pegadinha que gerava atalho fantasma

O mesmo acelerador pode estar gravado com os modificadores em outra ordem: o Kali
grava `<Alt><Shift>Tab`, o `gsettings` devolve `<Shift><Alt>Tab`. Comparar a
string crua cria **duas propriedades no xfconf para uma tecla só**, e aí qual
vale é indefinido. `23-atalhos-teclado.sh` normaliza para a ordem
`<Primary><Shift><Alt><Super>` antes de comparar e de gravar. `<Control>`,
`<Ctrl>` e `<Primary>` são a mesma coisa para o GTK; o xfconf grava `<Primary>`.

## Detalhes que não se adivinham

- Nomes de ação do xfwm4 vêm das strings do binário instalado
  (`strings $(command -v xfwm4) | grep '_key$'`) e do
  `xfce4-keyboard-shortcuts.xml` do Kali em `docs/referencia/`.
- `Above_Tab` é invenção do mutter (a tecla acima do Tab, que varia com o
  layout); o GTK não entende, então esses atalhos não migram.
- Aceleradores `XF86*` não precisam migrar: quem trata tecla de hardware no Xfce
  é o `xfce4-settings`/`xfce4-power-manager`, não o WM.
- Restaurar o XML do canal à mão não basta: o `xfconfd` mantém o canal em
  memória e sobrescreve o arquivo. `atalhos reverter` copia e mata o `xfconfd`
  (o D-Bus o relança na consulta seguinte).

Ver [[teclado-e-a-precedencia-do-xfconf]] para o caso do *layout* de teclado, que
é outro problema com a mesma cara.
