# 13. Wayland (hoje) vs Xorg (Xfce e Plasma)

A sessão que você usa hoje é **GNOME 46 em Wayland**. As sessões que este
material instala — Xfce e "Plasma (X11)" — rodam em **Xorg**. Isso não é detalhe
de aparência: muda o compositor, o portal de integração, quem é o dono dos
atalhos globais e da captura de tela, como a bandeja do sistema funciona e como a
escala de tela é calculada.

Nenhum aplicativo instalado aqui *deixa de abrir* por causa disso. O que muda é a
integração: recursos que hoje vêm do GNOME Shell (extensões, luz noturna,
gestos, captura) não existem no Xfce, e precisam de substituto ou deixam de
existir.

Este guia lista, item por item, o que acontece. A tabela abaixo foi levantada na
**máquina de referência** do guia 01 (Ubuntu 24.04, GNOME 46 em Wayland, GDM) —
use-a como mapa, e rode a checagem na sua própria máquina antes de trocar de
sessão:

```bash
scripts/50-analise-wayland-xorg.sh
```

Ele classifica cada achado nas mesmas severidades usadas aqui e grava um
relatório em `relatorios/`.

## 13.1 O que muda por baixo

| Camada | GNOME/Wayland (hoje) | Xfce/Xorg (e Plasma X11) |
|---|---|---|
| Compositor | Mutter (compositor + servidor gráfico) | Xorg como servidor + `xfwm4` (ou KWin) como compositor |
| Portal de integração | `xdg-desktop-portal-gnome` | `xdg-desktop-portal-gtk` (ambos já instalados aqui) |
| Isolamento de entrada | Wayland impede que um app leia/injete eventos de outro | X11 permite: `xdotool`, `XTEST`, `xclip`, gravadores de tela antigos |
| Captura de tela | só via portal / GNOME Shell | qualquer app pode capturar (`scrot`, `xfce4-screenshooter`, Peek) |
| Escala | fracionária, por monitor | inteira e global (`Xft/DPI`, `Gdk/WindowScalingFactor`) |
| Atalhos globais | GNOME Shell + `settings-daemon` | `xfce4-keyboard-shortcuts` (o Kali traz o seu) |
| Bandeja do sistema | extensão `appindicators` (StatusNotifier) | plugin `systray` do `xfce4-panel` |
| Ícones na área de trabalho | extensão `ding` | `xfdesktop` (nativo) |

Consequência de fundo: **extensão do GNOME Shell é código que roda dentro do
GNOME Shell**. Fora dele não existe — não há "porta" de extensão para o Xfce.
Cada uma das suas 13 extensões ativas precisa de um substituto nativo, ou o
recurso desaparece.

## 13.2 Inventário da máquina de referência

Severidades: `QUEBRA` (o recurso deixa de existir) · `DEGRADA` (existe pior ou
exige software extra) · `MUDA` (existe, mas em outro lugar/formato) · `MELHORA` ·
`OK` (nada a fazer).

### Extensões do GNOME ativas

| Extensão | Sev. | O que acontece | O que fazer |
|---|---|---|---|
| `dash-to-dock` | QUEBRA | não há dock no Xfce | o painel do Kali já faz o papel: lançadores + `tasklist`. Se quiser um dock de verdade, confirme com `apt-cache policy plank` |
| `ubuntu-dock` | QUEBRA | mesma extensão, variante do Ubuntu | idem acima; irrelevante fora do GNOME |
| `tiling-assistant` | QUEBRA | encaixe de janelas por atalho/borda | `xfwm4` tem encaixe nativo (`Super`+setas e arraste até a borda); no Plasma, o KWin tem o próprio |
| `ubuntu-appindicators` | QUEBRA (função nativa) | ícones de bandeja de apps | plugin `systray` do `xfce4-panel` 4.18 — já vem no layout do Kali, com suporte a StatusNotifier; se algum ícone não aparecer, confirme a opção "StatusNotifier" nas propriedades do plugin |
| `clipboard-indicator` | QUEBRA | histórico de área de transferência | `xfce4-clipman-plugin` (1.6.5 disponível) |
| `emoji-copy` | QUEBRA | seletor de emoji por atalho | sem equivalente de painel. O app **Caracteres** (`gnome-characters`) funciona como aplicativo em qualquer sessão; o atalho global, não |
| `Bluetooth-Battery-Meter` | QUEBRA | bateria de fones/mouse BT no painel | `blueman` (2.3.5) mostra bateria de parte dos dispositivos — confirme com o seu aparelho |
| `bluetooth-battery` | QUEBRA | idem | idem |
| `burn-my-windows` | QUEBRA | animações de abrir/fechar | `xfwm4` só tem compositor simples (sombra, transparência). No **Plasma**, o KWin tem efeitos nativos equivalentes |
| `compiz-windows-effect` | QUEBRA | janelas "gelatinosas" | no Plasma existe o efeito nativo *Wobbly Windows*; no Xfce, não há |
| `compiz-alike-magic-lamp-effect` | QUEBRA | minimizar em "lâmpada" | no Plasma existe *Magic Lamp*; no Xfce, não há |
| `Battery-Health-Charging` | QUEBRA | limite de carga da bateria | o kernel expõe `/sys/class/power_supply/BAT0/charge_control_end_threshold` (existia na máquina de referência, em `100`). Sem interface gráfica: escreva o valor como root (não persiste no boot) ou use `tlp` com `STOP_CHARGE_THRESH_BAT0` |
| `ding` | MUDA | ícones na área de trabalho | `xfdesktop` faz isso nativamente, e o `xfce4-desktop.xml` do Kali já configura (48 px, Home/sistema/removíveis/lixeira) |

