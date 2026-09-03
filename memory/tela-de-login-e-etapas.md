# Tela de login e a separação instalar / aplicar

Duas confusões que já custaram um ciclo de "apliquei tudo e não mudou nada"
(2026-09-03, sessão real nesta máquina). Ambas viraram código, não só prosa:
`scripts/21-greeter-lightdm.sh` e o bloco `proximo_passo_aplicar` do
`kali-look.sh`.

## `instalar` não aplica nada

`kali-look.sh instalar xfce` instala pacotes. A aparência é gravada pelo
`aplicar`, que só funciona **de dentro** da sessão alvo, porque escreve no
serviço de configuração dela (`xfconf`, `kconfig`, `dconf`). Rodado de fora, o
`exige_sessao` recusa — e o erro se perde entre as linhas do `apt`.

Sintoma: instala, reinicia, entra no Xfce e encontra `Greybird` +
`elementary-xfce-dark`, o padrão do Xfce.

Diagnóstico que não depende de memória do usuário — o log guarda as recusas:

```bash
grep -c 20-aplicar-xfce ~/.local/state/kali-look-backup/kali-look.log   # 0 = nunca rodou
grep ERRO ~/.local/state/kali-look-backup/kali-look.log | tail
```

## O greeter do LightDM não lê o `$HOME`

Ele roda como o usuário de sistema `lightdm`, antes de qualquer login. Tema e
ícones têm de estar em `/usr/share/{themes,icons}`: o modo `assets --usuario`
(`~/.themes`, `~/.local/share/icons`) é invisível para ele. Logo, a tela de login
exige `assets --sistema`.

Os três arquivos que a config do Kali referencia, todos de `kali-themes-common`:

| Arquivo | |
|---|---|
| `/usr/share/themes/Kali-Light` | tema GTK |
| `/usr/share/icons/Flat-Remix-Blue-Light` | ícones |
| `/usr/share/desktop-base/kali-theme/login/background` | fundo |

Outros detalhes desta camada:

- **Trocar o DM ≠ tematizar.** `apt install lightdm` muda qual programa desenha a
  tela; o greeter segue no tema padrão. São dois passos.
- **O logo do GDM fica inerte** quando o LightDM assume, então um `status` que
  diz "logo do GDM: aplicado" não significa que a tela de login mudou. O `status`
  agora qualifica isso.
- **`keyboard = onboard`** vem na config original do Kali e o `onboard` não é
  instalado por este runbook — a linha é comentada na aplicação.
- **Chaveiro:** o pacote `lightdm` do Ubuntu 24.04 **já** instala
  `pam_gnome_keyring.so` em `/etc/pam.d/lightdm` e `lightdm-greeter` (4 linhas).
  Trocar o GDM pelo LightDM, por si só, não faz o chaveiro pedir senha a cada
  boot — verifique antes de culpar a troca.

## Caminho que o guia 08 citava e não existe

`/usr/share/kali-themes/etc/lightdm/lightdm-gtk-greeter.conf` vem do pacote
`kali-themes`, que declara `Breaks: gnome-shell (>= 51~)` e não se instala aqui.
A única fonte válida é `docs/referencia/lightdm-gtk-greeter.conf`. Corrigido.

## `grep -q` com `pipefail` reporta falso negativo

Variante da armadilha de `set -e` já conhecida. `fc-list … | grep -qi cantarell`
falhava **de forma intermitente**: o `grep -q` fecha o pipe no primeiro
casamento, o `fc-list` morre de `SIGPIPE`, e com `pipefail` o pipeline devolve
141 → uma fonte instalada era relatada como ausente. Sem o `-q` o grep lê até o
fim e o resultado é estável. Vale para qualquer produtor lento num pipeline com
`pipefail`.

## O painel apaga o que veio antes, e o Whisker migrou para o xfconf

Dois defeitos que se somavam e produziam "painel do Kali, menu do Xfce":

- `xfce4-panel-profiles load` **substitui** `~/.config/xfce4/panel/` inteiro.
  Rodado depois do `20-aplicar-xfce.sh`, apagava os complementos dele. Ordem
  certa: carregar o perfil **primeiro**, ajustar depois.
- `xfce4-whiskermenu-plugin` **2.8** (Ubuntu 24.04) guarda a config no
  **xfconf**; o `~/.config/xfce4/panel/whiskermenu-<id>.rc` legado é migrado e
  **apagado** na primeira execução do plugin. A cópia do `.rc` que o script fazia
  não tinha efeito nenhum — e cravava o id `1`, que só por sorte é o do Kali.

O `.rc` desaparece também se você o copiar com o painel **rodando**: ao sair, o
plugin reescreve seu estado. Para o fallback (plugin < 2.8) a ordem é parar o
painel, escrever, subir.

Virou `scripts/22-painel-xfce.sh`, que detecta o id do plugin em vez de cravá-lo.
O perfil `Kali.tar.bz2` já traz `button-icon`, `favorites`, `menu-width/height` e
`position-*`; o script grava as dez chaves restantes do arquivo de referência.
