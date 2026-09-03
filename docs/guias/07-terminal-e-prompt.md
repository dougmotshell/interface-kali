# 7. Terminal e prompt

O terminal é metade da identidade visual do Kali: fundo levemente transparente,
paleta azul-esverdeada e o prompt de duas linhas com `┌──` / `└─$`.

## 7.1 A paleta oficial (16 cores)

| # | Cor | Hex | # | Cor | Hex |
|---|---|---|---|---|---|
| 0 | preto | `#1F2229` | 8 | preto claro | `#198388` |
| 1 | vermelho | `#D41919` | 9 | vermelho claro | `#EC0101` |
| 2 | verde | `#5EBDAB` | 10 | verde claro | `#47D4B9` |
| 3 | amarelo | `#FEA44C` | 11 | amarelo claro | `#FF8A18` |
| 4 | azul | `#367BF0` | 12 | azul claro | `#277FFF` |
| 5 | magenta | `#9755B3` | 13 | magenta claro | `#962AC3` |
| 6 | ciano | `#49AEE6` | 14 | ciano claro | `#05A1F7` |
| 7 | branco | `#E6E6E6` | 15 | branco claro | `#FFFFFF` |

Mais: transparência de 5% (`BackgroundDarkness=0.95`), negrito em cor clara
(`bold-is-bright`), histórico ilimitado, sem confirmação ao fechar e fonte
`Fira Code Medium 10`.

Essas 16 cores são as **cores ANSI**: elas pintam o que o programa colore (o
`ls`, o `git`, o próprio prompt). O texto que **você digita**, o fundo, o cursor
e a seleção saem de outro par, o de primeiro plano e fundo — que a tabela acima
não contém:

| Papel | Hex | Origem |
|---|---|---|
| primeiro plano (texto digitado) | `#FFFFFF` | `docs/referencia/kde/Kali-Dark.colorscheme`, `[Foreground] Color=255,255,255` |
| fundo | `#23252E` | `docs/referencia/kde/Kali-Dark.colorscheme`, `[Background] Color=35,37,46` |

O Kali não grava esse par nos terminais GTK: o `xfce4-terminalrc` traz
`ColorUseTheme=TRUE` e o `Kali.json` do tilix traz `use-theme-colors: true` — os
dois pedem o par **ao tema GTK**, que no Kali é o `Kali-Dark`
(`theme_fg_color #eeeeec`, `theme_bg_color #23252e`). Aqui o tema GTK pode ser
outro, e é daí que vem o texto digitado numa cor que não é do Kali (§7.5).

## 7.2 xfce4-terminal (ambiente Xfce)

```bash
mkdir -p ~/.config/xfce4/terminal
cp docs/referencia/shell/xfce4-terminalrc \
   ~/.config/xfce4/terminal/terminalrc
```

Isso configura o **xfce4-terminal e mais nenhum**. Duas coisas fazem esse arquivo
não aparecer em lugar nenhum, e as duas são mais comuns que erro de paleta:

**1. O terminal que abre é outro.** Os atalhos do Kali (`Super+T`, `Ctrl+Alt+T`) e
o launcher do painel rodam `exo-open --launch TerminalEmulator`, que resolve pelo
`~/.config/xfce4/helpers.rc`. Se ele não existe ou aponta para outro programa,
abre outro terminal — e nada muda:

```bash
mkdir -p ~/.config/xfce4
printf 'TerminalEmulator=xfce4-terminal\n' >> ~/.config/xfce4/helpers.rc
```

O "Root Terminal Emulator" do painel do Kali roda `pkexec x-terminal-emulator`,
que é uma **alternativa do dpkg** — global, e por isso com `sudo`:

```bash
update-alternatives --query x-terminal-emulator | grep '^Value:'   # quem é hoje
sudo update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper
```

Num Ubuntu que já teve outros terminais instalados, esse valor costuma ser
`tilix`, `terminator` ou `gnome-terminal`.

**2. A janela já estava aberta.** O xfce4-terminal lê o `terminalrc` na
inicialização. Abra uma janela nova.

