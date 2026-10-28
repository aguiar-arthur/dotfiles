# Markdown

Markdown files and notes: rendering in the buffer, the pandoc preview, linting with rumdl, and
the notes folder with obsidian.nvim. Its relationships are in [map](map.md).

## Language

- **notes folder**: `settings.notes.dir` (`~/notes`), plain `.md` files; daily notes in
  `daily/`.
- **preview**: the HTML page `,p` builds with pandoc and rebuilds on save.

## Files

| Path | Holds |
|---|---|
| `config/nvim/lua/plugins/markdown.lua` | render-markdown.nvim, obsidian.nvim, `<leader>n` |
| `config/nvim/lua/dotfiles/markdown_preview.lua` | the pandoc preview behind `,p` |
| `config/nvim/after/ftplugin/markdown.lua` | `,p`, the backtick pair |
| `config/nvim/after/lsp/marksman.lua` | marksman outside the notes folder only |
| `config/nvim/templates/note.md` | the `# title` new and daily notes start with |
| `config/rumdl/rumdl.toml` | the lint rules (line length 100, only the inline HTML the README's header and `<details>` need); `.rumdl.toml` and `~/.config/rumdl/rumdl.toml` link to it |

## How it works

render-markdown.nvim draws headings, tables, code blocks and checkboxes in the buffer; the line
under the cursor and insert mode show the raw text. `<leader>um` turns it off. Cursor's `.mdc`
rule files are Markdown too. LaTeX math is not rendered there: `,p` builds an HTML page with
pandoc (math as MathML, images embedded), opens it in the browser and rebuilds it on every
save. HTML in the Markdown is rendered too.

Notes are handled by obsidian.nvim, which loads only in the notes folder or with a `<leader>n`
key and needs no Obsidian app or account. `<leader>nf` / `ng` find and grep, `nn` asks for a
title and creates `the-title.md`, `nd` opens today's note, `nb` lists backlinks (on a `#`
heading, links to that heading). Links are `[[note]]`: obsidian.nvim completes them, `<CR>` or
`gd` follows one and `grr` lists references; `<CR>` on a checkbox ticks it. No YAML frontmatter
is written. marksman serves Markdown outside the notes folder only, so the two never answer
the same request twice.

rumdl lints as you type; it formats on save only under a `.rumdl.toml` or `.markdownlint.*`, so
notes are never restyled.

## Contract

Offers: nothing other contexts rely on.

Consumes:

- [core](core.md): `settings.notes.dir` and the global conceal toggle `<leader>uc`.
  render-markdown sets `conceallevel` on every redraw, so it is set up again with the global
  value whenever that changes (an `OptionSet` autocmd).
- [code](code.md): rumdl and marksman as servers, and the formatting rules.
- [workspace](workspace.md): mini.pairs leaves the backtick alone; the ftplugin adds a pair that
  does not fire next to another backtick, so typing a code fence still works.

## Pitfalls

- None of its own.

## Checks

| What | Where |
|---|---|
| `,p` builds MathML, tables, HTML and rebuilds on save; the backtick pair; rumdl attaches | `tests/keys.lua` |
| Rendering, `u m`, rumdl and marksman attach, `gd` on a `[[link]]` | full: `test_markdown` in `tests/markdown.sh` |
| Daily notes, obsidian-ls, marksman stays out, checkboxes | full: `test_notes` |
| The repository's own Markdown | quick: `rumdl` |

## Changing it

- **A lint rule**: `config/rumdl/rumdl.toml`; then `rumdl check . --config
  config/rumdl/rumdl.toml` on the repository, which follows the same rules.
- **Preview look**: the CSS at the top of `markdown_preview.lua`, Dracula colors in dark mode.
