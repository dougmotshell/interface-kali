# 11. Problemas possíveis e como resolver

Catálogo de coisas que podem dar errado ao aplicar a aparência do Kali nesta
máquina (Ubuntu 24.04 / GNOME 46 / Wayland / GDM), no formato
**sintoma → causa → solução**.

Recorte dos documentos vizinhos:

- **este arquivo (11)** = diagnóstico e correção de sintomas;
- **[`10-rollback.md`](10-rollback.md)** = reverter *configuração* aplicada;
- **[`12-remover-ambientes.md`](12-remover-ambientes.md)** = desinstalar/remover
  *software* e assets.

> Regra de ouro antes de qualquer coisa: rode `scripts/00-backup.sh`. Com o dump
> do `dconf` na mão, quase tudo nesta página vira um comando de restauração.

---

## 11.1 Sessão e login

### Instalei tudo, reiniciei, e a sessão nova está com o tema padrão dela

**Sintoma.** O `instalar xfce` correu bem, o boot já mostra a logo do Kali, mas a
sessão Xfce abre com **Greybird** e ícones `elementary-xfce-dark` — o tema padrão
do Xfce, não o do Kali. No GNOME, o Yaru roxo segue no lugar.

**Causa.** `instalar` e `aplicar` são passos **separados**, e o `aplicar` só
funciona de dentro da sessão que ele configura: a aparência é gravada no serviço
de configuração do próprio ambiente (`xfconf` no Xfce, `kconfig` no Plasma,
`dconf` no GNOME). Rodado de fora — do GNOME, por exemplo — o comando é
**recusado**, com esta mensagem:

```
✗ esta ação precisa rodar dentro da sessão xfce (sessão atual: ubuntu:GNOME).
```

É fácil perder esse erro entre as dezenas de linhas de saída do `apt`, reiniciar
e concluir que o runbook falhou.

**Solução.** Entre na sessão certa e rode o `aplicar` lá dentro:

```bash
# 1. logout (não precisa reiniciar) e escolha "Xfce" na tela de login
# 2. abra um terminal JÁ na sessão Xfce:
scripts/kali-look.sh aplicar xfce
scripts/kali-look.sh painel xfce   # o painel é etapa separada
```

**Como confirmar sem adivinhar.** O log registra toda invocação, inclusive as
recusadas:

```bash
grep -c 20-aplicar-xfce ~/.local/state/kali-look-backup/kali-look.log
# 0 = o aplicar nunca rodou; qualquer número > 0 = rodou
grep ERRO ~/.local/state/kali-look-backup/kali-look.log | tail
```

E o `status` mostra o que está em uso de fato — se a linha "tema GTK" do Xfce diz
`Greybird`, a aparência não foi aplicada:

```bash
scripts/kali-look.sh status
```

### A tela de login não tem nada do Kali

**Sintoma.** O boot mostra a logo do Kali (Plymouth e GRUB), mas a tela de login
é a genérica — nenhum fundo do Kali, nenhum logo.

**Causa.** Duas possíveis, e o `status` distingue:

- Você trocou o gerenciador de login para o **LightDM** e parou aí. Instalar o
  LightDM só troca *qual programa* desenha a tela; o greeter continua com o tema
  padrão. Pior: a partir daí o logo aplicado ao GDM (§8.3) fica **inerte**, então
  um `status` que diz "logo do GDM: aplicado" não significa que a tela mudou.
- Você seguiu no **GDM**. Aí o único item disponível é o logo — o fundo do GDM
  está compilado no `gresource` do `gnome-shell` e trocá-lo não é recomendado
  ([`08-boot-login-e-logos.md`](08-boot-login-e-logos.md) §8.3).

**Solução.** No LightDM, tematize o greeter (é um passo próprio, e exige os
assets no **sistema**, porque o greeter não lê o seu `$HOME`):

```bash
scripts/kali-look.sh greeter status     # diagnóstico: quem está ativo, o que falta
scripts/kali-look.sh assets --sistema   # se faltar tema/ícone/fundo em /usr/share
scripts/kali-look.sh greeter aplicar    # confirmação dupla + backup datado
```