O `kali-look.sh` cuida dos dois e diz em qual terminal você está:

```bash
scripts/kali-look.sh terminal xfce    # paleta + terminal preferido + alternativa
scripts/kali-look.sh terminal auto    # detecta o terminal em uso e aplica nele
scripts/kali-look.sh status           # mostra o preferido e o x-terminal-emulator
```

## 7.3 gnome-terminal (ambiente GNOME)

O `gnome-terminal` guarda cores por perfil, identificado por UUID:

```bash
P=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
G="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P/"

gsettings set $G palette "['#1F2229','#D41919','#5EBDAB','#FEA44C','#367BF0','#9755B3','#49AEE6','#E6E6E6','#198388','#EC0101','#47D4B9','#FF8A18','#277FFF','#962AC3','#05A1F7','#FFFFFF']"
# NÃO use `use-theme-colors true` (o que o Kali faz) num Ubuntu cujo tema GTK
# pode não ser o Kali-Dark: o texto digitado sairia na cor do tema. §7.1 explica.
gsettings set $G use-theme-colors false
gsettings set $G foreground-color "'#FFFFFF'"
gsettings set $G background-color "'#23252E'"
gsettings set $G bold-is-bright true
gsettings set $G scrollback-unlimited true
gsettings set $G use-transparent-background true
gsettings set $G background-transparency-percent 5
gsettings set $G font 'Fira Code Medium 10'
gsettings set $G use-system-font false
gsettings set org.gnome.Terminal.Legacy.Settings theme-variant 'dark'
gsettings set org.gnome.Terminal.Legacy.Settings confirm-close false
```

## 7.4 Konsole (ambiente Plasma)

```bash
mkdir -p ~/.local/share/konsole
cp docs/referencia/kde/Kali-Dark.{profile,colorscheme} \
   ~/.local/share/konsole/
kwriteconfig5 --file konsolerc --group "Desktop Entry" --key DefaultProfile Kali-Dark.profile
```

## 7.5 Outros terminais

O `kali-themes-common` também traz a mesma paleta para `tilix`
(`/usr/share/tilix/schemes/Kali.json`), `alacritty`
(`/etc/xdg/alacritty/alacritty.toml`), `terminator`, `qterminal` e `yakuake`. Com
o **modo B** (assets no sistema), esses arquivos aparecem sozinhos.

### tilix

O `Kali.json` é só o esquema — ele fica disponível na lista, mas não se aplica
sozinho. O tilix guarda o perfil no `dconf`:

```bash
# o perfil que o tilix abre é o `default`; a lista só serve de reserva, e quem
# tem mais de um perfil acertaria o perfil errado configurando o primeiro
U=$(dconf read /com/gexperts/Tilix/profiles/default | tr -d "'")
[ -n "$U" ] || U=$(dconf list /com/gexperts/Tilix/profiles/ | grep '/$' | head -1 | tr -d '/')
B=/com/gexperts/Tilix/profiles/$U

# as 16 cores de /usr/share/tilix/schemes/Kali.json
dconf write $B/palette "['#1F2229', '#D41919', '#5EBDAB', '#FEA44C', '#367bf0', '#9755b3', '#49AEE6', '#E6E6E6', '#198388', '#EC0101', '#47D4B9', '#FF8A18', '#277FFF', '#962ac3', '#05A1F7', '#FFFFFF']"
# primeiro plano e fundo: fixos nos valores do Kali, NÃO herdados do tema GTK.
# O `use-theme-colors: true` do Kali.json é o que faz o texto digitado sair com a
# cor do tema ativo (Yaru, Adwaita…) em vez da do Kali — veja §7.1 e o sintoma
# no fim desta seção. O tilix grava cor em #RRRRGGGGBBBB, a forma que ele relê.
dconf write $B/use-theme-colors false
dconf write $B/foreground-color "'#FFFFFFFFFFFF'"
dconf write $B/background-color "'#232325252E2E'"
# cursor, seleção e negrito sem cor própria: derivados do par acima, não do tema
dconf write $B/cursor-colors-set false
dconf write $B/highlight-colors-set false
dconf write $B/bold-color-set false

# fonte: xsettings.xml do Kali define MonospaceFontName = Fira Code Medium 10.
# Sem isto o tilix usa a fonte mono do GNOME, que é outra.
dconf write $B/use-system-font false
dconf write $B/font "'Fira Code Medium 10'"

# terminalrc do Kali: BackgroundDarkness=0.95 -> 5% de transparência
dconf write $B/use-transparent-background true
dconf write $B/background-transparency-percent 5
```

