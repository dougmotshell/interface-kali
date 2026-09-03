# Teclado ABNT2 e a precedência do xfconf sobre o `/etc`

Caso real nesta máquina (2026-09-03, Dell Latitude 3400, Xfce em X11): o teclado
não se comportava como ABNT2 e editar a configuração do sistema não resolvia.

## O sintoma e a causa

`/etc/default/keyboard` e o `localectl` estavam **corretos** —
`XKBLAYOUT="br"`, `XKBVARIANT="abnt2"`, `XKBMODEL="pc105"`. A sessão em execução,
não:

```
setxkbmap -query   →   model: dell   layout: br   variant: nativo-epo
```

`nativo-epo` é o layout **Nativo para Esperanto**, não o ABNT2. Vinha do xfconf:

```
xfconf-query -c keyboard-layout -lv
/Default/XkbLayout    br
/Default/XkbModel     dell           ← errado
/Default/XkbVariant   nativo-epo     ← errado
```

O `xfsettingsd` aplica esse canal a cada login, **por cima** do `/etc`. Enquanto
o valor estiver ali, mexer no arquivo do sistema não muda nada na sessão.

## A regra geral

Quem manda no layout, do mais forte para o mais fraco, dentro de uma sessão
gráfica:

| Ordem | Onde | Quem aplica |
|---|---|---|
| 1 | `xfconf`, canal `keyboard-layout` (Xfce) · `gsettings org.gnome.desktop.input-sources` (GNOME) · `kxkbrc` (Plasma) | o daemon de configurações da sessão, a cada login |
| 2 | `setxkbmap` avulso (autostart, `~/.xprofile`) | o próprio comando, uma vez |
| 3 | `/etc/default/keyboard`, `localectl` | o X/console, na ausência dos de cima |

É o **mesmo padrão** já registrado para o Whisker Menu (config migrada para o
xfconf, `.rc` legado inerte) e para o painel (`panel-profiles` substituindo a
pasta inteira): neste ambiente, o serviço de configuração da sessão é a fonte de
verdade, e arquivo em `/etc` ou em `~/.config` é palpite até prova em contrário.
Diagnostique **na sessão**, não no arquivo.

## A correção

```bash
xfconf-query -c keyboard-layout -p /Default/XkbLayout  -s br
xfconf-query -c keyboard-layout -p /Default/XkbVariant -s abnt2
xfconf-query -c keyboard-layout -p /Default/XkbModel   -s pc105
setxkbmap -model pc105 -layout br -variant abnt2   # aplica já, sem relogar
```

## Como verificar de fato, sem digitar tecla

Conferir a configuração só prova que a configuração mudou. O mapa ativo é que
importa — e ele se lê:

```bash
setxkbmap -print | xkbcomp -xkb - out.xkb
grep -A2 'key <AB11>' out.xkb   # slash question degree questiondown
grep -A2 'key <KPDL>' out.xkb   # KP_Delete KP_Separator (vírgula decimal)
grep -A2 'key <AC10>' out.xkb   # ccedilla Ccedilla dead_acute
```

`<AB11>` é a tecla extra ao lado do Shift direito — ela **só existe** no ABNT2, o
que a torna o teste decisivo entre `br+abnt2` e um `br` qualquer.

## Duas pontas fora da sessão gráfica

- **Console (tty): `VC Keymap: (unset)` é normal aqui, não é defeito.**
  `/etc/vconsole.conf` é um **symlink** para `default/keyboard`, e o
  `systemd-localed` procura nele uma linha `KEYMAP=` que o formato Debian não
  tem (usa `XKBLAYOUT`/`XKBVARIANT`). Quem configura o console no Ubuntu é o
  `console-setup`, pelo cache em `/etc/console-setup/`. Para saber se o tty está
  certo, leia o cache — não o `localectl`:

  ```bash
  zcat /etc/console-setup/cached_UTF-8_del.kmap.gz | grep -E '^keycode +89 '
  # ABNT2 → U+002f U+003f U+00b0 U+00bf   (a tecla / ? ° ¿)
  ```

  Nesta máquina o cache já estava ABNT2, e não havia o que corrigir. Se um dia
  precisar regenerar: `setupcon` puro **recusa** fora de um VT ("we are not on
  the console"); de dentro do X é `sudo setupcon --save-only`, que implica
  `--force`.
- **GNOME/Plasma.** O `gsettings` estava com `[('xkb', 'br')]`, sem variante —
  funciona, porque a variante padrão do layout `br` no xkeyboard-config **é** o
  abnt2. Para deixar explícito: `[('xkb', 'br+abnt2')]`.
