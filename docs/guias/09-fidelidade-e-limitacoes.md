# 9. Fidelidade e limitações

Comparação item a item entre o Kali original e cada um dos três ambientes,
aplicados sobre este Ubuntu 24.04.

Legenda: ✅ idêntico · 🟡 próximo, com diferenças visíveis · 🔴 não reproduzível

## 9.1 Quadro geral

| Elemento | Xfce | Plasma | GNOME |
|---|---|---|---|
| Tema de janelas/widgets | ✅ `Kali-Dark` original | 🟡 cores `KaliDark` + decoração Breeze | 🟡 `adw-gtk3-dark` (é o que o Kali usa no GNOME) |
| Tema de ícones | ✅ `Flat-Remix-Blue-Dark` | ✅ | ✅ |
| Cursor | ✅ Adwaita 24 | ✅ | ✅ |
| Fontes | ✅ Cantarell / Fira Code | ✅ | ✅ |
| Wallpaper e fundos | ✅ arquivos originais | ✅ | ✅ |
| Logos e ícone do menu | ✅ | ✅ | 🟡 só no GDM e no menu de apps |
| Estrutura do painel/barra | ✅ layout oficial do Kali | 🟡 painel Plasma com ajustes do Kali | 🔴 barra do GNOME ≠ painel do Kali |
| Pager de áreas de trabalho | ✅ | 🟡 (widget opcional) | 🔴 |
| Lista de janelas sem rótulo | ✅ | 🟡 com rótulo por padrão | 🔴 |
| Gráfico de CPU no painel | ✅ `cpugraph` | 🟡 widget diferente | 🟡 extensão `system-monitor` |
| IP de VPN no painel | ✅ script `genmon` original | 🔴 | 🔴 (extensão é exclusiva do Kali) |
| Menu de aplicativos | ✅ Whisker Menu configurado | 🟡 Kickoff com ícone do dragão | 🟡 `apps-menu` |
| Barra de título (botões, fonte) | ✅ `O\|HMC`, Cantarell Bold 9 | 🟡 ordem igual, estilo Breeze | 🟡 GNOME headerbar |
| Terminal (paleta, transparência) | ✅ | ✅ | ✅ |
| Prompt de duas linhas | ✅ | ✅ | ✅ |
| Editores com esquema Kali-Dark | ✅ Mousepad | ✅ Kate/Konsole | ✅ GNOME Text Editor |
| Tela de bloqueio | ✅ | ✅ | 🟡 fundo aplicável, layout do GNOME |
| Tela de login | 🟡 LightDM idêntico, se você trocar o DM | 🟡 GDM com logo do Kali | 🟡 GDM com logo do Kali |
| Plymouth (boot) | ✅ | ✅ | ✅ |
| GRUB | ✅ | ✅ | ✅ |
| Apps GTK4/libadwaita | 🟡 escuros, mas em cinza Adwaita | 🟡 idem | 🟡 idem |
| Apps Qt | ✅ via `qt5ct`/`qt6ct` | ✅ nativo | ✅ via `qt5ct` |
| Snaps | 🔴 ignoram `~/.themes` | 🔴 | 🔴 |
| **Estimativa geral** | **~95%** | **~80%** | **~65%** |

## 9.2 Limitações que valem explicação

**Decoração de janela no Plasma.** A decoração `Kali` é um plugin binário
(`kwin-style-kali`) compilado para o KDecoration do Plasma 6. O Ubuntu 24.04 tem
Plasma 5.27, então o plugin não existe nem carrega. Fica Breeze com as cores do
Kali. Só uma distro com Plasma 6 (ou o próprio Kali) resolve.

**A barra do GNOME.** Nenhum tema muda a arquitetura do GNOME Shell: uma barra
superior fina, visão de Atividades, sem pager nem lista de janelas. O sabor GNOME
do Kali tem exatamente essa limitação — ou seja, aplicando o Caminho GNOME você
fica igual ao *Kali GNOME*, não ao *Kali padrão*.

**Versão do Xfce.** 4.18 aqui, 4.20 no Kali. Os temas funcionam nos dois; podem
haver diferenças de espaçamento no painel e opções a mais/menos nos plugins.

**Tema de shell do GNOME.** O `Kali-Dark/gnome-shell` acompanha o GNOME 48/49 do
Kali. No 46 ele carrega, mas pode haver detalhes fora de posição. É desfazível
em um comando.

**GTK4/libadwaita.** Nautilus, Configurações e outros apps novos ignoram
`gtk-theme` por design. Eles respeitam apenas claro/escuro. Forçar cor exige CSS
próprio em `~/.config/gtk-4.0/gtk.css`, que quebra a cada atualização.

**Snaps.** Rodam em confinamento e não veem `~/.themes`. O Firefox do Ubuntu é
snap por padrão; considere a versão `.deb` ou Flatpak se o tema nele importar.

**Fundo do GDM.** Está dentro de um `gresource` compilado no Ubuntu. Trocável
apenas recompilando — risco alto, benefício baixo.

**Menu de ferramentas do Kali.** As categorias "01 – Information Gathering", "02
– Vulnerability Analysis" etc. vêm do pacote `kali-menu`, que existe para
organizar as ferramentas de pentest. Como você não quer as ferramentas, esse
menu fica fora — é a única ausência realmente perceptível para quem conhece o
Kali de vista.

**`kali-undercover`.** O modo que disfarça o Kali de Windows depende de
`kali-defaults`; não é parte do visual padrão e ficou fora.

## 9.3 Onde cada ambiente compensa

- **Xfce:** máxima fidelidade, isolamento total do seu ambiente atual, custo de
  disco moderado. É a escolha se o objetivo é "parecer Kali".
- **Plasma:** bom meio-termo visual, muitos aplicativos KDE novos instalados,
  configuração mais trabalhosa e a ressalva da decoração.
- **GNOME:** o mais rápido e sem instalar desktop novo, mas o resultado é "GNOME
  com as cores do Kali". Reversível em segundos.

Nada impede instalar os três: os assets são compartilhados e cada sessão lê a
sua própria configuração. O GDM lista todas na tela de login.