O efeito aparece no **próximo logout**. Se a tela de login não subir, entre em um
console com `Ctrl+Alt+F3` e rode `scripts/kali-look.sh greeter reverter`.

### A sessão não abre e volta para a tela de login

**Sintoma.** Você digita a senha, a tela pisca e volta para o GDM (o "loop de
login").

**Causa.** Quase sempre configuração do *usuário*: extensão de shell
incompatível, tema de shell quebrado, `~/.config/xfce4` inconsistente ou
`~/.config/kdeglobals`/`kwinrc` apontando para um componente inexistente. Menos
comum: falta de espaço em disco (§11.9) ou permissão errada em `~/.Xauthority`.

**Solução.** Entre em um console de texto e desfaça pela linha de comando:

1. `Ctrl+Alt+F3` → login com usuário e senha (sem ambiente gráfico).
2. Conforme a sessão que falhou:

```bash
# GNOME: desliga tema de shell e extensões de terceiros
gsettings set org.gnome.shell.extensions.user-theme name ''
gsettings reset org.gnome.shell enabled-extensions
# ou, mais agressivo, volta todo o GNOME ao padrão do Ubuntu:
dconf reset -f /org/gnome/

# Xfce: tira a configuração do caminho, sem apagar
mv ~/.config/xfce4 ~/.config/xfce4.bak

# Plasma: idem
mkdir -p ~/config-plasma.bak
mv ~/.config/kdeglobals ~/.config/kwinrc ~/.config/plasmarc ~/config-plasma.bak/ 2>/dev/null
```

3. `Ctrl+Alt+F1` (ou `Ctrl+Alt+F2`) volta para a tela do GDM. Se preferir,
   `sudo systemctl restart gdm3` reinicia a tela de login.

**Teste decisivo** para saber se o problema é do seu usuário ou do sistema: crie
um usuário limpo e tente a mesma sessão com ele.

```bash
sudo adduser teste-kali        # depois: sudo deluser --remove-home teste-kali
```

Se com o usuário novo a sessão abre, o problema está no seu `$HOME`.

### Tela preta depois do login (sem cursor, sem painel)

**Causa.** No Xfce/Plasma sobre Xorg, geralmente compositor ou driver; no GNOME,
tema de shell inválido.

**Solução.**

```bash
# Xfce: desliga o compositor
xfconf-query -c xfwm4 -p /general/use_compositing -s false

# Plasma: desliga o compositor na inicialização
kwriteconfig5 --file kwinrc --group Compositing --key Enabled false
```

Se a tela preta é *antes* do login, veja o item seguinte.

### O GDM não sobe (fica no texto de boot ou em tela preta antes do login)

**Solução.**

```bash
systemctl status gdm3            # ativo? falhou?
journalctl -b -u gdm3 --no-pager | tail -40
sudo systemctl restart gdm3
```

Se o serviço não existe mais como padrão, é porque algum pacote assumiu o posto
(SDDM ou LightDM) — item abaixo.

### Instalei o SDDM (ou o LightDM) e agora a tela de login é outra

**Causa.** No Debian/Ubuntu só **um** gerenciador de login fica ativo. Instalar
`sddm` ou `lightdm` dispara um diálogo do `debconf` que pergunta qual usar — e é
fácil confirmar sem ler.

**Solução.** Volte ao GDM:

```bash
sudo dpkg-reconfigure gdm3       # escolha "gdm3" na lista
# alternativa direta:
sudo systemctl disable sddm lightdm 2>/dev/null
sudo systemctl enable gdm3
sudo systemctl restart gdm3
```

Confira quem está no comando:

```bash
cat /etc/X11/default-display-manager
systemctl status display-manager --no-pager | head -3
```

Este material recomenda **não** trocar o gerenciador de login
(`08-boot-login-e-logos.md` §8.4): o ganho visual é a tela de entrada, e o risco
atinge todas as sessões.

Se a troca já foi feita e você quer **ficar** no LightDM, o ganho visual só chega
com o passo de tematização — `scripts/kali-look.sh greeter aplicar`, item "A tela
de login não tem nada do Kali" acima.

---

## 11.2 GNOME

### O tema de shell `Kali-Dark` não aplica (a barra superior continua igual)

Três causas possíveis, em ordem de frequência:

| Causa | Verificação | Solução |
|---|---|---|
| Extensão `user-theme` não instalada | `gnome-extensions list \| grep -i user-theme` (vazio) | `sudo apt install gnome-shell-extensions` |
| Extensão instalada mas desabilitada | `gnome-extensions info user-theme@gnome-shell-extensions.gcampax.github.com` | `gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com` |
| Tema não está em um caminho lido | `ls ~/.themes/Kali-Dark/gnome-shell/gnome-shell.css` | rode `scripts/10-baixar-assets.sh --instalar-usuario` |

E, em Wayland, **não existe** recarregar o shell: `Alt+F2` → `r` só funciona em
Xorg. Faça logout/login.

```bash
gsettings get org.gnome.shell.extensions.user-theme name   # deve responder 'Kali-Dark'
```

### O tema de shell aplica, mas há elementos fora de lugar

**Causa.** O `Kali-Dark/gnome-shell` do pacote atual foi feito para o GNOME do
Kali (48/49); aqui é o 46. O CSS carrega — ele já traz as regras de *quick
settings* — mas seletores novos/renomeados podem deixar espaçamentos estranhos.

**Solução.** Se algo ficar ilegível, desligue **só** o tema de shell; o resto
(GTK, ícones, fontes, wallpaper) continua valendo:

```bash
gsettings set org.gnome.shell.extensions.user-theme name ''
```

### Os aplicativos não escurecem / continuam com o roxo do Yaru

```bash
gsettings get org.gnome.desktop.interface gtk-theme      # esperado: 'adw-gtk3-dark'
gsettings get org.gnome.desktop.interface color-scheme   # esperado: 'prefer-dark'
ls ~/.themes/adw-gtk3-dark/gtk-3.0/gtk.css               # o tema tem de existir
```

Se `gtk-theme` está correto e nada muda, o tema não foi instalado: o
`adw-gtk3-dark` vem do `.deb` `adw-gtk3-kali` (não existe nos repositórios do
Ubuntu — `01-analise-do-sistema-atual.md` §1.5).

---

## 11.3 Ícones e fontes

### Faltam ícones (quadrados vazios, ícones genéricos em alguns menus)

**Causa.** O `Flat-Remix-Blue-Dark` declara
`Inherits=breeze-dark,elementary,Adwaita,gnome,hicolor`, e **`breeze-dark` e
`elementary` não existem neste Ubuntu** — confirmado na máquina de referência. O Kali
resolve isso porque instala o `breeze-dark` junto. Quando um ícone não está no
Flat-Remix, a cadeia cai direto no `Adwaita`, e alguns aplicativos acabam sem
ícone próprio.

**Solução.**

```bash
# 1) instalar o tema herdado (opcional, ~poucos MB)
sudo apt install breeze-icon-theme

# 2) reconstruir o cache do tema
gtk-update-icon-cache -f ~/.local/share/icons/Flat-Remix-Blue-Dark
# no modo sistema:
sudo gtk-update-icon-cache -f /usr/share/icons/Flat-Remix-Blue-Dark
```

Confirme se o pacote `breeze-icon-theme` fornece o diretório esperado com
`dpkg -L breeze-icon-theme | grep -m1 breeze-dark`.

### O ícone do menu do painel (dragão) não aparece

**Causa.** O ícone `kali-panel-menu` mora **dentro** do tema de ícones. Se o tema
ativo não é um `Flat-Remix-*`, o nome não resolve.

```bash
find ~/.local/share/icons /usr/share/icons -name 'kali-panel-menu*' 2>/dev/null
```

### `Fira Code Medium` não é encontrada (o terminal usa outra fonte)

**Causa.** Esta máquina tem `FiraCode Nerd Font` (uma variante *patched*), cuja
família tem **nome diferente**. Configurações que pedem `Fira Code Medium 10` não
casam com ela.

**Solução.**

```bash
sudo apt install fonts-firacode fonts-cantarell
fc-cache -f
fc-list : family | tr ',' '\n' | grep -iE '^fira code|^cantarell' | sort -u
```

Se preferir manter a Nerd Font, ajuste o *nome* nas configurações em vez de
instalar a fonte — por exemplo
`gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font Med 10'`.

### O `㉿` do prompt aparece como retângulo vazio

**Causa.** A fonte do terminal não tem o glifo U+327F.

**Solução.** Use uma fonte que o tenha (Fira Code e as Nerd Fonts têm), ou
instale uma cobertura ampla:

```bash
sudo apt install fonts-noto-core
fc-cache -f
# teste rápido:
printf '㉿\n'
```

Se continuar quadrado, troque o símbolo no bloco do prompt:
`prompt_symbol=@`.

---

## 11.4 Terminal e prompt

### O prompt de duas linhas não aparece

**Causa.** Outro tema de prompt assume depois: Powerlevel10k
(`~/.p10k.zsh` + `source .../powerlevel10k.zsh-theme`), Starship
(`eval "$(starship init zsh)"`) ou um framework (oh-my-zsh) definem `PROMPT`
depois do seu bloco.

**Solução.** Escolha um. Para ficar com o do Kali, comente a inicialização do
outro no `~/.zshrc` e garanta que o bloco do Kali seja o **último** a definir
`PROMPT`:

```bash
grep -nE 'p10k|powerlevel|starship|oh-my-zsh|PROMPT=' ~/.zshrc
```

Depois: `exec zsh` para recarregar.

### Apliquei a paleta e o terminal continua igual

**Sintoma.** O tema das janelas mudou, o painel mudou, mas o terminal segue com as
cores de antes.

**Causa.** Quase sempre não é a paleta — é **outro terminal**. O
`~/.config/xfce4/terminal/terminalrc` configura o `xfce4-terminal` e mais nenhum.
Se o que abre é `tilix`, `terminator` ou `gnome-terminal`, nada muda.

Duas coisas decidem qual abre:

| O que abre | Resolvido por | Como ver |
|---|---|---|
| `Super+T`, `Ctrl+Alt+T`, launcher do painel (`exo-open --launch TerminalEmulator`) | `~/.config/xfce4/helpers.rc` | `awk -F= '/^TerminalEmulator=/{print $2}' ~/.config/xfce4/helpers.rc` |
| "Root Terminal" do painel (`pkexec x-terminal-emulator`) | alternativa do dpkg (global) | `update-alternatives --query x-terminal-emulator \| grep '^Value:'` |

**Solução.** Deixe o script resolver — ele identifica o terminal em que você está
e diz o que fazer:

```bash
scripts/kali-look.sh terminal auto    # aplica no terminal em uso
scripts/kali-look.sh terminal xfce    # paleta + terminal preferido + alternativa
scripts/kali-look.sh status           # mostra os dois valores acima
```

Se você prefere continuar no tilix, a paleta do Kali existe para ele:
`scripts/kali-look.sh terminal tilix` (ver
[`07-terminal-e-prompt.md`](07-terminal-e-prompt.md) §7.5).

**Terceira causa, mais boba:** a janela já estava aberta. O xfce4-terminal lê o
`terminalrc` na inicialização — abra uma nova.

### As cores do terminal não mudaram

O `gnome-terminal` guarda cores **por perfil**. Se você tem vários, o comando do
guia altera só o padrão:

```bash
gsettings get org.gnome.Terminal.ProfilesList list       # todos os UUIDs
gsettings get org.gnome.Terminal.ProfilesList default    # o que os scripts usam
```

E `use-theme-colors=true` faz o fundo/frente vir do tema — se você tinha cores
personalizadas, elas deixam de ser aplicadas de propósito.

---

## 11.5 Instalação dos assets

### `dpkg -i adw-gtk3-kali...deb` falha com `Breaks: libgtk-4-1 (<< 4.16)`

**Causa.** Real e esperada: este Ubuntu tem GTK4 **4.14.5**, e o pacote exige
4.16+.

**Solução.** Não force. O pacote só carrega arquivos de tema; instale-o no modo
por usuário:

```bash
dpkg-deb -x ~/.cache/kali-assets/adw-gtk3-kali_*.deb /tmp/adw
mkdir -p ~/.themes && cp -a /tmp/adw/usr/share/themes/adw-gtk3* ~/.themes/
```

(É exatamente o que `scripts/10-baixar-assets.sh --instalar-sistema` já faz para
este pacote.) Se insistir em `dpkg -i --force-depends`, o tema GTK4 dele pode
apresentar defeitos no GTK 4.14 e o `apt` passa a reclamar de dependências
quebradas em toda operação futura.

### O `.deb` baixado tem 0 byte

**Causa.** `http.kali.org` redireciona para um espelho (`kali.download`). Sem
`-L`, o `curl` grava a resposta de redirecionamento — arquivo vazio. Aconteceu
durante a preparação deste material.

**Solução.**

```bash
curl -fL --retry 3 -O https://kali.download/kali/pool/main/k/kali-themes/kali-themes-common_2026.3.0_all.deb
ls -lh *.deb                      # confira o tamanho (~7 MB)
dpkg-deb -f kali-themes-common_2026.3.0_all.deb Package Version
```

Um `.deb` truncado também dá `is not a Debian format archive` — mesmo remédio.

### Alguém adicionou o repositório `kali-rolling` ao APT

**Sintoma.** `apt upgrade` propõe centenas de pacotes, incluindo `libc6`,
`systemd`, `libgtk-*`; ou o `apt` reclama de conflitos insolúveis.

**Causa.** O clássico "FrankenDebian": misturar Kali (Debian
testing/unstable) com Ubuntu 24.04.

**Solução — pare antes de qualquer `upgrade`/`dist-upgrade`:**

```bash
# 1) localizar a fonte
grep -rIl 'kali' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null

# 2) remover (ou renomear para .disabled)
sudo mv /etc/apt/sources.list.d/<arquivo-kali>.list{,.disabled}
sudo rm -f /etc/apt/trusted.gpg.d/kali*.gpg /etc/apt/keyrings/kali*  # se houver

# 3) reindexar e conferir o estrago
sudo apt update
apt list --upgradable | head -50
```

Se **nada** foi instalado de lá, remover a fonte encerra o assunto. Se já houve
instalação, identifique os pacotes de origem Kali e reverta para a versão do
Ubuntu com *pinning*:

```bash
apt list --installed 2>/dev/null | grep -i kali
sudo apt install --reinstall <pacote>/noble        # força a versão do Ubuntu
```

Confirme cada reversão com `apt-cache policy <pacote>` antes de aplicar; se
muitos pacotes de base foram trocados, restaurar backup do sistema é mais rápido
e mais seguro do que consertar peça por peça.

---

## 11.6 Xfce

### O menu do painel está sem o dragão e sem os favoritos do Kali

**Sintoma.** O painel tem o layout do Kali, mas o botão do menu mostra o ícone
genérico do Xfce, e os favoritos são os padrão — não os do Kali.

**Causa.** Duas, e podem se somar:

1. **Ordem invertida.** `xfce4-panel-profiles load` **substitui**
   `~/.config/xfce4/panel/` inteiro. Rodado *depois* do `aplicar xfce`, ele apaga
   os complementos que aquele passo tinha posto lá.
2. **O `.rc` não vale mais.** O `xfce4-whiskermenu-plugin` **2.8** (Ubuntu 24.04)
   guarda a configuração no **xfconf**; o antigo
   `~/.config/xfce4/panel/whiskermenu-<id>.rc` é migrado e **apagado** na
   primeira execução do plugin. Copiar o arquivo não tem efeito nenhum — e
   reiniciar o painel logo depois de copiá-lo o remove.

**Solução.** Rode a etapa de painel, que faz as duas coisas na ordem certa
(carrega o perfil primeiro, depois grava as chaves no xfconf do plugin certo):

```bash
scripts/kali-look.sh painel xfce
```

**Conferir sem adivinhar** — o que vale é o xfconf, não o arquivo:

```bash
# descobre o id do plugin e lê a config em uso
for i in $(seq 1 30); do
  [ "$(xfconf-query -c xfce4-panel -p /plugins/plugin-$i 2>/dev/null)" = whiskermenu ] \
    && N=$i && break
done
xfconf-query -c xfce4-panel -p /plugins/plugin-$N/button-icon   # esperado: kali-panel-menu
xfconf-query -c xfce4-panel -p /plugins/plugin-$N/menu-width    # esperado: 570
```

Se `button-icon` já é `kali-panel-menu` e o ícone continua genérico, o problema é
o tema de ícones: o `kali-panel-menu.svg` vem de `kali-themes-common`, em
`Flat-Remix-Blue-Dark/apps/scalable/` (§11.3).


| Sintoma | Causa | Solução |
|---|---|---|
| `xfce4-panel-profiles load` não existe | pacote ausente | `sudo apt install xfce4-panel-profiles` |
| O painel carregou, mas o plugin de VPN mostra erro | o `genmon` aponta para `/usr/share/kali-themes/xfce4-panel-genmon-vpnip.sh`, que só existe no modo sistema | clique direito no plugin → Propriedades → aponte para `~/.local/share/kali-themes/xfce4-panel-genmon-vpnip.sh` |
| O Whisker Menu ficou com o tamanho/ícone padrão | no plugin 2.8 a config está no **xfconf**, não no `.rc` — ver o item dedicado no início desta seção | `scripts/kali-look.sh painel xfce` |
| Mudanças no `xfconf` não pegam | as configurações são lidas na entrada da sessão | logout/login na sessão Xfce, ou `xfce4-panel -r` para só o painel |
| O wallpaper não muda | a propriedade varia por monitor/workspace | `xfconf-query -c xfce4-desktop -l \| grep -E 'last-image$\|image-path$'` e defina cada uma |
| Não há sessão "Xfce" no GDM | o `xfce4` não terminou de instalar | `ls /usr/share/xsessions` — hoje esta máquina só tem `ubuntu.desktop` e `ubuntu-xorg.desktop` |

---

## 11.7 KDE Plasma

| Sintoma | Causa | Solução |
|---|---|---|
| A decoração de janela não fica igual à do Kali | `library=org.kali.kali` é plugin binário do pacote `kwin-style-kali`, feito para Plasma 6; aqui é 5.27 | use `org.kde.breeze` com a ordem de botões do Kali (`05-ambiente-kde-plasma.md` §5.4). Não há solução dentro do Ubuntu 24.04 |
| `kwriteconfig6: command not found` | Plasma 5 usa os binários `*5` | use `kwriteconfig5`, `plasma-apply-*` (o script `30-aplicar-plasma.sh` já detecta) |
| `plasma-apply-lookandfeel` diz que o tema não existe | assets não instalados, ou instalados só em `~` sem o Plasma ter recarregado | confirme `ls ~/.local/share/plasma/look-and-feel/` ou `/usr/share/plasma/look-and-feel/`; reinicie a sessão Plasma |
| O tema global aplica, mas apps GTK ficam claros | falta a ponte GTK do Plasma | `sudo apt install kde-config-gtk-style` e escolha `Kali-Dark` em *Aparência → Estilo de aplicativos → GNOME/GTK* |
| O painel não tem o dragão | o script de customização não rodou | veja `05-ambiente-kde-plasma.md` §5.5; alternativa manual: clique direito no menu → Configurar → ícone |
| Instalei `sddm` sem querer | dependência de `kali-desktop-kde` | §11.1, `dpkg-reconfigure gdm3` |

---

## 11.8 Boot e login (Plymouth, GRUB)

| Sintoma | Causa | Solução |
|---|---|---|
| O tema do GRUB não aparece | o Ubuntu esconde o menu quando há só um SO instalado | segure `Shift` (BIOS) ou `Esc` (UEFI) no boot; ou ajuste `GRUB_TIMEOUT_STYLE=menu` em `/etc/default/grub` |
| Editei o GRUB e nada mudou | falta aplicar | `sudo update-grub` (guarde antes: `sudo cp /boot/grub/grub.cfg /boot/grub/grub.cfg.bak`) |
| O Plymouth continua o do Ubuntu | falta aplicar no initramfs | `sudo update-initramfs -u` depois de trocar a alternativa |
| O texto do Plymouth do Kali não aparece | o tema usa o módulo `label` | `sudo apt install plymouth-label` |
| `update-alternatives --config default.plymouth` diz que só há uma opção | na máquina de referência havia apenas `bgrt` registrado | instale `plymouth-themes` e/ou registre o tema do Kali com `--install`, como em `08-boot-login-e-logos.md` §8.5 |
| O logo do Kali não aparece no GDM | o `dconf` do GDM não foi atualizado | `sudo dconf update` e reinicie o GDM |
| O fundo do GDM continua o do Ubuntu | está compilado dentro de `gnome-shell-theme.gresource` | comportamento esperado; §8.3 explica por que não vale mexer |

---

## 11.9 Espaço em disco

**Sintoma.** `dpkg` falha no meio, a sessão não abre, o GNOME reclama de disco
cheio.

**Causa.** Esta máquina está com **88% de `/` em uso (28 GB livres)**. Os assets
do Kali ocupam ~95 MB, mas o Xfce completo pede ~400 MB e o Plasma ~700 MB — e
o `apt` precisa de espaço extra para baixar e descompactar.

**Medir antes:**

```bash
df -h /                                       # espaço livre
apt-get install --no-install-recommends -s xfce4 | tail -5   # simulação: quanto será usado
```

**Liberar:**

```bash
sudo apt autoremove --purge
sudo apt clean                                # cache de .deb
journalctl --disk-usage
sudo journalctl --vacuum-time=14d
rm -rf ~/.cache/kali-assets                   # depois de instalar os assets
du -xh --max-depth=1 ~ 2>/dev/null | sort -h | tail -15
```

---

## 11.10 "Misturei as configurações de dois ambientes"

**Sintoma.** Depois de testar Xfce e Plasma, a sessão GNOME ficou com fonte
estranha, cursor errado ou barra de título diferente.

**Causa.** A maioria das configurações é isolada por ambiente — `xfconf` para o
Xfce, `~/.config/kdeglobals` para o Plasma, `dconf` para o GNOME. Mas três
camadas são **compartilhadas**:

| Camada compartilhada | Arquivo | Efeito |
|---|---|---|
| GTK 3 | `~/.config/gtk-3.0/settings.ini` | tema/ícones/fonte para todo app GTK3, em qualquer sessão |
| GTK 4 | `~/.config/gtk-4.0/settings.ini` | idem para GTK4 |
| Qt | `QT_QPA_PLATFORMTHEME` em `~/.profile` ou `/etc/profile.d/` | estilo dos apps Qt fora do Plasma |

**Solução.** Deixe o `settings.ini` fora do jogo e configure cada ambiente pela
sua própria via (`dconf`/`xfconf`/`kdeglobals`):

```bash
mv ~/.config/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini.bak 2>/dev/null
mv ~/.config/gtk-4.0/settings.ini ~/.config/gtk-4.0/settings.ini.bak 2>/dev/null
```

Cada sessão volta a mandar em si mesma no próximo login. Para saber em qual você
está: `echo $XDG_CURRENT_DESKTOP`.

---

## 11.11 Sintomas típicos de Wayland → Xorg

Sua sessão de hoje é GNOME em Wayland; Xfce e "Plasma (X11)" são Xorg. Os
sintomas abaixo aparecem no primeiro dia na sessão nova e **não** são defeito de
tema. O mapa completo, item por item, está em
[`13-wayland-vs-xorg.md`](13-wayland-vs-xorg.md).

| Sintoma | Causa | Solução |
|---|---|---|
| Compartilhamento de tela no Slack/Teams/Meet abre a lista vazia ou não mostra janelas | dono da captura mudou; no Xorg o app captura direto, mas o app pode ter cacheado a escolha do portal | feche e reabra o app na sessão nova; escolha "Tela inteira" uma vez. Se persistir, confirme que `xdg-desktop-portal-gtk` está rodando: `systemctl --user status xdg-desktop-portal-gtk` |
| O diálogo de senha nunca aparece e a ação simplesmente não acontece (discos, GParted, atualização) | não há agente gráfico do polkit na sessão Xfce | `sudo apt install mate-polkit` e faça logout/login. Verifique se está no ar: `pgrep -af polkit-mate-authentication-agent` |
| O chaveiro pede senha a cada boot (Chrome, Brave, Slack, Bitwarden esquecem senhas) | o destravamento por PAM não está no gerenciador de login em uso. No Ubuntu 24.04 o pacote `lightdm` **já** instala as linhas, então trocar o GDM pelo LightDM por si só não causa isso — verifique antes de culpar a troca | `grep -rn pam_gnome_keyring /etc/pam.d/lightdm*` (o esperado são 4 linhas, em `lightdm` e `lightdm-greeter`); se faltarem, adicione `-auth optional pam_gnome_keyring.so` e `-session optional pam_gnome_keyring.so auto_start`, ou volte ao GDM (guia 08 §8.4) |
| Atalhos de teclado que eu usava sumiram | os do GNOME ficam no `dconf`, o Xfce lê o canal `xfconf` `xfce4-keyboard-shortcuts` — bancos e nomes de ação diferentes | `scripts/kali-look.sh atalhos status` mostra a diferença e `… atalhos migrar` grava os seus no `xfwm4` (guia 04 §4.7). Não precisa ter salvado nada antes: o `dconf` é do usuário, não da sessão |
| Gestos de touchpad de 3/4 dedos pararam | o Mutter tem gestos nativos, o Xorg não | `touchegg` ou `libinput-gestures` — confirme com `apt-cache policy touchegg libinput-gestures` |
| A luz noturna (tela mais quente à noite) desapareceu | é um recurso do GNOME; o Xfce não tem | `redshift-gtk`, `gammastep` ou `xsct` |
| No OBS, a fonte de captura de tela aparece vazia ou preta | fontes PipeWire (do Wayland) não funcionam no Xorg | crie uma fonte nova: *Captura de tela (XSHM)* ou *Captura de janela (Xcomposite)*. As fontes antigas não se convertem |
| `grim` não captura nada | é ferramenta só-Wayland — e aqui já não funcionava | use `xfce4-screenshooter`, `scrot` ou a tecla `Print` |

---

## 11.12 Diagnóstico rápido

Copie e cole conforme o caso — todos são de leitura, nenhum altera o sistema.

**Onde estou:**

```bash
echo "$XDG_CURRENT_DESKTOP / $XDG_SESSION_TYPE / $DESKTOP_SESSION"
cat /etc/X11/default-display-manager
ls /usr/share/xsessions /usr/share/wayland-sessions
```

**GNOME:**

```bash
gsettings get org.gnome.desktop.interface gtk-theme
gsettings get org.gnome.desktop.interface icon-theme
gsettings get org.gnome.desktop.interface font-name
gsettings get org.gnome.desktop.interface monospace-font-name
gsettings get org.gnome.shell.extensions.user-theme name
gsettings get org.gnome.desktop.background picture-uri
gnome-extensions list --enabled
```

**Xfce:**

```bash
xfconf-query -c xsettings -l -v
xfconf-query -c xfwm4 -p /general/theme
xfconf-query -c xfce4-desktop -l | grep -E 'last-image$|image-path$'
ls ~/.config/xfce4/panel/
```

**Plasma:**

```bash
grep -E 'ColorScheme|Theme|widgetStyle|fixed|font' ~/.config/kdeglobals
grep -A3 kdecoration2 ~/.config/kwinrc
ls ~/.local/share/plasma/look-and-feel/ /usr/share/plasma/look-and-feel/ 2>/dev/null
```

**Temas, ícones e fontes disponíveis:**

```bash
ls ~/.themes /usr/share/themes
ls ~/.local/share/icons /usr/share/icons
fc-list : family | tr ',' '\n' | grep -iE '^cantarell|^fira code' | sort -u
```

**Logs:**

```bash
journalctl -b -u gdm3 --no-pager | tail -40          # tela de login
journalctl -b --user -u gnome-shell --no-pager | tail -40
journalctl -b _COMM=gnome-shell -p warning --no-pager | tail -30
cat ~/.xsession-errors 2>/dev/null                    # sessões Xorg; ausente hoje (Wayland)
sudo dmesg -T | tail -20
```

**Pacotes e alternativas:**

```bash
dpkg -l | grep -E 'kali-themes|kali-wallpapers|adw-gtk3'
apt-mark showmanual | grep -E 'xfce|plasma|kde|lightdm|sddm'
update-alternatives --query default.plymouth | head -8
```
