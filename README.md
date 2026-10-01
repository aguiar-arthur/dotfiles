# Dotfiles

Configuração pessoal de ambiente para macOS: **Neovim** (editor generalista com fluxo
completo de LaTeX), **Starship** (prompt) e **iTerm2** (perfil Dracula).

## Estrutura

```
Brewfile                      programas e fontes (brew bundle)
install.sh                    cria os symlinks e ativa o starship no zsh
config/
  nvim/                       Neovim >= 0.11
  starship/starship.toml      prompt em duas linhas, estilo "pílulas", cores Dracula
  iterm2/dracula.json         Dynamic Profile do iTerm2 (cores Dracula)
```

## Instalação

```sh
git clone <repo> ~/dotfiles && cd ~/dotfiles
brew bundle      # 1. instala os programas (neovim, starship, lazygit, MacTeX, Skim, fonte Nerd...)
./install.sh     # 2. cria os links e liga o starship no ~/.zshrc
```

Depois:

1. Abra um **novo terminal** (para o Starship carregar).
2. No iTerm2: *Settings → Profiles → "Dotfiles (Dracula)" → Other Actions → Set as Default*.
3. Abra o `nvim`. Na primeira vez o lazy.nvim instala os plugins, o Mason instala
   servidores LSP/formatters e o treesitter compila os parsers (leva um ou dois minutos).
