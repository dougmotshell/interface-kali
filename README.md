# Interface gráfica do Kali Linux no Ubuntu 24.04

Documentação para deixar a interface desta máquina visualmente igual à do Kali
Linux — temas, ícones, wallpapers, logos, fontes, painel, terminal, tela de login
e tela de boot — **sem instalar nenhuma ferramenta de pentest**.

O Kali é distribuído com três ambientes gráficos, e este material cobre os três:
**Xfce** (o padrão), **KDE Plasma** e **GNOME**.

Toda a especificação visual foi extraída dos pacotes oficiais do Kali
(`kali-themes`, `kali-themes-common`, `kali-defaults-desktop`, `adw-gtk3-kali`,
`kali-wallpapers-2026`, `kali-desktop-xfce`, `kali-desktop-kde`,
`kali-desktop-gnome`), versões 2026.3.x, baixados de
`https://kali.download/kali/pool/main/`. Nada foi suposto: cada valor (nome de
tema, paleta, fonte, layout de painel) vem dos arquivos de configuração desses
pacotes, e os originais estão em `docs/referencia/`.

## Estrutura

```
interface-kali/
├── README.md          você está aqui — índice e escolha do ambiente
├── docs/              toda a documentação
│   ├── README.md      índice das docs
│   ├── guias/         os 13 guias, na ordem de leitura
│   ├── capturas/      imagens antes/depois dos três ambientes
│   └── referencia/    arquivos de configuração originais do Kali
├── scripts/           automação — kali-look.sh é o ponto de entrada
└── relatorios/        saída do analisador Wayland → Xorg
```

Caminhos citados nos textos (`docs/referencia/…`, `scripts/…`) são relativos a esta
pasta.

## Começar

```bash
cd ~/Desktop/interface-kali/scripts
./kali-look.sh              # menu interativo: instalar, aplicar, reverter, remover
./kali-look.sh status       # o que está aplicado agora nesta máquina
```

O menu cobre todo o ciclo: baixar assets, instalar um ambiente, aplicar a
aparência, reverter, desinstalar. Tudo aceita `--dry-run`, e ações de risco pedem
confirmação. Antes de qualquer mudança: `./kali-look.sh backup`.

## Comparação visual

| Imagem | O que mostra |
|---|---|
| [`docs/capturas/1-antes-ubuntu-gnome.png`](docs/capturas/1-antes-ubuntu-gnome.png) | como está hoje (GNOME 46 + Yaru-purple-dark) |
| [`docs/capturas/2-depois-xfce-kali.png`](docs/capturas/2-depois-xfce-kali.png) | ambiente Xfce com os temas do Kali |
| [`docs/capturas/3-depois-plasma-kali.png`](docs/capturas/3-depois-plasma-kali.png) | ambiente KDE Plasma com o tema global do Kali |
| [`docs/capturas/4-depois-gnome-kali.png`](docs/capturas/4-depois-gnome-kali.png) | ambiente GNOME revestido de Kali |

São **simulações** montadas com o wallpaper, os ícones, as cores e as fontes
reais do Kali — não capturas de tela.
[`docs/capturas/README.md`](docs/capturas/README.md) explica o método e ensina a tirar
capturas reais suas (o GNOME 46 em Wayland bloqueia captura por linha de
comando).

## Os 13 guias