Ou `scripts/kali-look.sh terminal tilix`. Desfazer: `dconf reset -f $B/`.

**Sintoma: a paleta está certa e o texto que você digita está fora dela.** É o
`use-theme-colors`. Com ele ligado, a paleta de 16 cores continua sendo a do Kali
— o `ls` e o `git` saem certos —, mas o texto digitado, o fundo, o cursor e a
seleção vêm do tema GTK do momento. Num Ubuntu isso costuma ser Yaru ou Adwaita,
e no Xfce o valor que vale é o do `xfconf`, não o do `gsettings`:

```bash
dconf read /com/gexperts/Tilix/profiles/$U/use-theme-colors   # true = herda do tema
xfconf-query -c xsettings -p /Net/ThemeName                   # tema GTK no Xfce
gsettings get org.gnome.desktop.interface gtk-theme           # tema GTK no GNOME
```

Se os dois últimos discordam, o texto digitado muda de cor conforme a sessão em
que o tilix abre — o mesmo perfil, dois resultados. Fixar o par
primeiro-plano/fundo (acima) tira o tema GTK da conta e resolve nas duas.

Para os demais (`alacritty`, `terminator`, `qterminal`, `yakuake`) o runbook não
tem receita automática: use a paleta de §7.1 na configuração de cada um.

## 7.6 O prompt de duas linhas

O prompt é do `~/.zshrc` do Kali (`/etc/skel/.zshrc`, copiado em
`docs/referencia/shell/kali-zshrc`):

```
┌──(usuario㉿kali)-[~/algum/caminho]
└─$
```

Estrutura: verde para usuário comum, azul dentro dos parênteses, `㉿` entre
usuário e máquina, caminho abreviado depois do sexto nível (`~/a/…/d/e/f`),
segunda linha com `$` (ou `#` vermelho para root) e uma linha em branco antes de
cada prompt.

Você já tem um `~/.zshrc` próprio, então **não sobrescreva**. Adicione só o
bloco do prompt ao fim do seu arquivo:

```zsh
# --- prompt estilo Kali -----------------------------------------------------
setopt promptsubst
PROMPT_EOL_MARK=""
prompt_symbol=㉿
# os dois lados do ㉿: %n = usuário da sessão, %m = nome da máquina
prompt_user=${KALI_PROMPT_USER:-%n}
prompt_host=${KALI_PROMPT_HOST:-%m}
PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}(%B%F{%(#.red.blue)}'$prompt_user$prompt_symbol$prompt_host$'%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└─%B%(#.%F{red}#.%F{blue}$)%b%F{reset} '
# opcional: código de saída e jobs à direita
# RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'
# linha em branco antes de cada prompt
precmd() { print "" }
# ---------------------------------------------------------------------------
```

O bloco do Kali usa `%n` e `%m` direto no `PROMPT`; aqui eles passam por duas
variáveis para que os rótulos possam ser trocados sem reescrever a linha do
`PROMPT` — que é o único lugar do runbook onde um erro de escape estraga o
prompt sem avisar.

### Trocar os rótulos dos dois lados do ㉿

`%n` é o usuário da sessão e `%m` o nome da máquina. Num Ubuntu de trabalho os
dois costumam ser longos e redundantes — o hostname vindo do instalador repete o
nome do usuário e acrescenta o modelo do equipamento —, e o prompt do Kali fica
com meia linha ocupada antes do caminho:

```bash
scripts/kali-look.sh prompt rotulo dev lab      # ┌──(dev㉿lab)-[~]
scripts/kali-look.sh prompt rotulo --padrao     # volta ao %n㉿%m
scripts/kali-look.sh prompt rotulo              # mostra o que está gravado
scripts/kali-look.sh prompt aplicar dev lab     # já aplica o bloco com os rótulos
```

O que isso muda e o que não muda:

- Muda **só o texto do prompt**. Nem o usuário da sessão, nem o hostname da
  máquina, nem o que o `ssh`, o `hostname` ou um log mostram.
- Rótulo aceita letra, dígito, ponto, hífen e sublinhado. Sem espaço e sem `%` —
  `%` é sequência de prompt do zsh, e um rótulo com `%` viraria outra coisa na
  tela.
- `KALI_PROMPT_USER` e `KALI_PROMPT_HOST` no ambiente ganham do valor gravado:
  `KALI_PROMPT_HOST=prod zsh` testa um rótulo sem editar arquivo.
- Aba já aberta não muda: o zsh lê o `.zshrc` ao iniciar. E o `status` passa a
  mostrar o par gravado:

```bash
scripts/kali-look.sh status | grep 'prompt no zsh'
#   prompt no zsh : aplicado — (dev㉿lab)
```

Se o bloco no seu `.zshrc` for de uma versão anterior a esta (sem as linhas
`prompt_user`/`prompt_host`), o `prompt rotulo` reescreve o bloco inteiro, com
backup em `~/.zshrc.bak-<data>` — ele avisa quando faz isso.

### Quando o bloco está no arquivo e o prompt não muda

É o sintoma mais enganoso desta página. Um framework de prompt — **oh-my-zsh com
um `ZSH_THEME`**, Powerlevel10k, Starship — redefine o `PROMPT` em cada `precmd`,
ou seja, **depois** de o seu `.zshrc` ter sido lido. O bloco do Kali fica no
arquivo, a variável até é lida certa por `zsh -i -c 'print $PROMPT'`, e a tela
mostra o outro prompt. Quem desenha por último ganha.

Como confirmar:

```bash
grep -nE '^[[:space:]]*(ZSH_THEME=|eval "\$\(starship|source.*powerlevel10k)' ~/.zshrc
scripts/kali-look.sh status | grep 'prompt no zsh'
#   "aplicado, mas SOBRESCRITO por: oh-my-zsh com ZSH_THEME=\"spaceship\""
```

Só um dos dois pode desenhar. Para ficar com o do Kali:

```bash
scripts/kali-look.sh prompt exclusivo   # aplica o bloco E desativa o concorrente
```

Ele mexe em **uma** linha, com backup em `~/.zshrc.bak-<data>`: `ZSH_THEME="algo"`
vira `ZSH_THEME=""`, e as linhas de `starship`/`powerlevel10k` são comentadas.
Plugins, aliases e o resto do oh-my-zsh continuam valendo — só o tema sai. Para
voltar ao seu prompt, reverta a linha marcada com `por kali-look`.

À mão, é o mesmo efeito:

```bash
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME=""/' ~/.zshrc   # com backup antes!
```

**A escolha tem custo real.** O prompt do Kali mostra usuário, host e caminho em
duas linhas, e nada além disso: quem vinha de um tema como o spaceship perde
branch do git, estado da árvore, duração do comando e versões de runtime. Se
esses dados fazem parte do seu trabalho, manter o seu tema é a decisão certa — o
terminal segue com as cores, a fonte e a transparência do Kali de qualquer forma.

Caveats:

- O `㉿` (U+327F) precisa de fonte com esse glifo. Cantarell e Fira Code o têm;
  se aparecer um retângulo vazio, troque para `@` ou instale
  `fonts-noto-core`.
- Nada disso muda quando você usa `bash`; o Kali tem o equivalente em
  `/etc/skel/.bashrc`, que também está no pacote `kali-defaults`.
- Cores dos diretórios no `ls` e realce do `grep` já vêm dos padrões do zsh do
  Kali; o seu `~/.zshrc` pode já ter isso.