Nada disso precisa ser desinstalado: as extensões continuam válidas e voltam a
funcionar quando você entrar na sessão GNOME.

### Sessão, entrada e serviços

| Item | Sev. | O que acontece | O que fazer |
|---|---|---|---|
| Agente gráfico do polkit | QUEBRA | sem agente, o diálogo de senha **nunca aparece** e a ação falha calada (GParted, gnome-disks, atualizações) | instale `mate-polkit` (é o que o `kali-desktop-xfce` recomenda) ou `policykit-1-gnome`; ambos autostartam via `/etc/xdg/autostart` |
| Chaveiro (`gnome-keyring`) | OK com GDM | senhas de navegadores e apps de mensagem vêm do chaveiro; o GDM destrava por PAM (`libpam-gnome-keyring` instalado) e isso vale também para a sessão Xfce | nada. Se você trocar o gerenciador de login para o LightDM (guia 08), confirme com `grep -r pam_gnome_keyring /etc/pam.d/lightdm*` — sem isso o chaveiro passa a pedir senha a cada boot |
| Montagem automática de pendrive | MUDA | quem monta no GNOME é o `gvfs` + Nautilus | `thunar-volman` + `gvfs-backends` + `gvfs-fuse` |
| Notificações | MUDA | dono é o GNOME Shell | `xfce4-notifyd` (0.9.4) |
| Bloqueio de tela | MUDA | dono é o GNOME Shell | `xfce4-screensaver`, já configurado pelo `xfce4-screensaver.xml` do Kali |
| Applet de rede | MUDA | ícone é da barra do GNOME | `network-manager-gnome` (binário `nm-applet`) no autostart do Xfce |
| Cliente de VPN na bandeja (ex.: FortiClient) | MUDA | hoje aparece via `appindicators` | depende do plugin `systray` com StatusNotifier ativo (ver acima) |
| Teclas de brilho/mídia | MUDA | `gnome-settings-daemon` | `xfce4-power-manager` + `xfce4-settings` (atalhos do Kali já incluídos) |
| Gestos de touchpad (3/4 dedos) | DEGRADA | o Mutter tem gestos nativos; o Xorg não | `touchegg` ou `libinput-gestures` — confirme com `apt-cache policy touchegg libinput-gestures` |
| Rolagem natural / touchpad | MUDA | hoje `natural-scroll=true` no GNOME | reconfigure em *Configurações do Xfce → Mouse e touchpad*; a chave do GNOME não é lida |
| Luz noturna | DEGRADA | está **ligada** hoje (`night-light-enabled=true`) e o Xfce não tem equivalente | `redshift`/`redshift-gtk` (1.12), `gammastep` (2.0.9) ou `xsct` (2.2) — todos disponíveis |
| Atalhos personalizados | MUDA | atalhos do GNOME não migram | na máquina de referência não havia atalhos personalizados (`custom-keybindings` vazio) e a única alteração era `maximize` desvinculado — confira os seus com o analisador antes de assumir o mesmo. O Kali traz o seu `xfce4-keyboard-shortcuts.xml` |
| Escala de tela | OK aqui | na máquina de referência, `monitors.xml` mostra `scale 1` nos dois monitores, `text-scaling-factor 1.0` e `experimental-features` vazio — nenhuma escala fracionária em uso, logo nada a perder | nada. **Importa saber**: se um dia precisar de 125%/150%, o Xorg só faz escala inteira e global; com dois monitores de densidade diferente, o Wayland é melhor |
| Layout de monitores | MUDA | `~/.config/monitors.xml` é do GNOME e o Xfce **não lê** | reconfigure em *Configurações do Xfce → Exibição* (grava em `xfconf`, canal `displays`); `arandr` ajuda a montar o layout |