| Arquivo | Conteúdo |
|---|---|
| [`docs/guias/01-analise-do-sistema-atual.md`](docs/guias/01-analise-do-sistema-atual.md) | O que existe hoje nesta máquina e o que isso implica |
| [`docs/guias/02-especificacao-visual-do-kali.md`](docs/guias/02-especificacao-visual-do-kali.md) | A "planta" do visual do Kali: cada valor e sua origem |
| [`docs/guias/03-obter-os-assets-oficiais.md`](docs/guias/03-obter-os-assets-oficiais.md) | Como baixar temas/ícones/wallpapers do Kali com segurança |
| [`docs/guias/04-ambiente-xfce.md`](docs/guias/04-ambiente-xfce.md) | **Ambiente 1:** Xfce — o desktop padrão do Kali |
| [`docs/guias/05-ambiente-kde-plasma.md`](docs/guias/05-ambiente-kde-plasma.md) | **Ambiente 2:** KDE Plasma |
| [`docs/guias/06-ambiente-gnome.md`](docs/guias/06-ambiente-gnome.md) | **Ambiente 3:** GNOME — o seu desktop atual |
| [`docs/guias/07-terminal-e-prompt.md`](docs/guias/07-terminal-e-prompt.md) | Paleta do terminal e o prompt de duas linhas |
| [`docs/guias/08-boot-login-e-logos.md`](docs/guias/08-boot-login-e-logos.md) | GRUB, Plymouth, GDM/LightDM/SDDM, logos e avatar |
| [`docs/guias/09-fidelidade-e-limitacoes.md`](docs/guias/09-fidelidade-e-limitacoes.md) | Item a item: o que fica idêntico, próximo e impossível |
| [`docs/guias/10-rollback.md`](docs/guias/10-rollback.md) | Desfazer as **configurações** aplicadas |
| [`docs/guias/11-problemas-e-solucoes.md`](docs/guias/11-problemas-e-solucoes.md) | O que pode dar errado: sintoma → causa → solução, e diagnóstico |
| [`docs/guias/12-remover-ambientes.md`](docs/guias/12-remover-ambientes.md) | Desativar e **desinstalar** ambientes, assets e camadas |
| [`docs/guias/13-wayland-vs-xorg.md`](docs/guias/13-wayland-vs-xorg.md) | Sair do GNOME/Wayland para uma sessão Xorg: o que quebra, degrada e melhora |

O recorte entre 10, 11 e 12: **10** reverte configuração, **11** conserta
defeito, **12** remove software. O **13** é leitura obrigatória antes do primeiro
login em Xfce ou Plasma — a troca de Wayland para Xorg afeta extensões,
compartilhamento de tela, atalhos e captura de tela, não só a aparência.

## Scripts

| Script | Função |
|---|---|
| `scripts/kali-look.sh` | **Ponto de entrada.** Menu e subcomandos: `status`, `backup`, `assets`, `instalar`, `aplicar`, `reverter`, `remover`, `boot`, `terminal`, `prompt` |
| `scripts/00-backup.sh` | Salva o estado atual (dconf, configs, pacotes, temas) |
| `scripts/10-baixar-assets.sh` | Baixa os `.deb` do Kali e instala os arquivos (por usuário ou no sistema) |
| `scripts/20-aplicar-xfce.sh` | Tema, fontes, wallpaper, terminal e menu no Xfce |
| `scripts/30-aplicar-plasma.sh` | Tema global, ícones, decoração e Konsole no Plasma |
| `scripts/40-aplicar-gnome.sh` | Aplica tudo no GNOME atual |
| `scripts/41-reverter-gnome.sh` | Volta o GNOME ao Yaru-purple-dark |

Detalhes de uso em [`scripts/README.md`](scripts/README.md).

## Escolhendo o ambiente

|  | Xfce | KDE Plasma | GNOME |
|---|---|---|---|
| Fidelidade ao Kali padrão | **~95%** | ~80% | ~65% |
| Mexe no seu ambiente atual | Não | Não | **Sim** |
| Sessão nova no GDM | Sim | Sim | Não |
| Espaço extra | ~400 MB + 95 MB | ~700 MB + 95 MB | ~95 MB |
| Servidor gráfico | Xorg | Xorg (X11) | Wayland, como hoje |
| Tempo de setup | 30–40 min | 40–50 min | 15–20 min |
| Principal ressalva | Xfce 4.18 aqui vs 4.20 no Kali | decoração de janela do Kali exige Plasma 6 | barra do GNOME ≠ painel do Kali |

**Recomendação:** comece pelo **Xfce**. O visual do Kali é, em grande medida, o
Xfce 4 com os temas Kali-Dark e aquele painel superior; é o único ambiente em que
o resultado passa por Kali de verdade. Como ele entra como sessão paralela, seu
Ubuntu/GNOME continua intacto e você alterna na tela de login.

Se a ideia é só "escurecer e azular" o desktop que você já usa, vá direto ao
**GNOME** — 15 minutos, reversível em um comando.

Os três podem coexistir: os assets são compartilhados, cada sessão lê a sua
própria configuração e o GDM lista todas.

Nada aqui exige reinstalar o sistema, e nada aqui adiciona repositório do Kali ao
APT — o porquê está em
[`docs/guias/03-obter-os-assets-oficiais.md`](docs/guias/03-obter-os-assets-oficiais.md).
