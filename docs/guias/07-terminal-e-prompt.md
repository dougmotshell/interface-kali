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

## 7.2 xfce4-terminal (ambiente Xfce)

```bash
mkdir -p ~/.config/xfce4/terminal
cp ~/Desktop/interface-kali/docs/referencia/shell/xfce4-terminalrc \
   ~/.config/xfce4/terminal/terminalrc
```

## 7.3 gnome-terminal (ambiente GNOME)

O `gnome-terminal` guarda cores por perfil, identificado por UUID:

```bash
P=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
G="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P/"

gsettings set $G palette "['#1F2229','#D41919','#5EBDAB','#FEA44C','#367BF0','#9755B3','#49AEE6','#E6E6E6','#198388','#EC0101','#47D4B9','#FF8A18','#277FFF','#962AC3','#05A1F7','#FFFFFF']"
gsettings set $G use-theme-colors true
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
cp ~/Desktop/interface-kali/docs/referencia/kde/Kali-Dark.{profile,colorscheme} \
   ~/.local/share/konsole/
kwriteconfig5 --file konsolerc --group "Desktop Entry" --key DefaultProfile Kali-Dark.profile
```

## 7.5 Outros terminais

O `kali-themes` também traz a mesma paleta para `tilix`
(`/usr/share/tilix/schemes/`), `alacritty` (`/etc/xdg/alacritty/alacritty.toml`),
`terminator`, `qterminal` e `yakuake`. Você já tem o Tilix instalado — se usar o
modo B de instalação dos assets, o esquema aparece na lista de esquemas dele.

## 7.6 O prompt de duas linhas

O prompt é do `~/.zshrc` do Kali (`/etc/skel/.zshrc`, copiado em
`docs/referencia/shell/kali-zshrc`):

```
┌──(douglas-silva㉿kali)-[~/algum/caminho]
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
PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}(%B%F{%(#.red.blue)}%n'$prompt_symbol$'%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└─%B%(#.%F{red}#.%F{blue}$)%b%F{reset} '
# opcional: código de saída e jobs à direita
# RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'
# linha em branco antes de cada prompt
precmd() { print "" }
# ---------------------------------------------------------------------------
```

Se você usa Powerlevel10k, Starship ou outro tema de prompt, ele sobrescreve o
`PROMPT` — escolha um dos dois. Para o visual do Kali, desative o outro tema.

Caveats:

- O `㉿` (U+327F) precisa de fonte com esse glifo. Cantarell e Fira Code o têm;
  se aparecer um retângulo vazio, troque para `@` ou instale
  `fonts-noto-core`.
- Nada disso muda quando você usa `bash`; o Kali tem o equivalente em
  `/etc/skel/.bashrc`, que também está no pacote `kali-defaults`.
- Cores dos diretórios no `ls` e realce do `grep` já vêm dos padrões do zsh do
  Kali; o seu `~/.zshrc` pode já ter isso.