### Aplicativos instalados

| App | Sev. | Observação |
|---|---|---|
| Apps Electron/Chromium (editores de código, navegadores baseados em Chromium, mensageiros, clientes de banco de dados) | OK | desde que não haja `~/.config/*-flags.conf` nem `.desktop` com `--ozone-platform=wayland`, todos usam X11 nativamente no Xfce. Na máquina de referência não havia nenhuma flag dessas — **confirme na sua** com o item 3 do analisador |
| Compartilhamento de tela (apps de reunião e mensageiros) | MELHORA | no Wayland depende do portal e às vezes não lista janelas; no Xorg o app enxerga as janelas direto |
| OBS Studio | MUDA | na máquina de referência as cenas só tinham fontes de **áudio** (`alsa_input_capture`, `pulse_input_capture`, `pulse_output_capture`), nada de vídeo a converter — o analisador diz o que há nas suas. Ao criar uma no Xorg, use *Captura de tela (XSHM)* ou *Captura de janela (Xcomposite)*; fontes PipeWire são recriadas, não convertidas |
| Peek (gravador de tela) | MELHORA | é X11-only: hoje não funciona em Wayland, no Xfce volta a funcionar |
| `scrot`, `xclip`, `xrandr`, `xprop`, `xkill` | MELHORA | ferramentas X11 já instaladas que passam a funcionar de verdade |
| `grim` | QUEBRA | é Wayland-only e **hoje já não funciona** aqui (o Mutter não implementa `wlr-screencopy`); no Xorg não serve para nada |
| Captura de tela | MUDA | `xfce4-screenshooter` assume, e o Kali já mapeia a tecla `Print` para ele |
| Snaps (navegador, suíte de escritório, utilitários) | OK | abrem normalmente; continuam **sem** o tema (limitação já descrita no guia 09) |
| JDownloader (Java/Swing) | MELHORA | apps Java antigos costumam ir melhor em X11 que em XWayland |
| GIMP, VLC | OK | nenhum requisito de Wayland |
| Firefox (snap) | OK | usa X11 por padrão fora do GNOME; se você tinha `MOZ_ENABLE_WAYLAND` em algum lugar, não tem — verifiquei os arquivos de ambiente e não há nenhuma variável Wayland definida |

## 13.3 O que melhora no Xorg

- **Automação de janelas e teclado:** `xdotool`, `wmctrl`, `xte` funcionam;
  no Wayland são bloqueados por design.
- **Captura por linha de comando:** `scrot`, `import`, `xfce4-screenshooter -f`
  gravam sem pedir permissão a portal nenhum — no GNOME Wayland de hoje isso é
  recusado (`AccessDenied`), como constatamos ao montar as imagens deste
  material.
- **Peek** e outros gravadores de GIF voltam a funcionar.
- **Compartilhamento de tela** em apps Electron, sem depender do portal.
- **Apps legados e Java/Swing** com menos artefatos que sob XWayland.
- **Atalhos globais** de qualquer app (inclusive gravadores e teclas de mídia de
  terceiros) passam a funcionar sem depender do compositor.

## 13.4 Antes de trocar: o que salvar

```bash
# atalhos personalizados do GNOME (salve antes: não migram para o Xfce)
dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > ~/atalhos-gnome.ini
dconf dump /org/gnome/desktop/wm/keybindings/            > ~/atalhos-wm-gnome.ini

# layout de monitores do GNOME (o Xfce não lê este arquivo; serve de referência)
cp ~/.config/monitors.xml ~/monitors-gnome.xml.bak

# cenas do OBS
cp -r ~/.config/obs-studio/basic ~/obs-basic.bak
```

O `scripts/00-backup.sh` já grava o dump completo do `dconf`, o que cobre os dois
primeiros itens — estes comandos só deixam o recorte à mão.

## 13.5 Verificação automatizada

```bash
cd scripts
./50-analise-wayland-xorg.sh
```

O script inspeciona esta máquina (extensões ativas, variáveis e flags de
ambiente, portais, ferramentas só-Wayland e só-X11, escala, serviços de sessão,
apps instalados) e emite um relatório classificado pelas mesmas severidades desta
página, no terminal e em `relatorios/`. Rode antes do primeiro login na sessão
Xfce e depois dele, para comparar.

## 13.6 Onde continuar

- Sintomas concretos e como consertar: `11-problemas-e-solucoes.md`
  (seção "Sintomas típicos de Wayland → Xorg").
- Pacotes que cobrem as lacunas acima: `04-ambiente-xfce.md` §4.2.
- O que fica igual e o que não fica, no visual: `09-fidelidade-e-limitacoes.md`.