4. Para LaTeX, configure a busca inversa do Skim (veja [LaTeX](#latex)).

### O que o `install.sh` faz (e o que não faz)

| Faz | Não faz |
|---|---|
| `~/.config/nvim` → `config/nvim` | instalar programas (isso é o `brew bundle`) |
| `~/.config/starship.toml` → `config/starship/starship.toml` | instalar plugins do nvim (acontece ao abrir o `nvim`) |
| perfil do iTerm2 → `~/Library/Application Support/iTerm2/DynamicProfiles/` | definir o perfil do iTerm2 como padrão (passo manual acima) |
| adiciona ao `~/.zshrc` um bloco marcado que roda `starship init zsh` (uma vez) | |

É idempotente: pode ser rodado de novo sem duplicar nada. Se um destino já existir e não
for o link correto, ele é movido para `<destino>.bak.<data>` antes de criar o link.

Requisitos externos do Neovim: uma **Nerd Font** no terminal, `git`, `rg`, `fd`, `node`
(alguns servidores do Mason), `tree-sitter-cli` + compilador C (parsers), `lazygit`
(opcional), **MacTeX** (`latexmk`, `latexindent`, `chktex`) e **Skim** para LaTeX.
Tudo isso vem do Brewfile; use `:checkhealth` para diagnosticar o que faltar.

---

## Neovim

Configuração modular para **Neovim ≥ 0.11** (testada no 0.12): editor generalista (LSP,
completion, git, debug, picker, explorer, terminal integrado) com um fluxo completo de
LaTeX. Leader = `<Space>`, localleader = `,`.

### Estrutura

```
config/nvim/
  init.lua                    ponto de entrada (checa versão, carrega config/*)
  lua/config/
    options.lua               opções e leaders
    keymaps.lua               atalhos "core" (janelas, buffers, diagnósticos...)
    autocmds.lua              highlight no yank, restore cursor, spell/wrap em prosa...
    lazy.lua                  bootstrap do lazy.nvim
  lua/plugins/                uma spec por assunto
    snacks.lua                picker, explorer, terminal, lazygit, dashboard, notificações
    completion.lua            blink.cmp + LuaSnip
    lsp.lua                   nvim-lspconfig + mason (lista de servidores/ferramentas no topo)
    formatting.lua            conform.nvim
    treesitter.lua            nvim-treesitter (branch main)
    editor.lua                gitsigns, flash, harpoon, mini.{ai,surround,pairs}, trouble, todo, sessões
    debug.lua                 nvim-dap (+ UI, debugpy)
    ui.lua / colorscheme.lua  lualine, which-key, ícones, Dracula
    lang/tex.lua              vimtex
    lang/markdown.lua         render-markdown
  after/lsp/<servidor>.lua    ajustes por servidor (lua_ls, basedpyright, jsonls, yamlls, texlab)
  after/ftplugin/tex.lua      opções e atalhos de buffer para LaTeX
  snippets/tex.lua            snippets LaTeX (LuaSnip)
```

### Como descobrir atalhos

- Aperte `<Space>` e espere: o which-key mostra os grupos e, dentro deles, cada atalho.
- `<Space>?` abre o painel de atalhos; `<Space>fk` busca em todos os keymaps.
- Num `.tex`, a mesma coisa vale para `,` (atalhos do vimtex).

### Atalhos (`<Space>` = leader)

| Prefixo | Grupo | Exemplos |
|---|---|---|
| `<leader>f` | file/find (snacks picker) | `ff` arquivos · `fg` grep · `fr` recentes · `fb` buffers · `fc` config · `fk` atalhos · `fs` símbolos · `fR` retomar |
| `<leader>o` | open | `op` explorer · `of` revelar arquivo atual · `on` histórico de notificações |
| `<leader>l` | lsp | `ld` definição · `lr` referências · `ln` rename · `la` code action · `lf` formatar · `ll` diagnósticos |
| `<leader>d` | diagnostics (Trouble) | `dx` · `dd` buffer · `dq` quickfix · `dt` TODOs |
| `<leader>g` | git | `gg` lazygit · `gs` stage hunk · `gp` preview · `gb` blame · `gl` log · `]c`/`[c` hunks |
| `<leader>b` / `w` | buffer / window | `bd` fecha buffer · `bb` lista · `wv`/`ws` splits · `Ctrl-h/j/k/l` navega |
| `<leader>t` | terminal | `tf` float · `th` horizontal · `tv` vertical · `Ctrl-\` alterna |
| `<leader>m` | harpoon | `ma` adiciona · `mm` menu · `m1…m5` salta |
| `<leader>D` | debug (DAP) | `Db` breakpoint · `Dc` continuar · `Di/Do/DO` step · `Du` UI |
| `<leader>S` | sessões | `Sr` restaurar · `Sl` última |
| `<leader>u` | toggles | `us` spell · `uw` wrap · `uc` conceal · `uf` auto-format · `uh` inlay hints |
| `s` / `S` | flash | salto rápido / seleção por treesitter |
| `gsa gsd gsr` | surround | adicionar / remover / trocar |

### LaTeX

Fluxo: **vimtex** compila (latexmk contínuo) e abre o PDF no **Skim** com SyncTeX;
**texlab** dá completion (`\cite`, `\ref`, comandos), diagnósticos (chktex), rename e
go-to-definition; **LuaSnip** expande snippets matemáticos; **latexindent** formata.

Atalhos em arquivos `.tex` (`<localleader>` = `,`):

| Atalho | Ação |
|---|---|
| `,ll` | liga/desliga compilação contínua (latexmk) |
| `,lv` | abre/atualiza o PDF e faz forward search |
| `,le` / `,lo` / `,lg` | erros / saída do latexmk / status |
| `,lt` / `,lT` | índice (TOC) / alterna |
| `,lc` / `,lC` | limpa arquivos auxiliares / + PDF |
| `,lw` | contagem de palavras |
| `<leader>lf` | formata com latexindent (não roda ao salvar, de propósito) |
| `<leader>uc` | alterna conceal (símbolos renderizados) |

Edição do vimtex: `dse`/`cse` (ambiente), `dsc`/`csc` (comando), `ie`/`ae` (ambiente),
`i$`/`a$` (matemática inline), `tsf` (alterna fração), `]]`/`[[` (seções).

**Skim → Neovim (busca inversa, Cmd+Shift+clique no PDF):** em
*Skim → Preferences → Sync* escolha *Custom*, *Command* `nvim` e *Arguments*
`--headless -c "VimtexInverseSearch %line '%file'"`.

**Outro motor** (lualatex/xelatex): primeira linha do arquivo `% !TEX program = lualatex`.
Para `minted`/`-shell-escape`, crie um `.latexmkrc` no projeto com
`$pdflatex = 'pdflatex -shell-escape %O %S';`.

#### Snippets (`snippets/tex.lua`)

Autosnippets (expandem sozinhos):

| Contexto | Digite | Resultado |
|---|---|---|
| texto | `mk` · `dm` · `beg` | `$…$` · `\[…\]` · `\begin{…}…\end{…}` |
| matemática | `a//` · `(a+b)//` | `\frac{a}{}` · `\frac{a+b}{}` |
| matemática | `x2` · `__` · `td` · `sr` · `cb` | `x_2` · `_{}` · `^{}` · `^2` · `^3` |
| matemática | `;a` `;b` `;G` `;o`… | `\alpha` `\beta` `\Gamma` `\omega`… |
| matemática | `->` `=>` `<=` `!=` `...` `xx` `ooo` | `\to` `\implies` `\leq` `\neq` `\dots` `\times` `\infty` |
| matemática | `sum` `int` `lim` `part` `sq` `lr(` | somatório, integral, limite, derivada parcial, raiz, `\left( \right)` |
| matemática | `RR` `NN` `ZZ` `QQ` `CC` | `\mathbb{R}`… |

Snippets pelo menu de completion: `eqn`, `ali`, `thm`, `prf`, `ite`, `enu`, `fig`, `tab`,
`sec`/`ssec`, `cit`, `ref`, `eqr`, `doc` (preâmbulo completo)… Adicione os seus em
`snippets/tex.lua` (ou crie `snippets/<filetype>.lua`).

### LSP, formatação e debug

| Linguagem | LSP | Formatter |
|---|---|---|
| Lua | lua_ls (+ lazydev) | stylua |
| Python | basedpyright + ruff | ruff |
| LaTeX/BibTeX | texlab | latexindent |
| Bash | bashls (+ shellcheck) | shfmt |
| JS/TS/HTML/CSS/JSON/YAML/MD | vtsls, html, cssls, jsonls, yamlls, marksman | prettier |
| TOML · C/C++ | taplo · clangd | LSP |
| Clojure | clojure-lsp (do Brewfile; habilitado se estiver no PATH) | LSP |

Para adicionar um servidor: inclua o nome em `mason_servers` (topo de `lua/plugins/lsp.lua`)
e, se precisar de ajustes, crie `after/lsp/<nome>.lua`. Formatters ficam em `formatting.lua`.
Auto-format ao salvar: `<leader>uf` (global) ou `:FormatToggle!` (só o buffer).

### Notas

- Na primeira abertura de um `.tex`/`.md` o Neovim oferece baixar os dicionários
  (`en`, `pt`) para o spell check.
- Os parsers do treesitter são compilados localmente na primeira execução.

---

## Starship

Prompt em duas linhas, com ícones (Nerd Font) e informações contextuais:

```
(mac) (~/dotfiles) (main !1 ?2) +4 (py 3.13) ───────────────── 3s  11:10
❯
```

(Cada item entre parênteses é uma "pílula" colorida com ícone.)

- **Linha 1:** SO, diretório, branch do git com status (`!` modificado, `?` não rastreado,
  `+` staged, `⇡⇣` à frente/atrás) e linhas adicionadas/removidas, versões de
  Python/Node/Lua/Ruby/Rust/Go/Java/C (só quando o diretório é desse tipo); à direita,
  duração de comandos com mais de 2 s e a hora.
- **Linha 2:** usuário/host (apenas em ssh ou root), sudo, jobs em segundo plano, código de
  erro e o `❯` (vermelho quando o último comando falhou).
- Para ajustar: edite `config/starship/starship.toml`. As cores estão em
  `[palettes.dracula]` e cada módulo tem seu `format`/`symbol`. Os ícones são escritos como
  escapes `\uXXXX`, então o arquivo é ASCII puro.

## iTerm2

`config/iterm2/dracula.json` é um **Dynamic Profile**: o iTerm2 lê o arquivo sozinho e
mostra o perfil "Dotfiles (Dracula)". Ele herda o perfil *Default* (inclusive a fonte) e
altera apenas:

- paleta Dracula (16 cores ANSI, fundo, cursor, seleção)
- *Option* como Meta/Esc+ (necessário para os atalhos `Alt-j/k` do Neovim)
- cursor em barra, transparência leve com blur, 140×40, scrollback de 100 mil linhas

A fonte precisa ser uma **Nerd Font** para os ícones do prompt e do Neovim aparecerem
(o Brewfile instala a JetBrainsMono Nerd Font). Para trocar a fonte, mude no perfil
dentro do iTerm2 ou adicione `"Normal Font"` ao JSON.

## Manutenção

- **Atualizar programas:** `brew update && brew upgrade`
- **Atualizar plugins do nvim:** `:Lazy update` (o lockfile `lazy-lock.json` está no
  `.gitignore`; remova a linha `**/lazy-lock.json` para versioná-lo e ter versões
  reproduzíveis entre máquinas)
- **Instalação limpa do nvim:** `rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim`
- **Diagnóstico:** `:checkhealth` no Neovim · `starship explain` no shell

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
