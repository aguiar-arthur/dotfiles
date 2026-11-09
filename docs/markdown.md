# Markdown

Markdown files and notes: rendering in the buffer, the pandoc preview, linting with rumdl, and
the notes folder with obsidian.nvim. Its relationships are in [map](map.md).

## How it works

render-markdown.nvim draws headings, tables, code blocks and checkboxes in the buffer; the line
under the cursor and insert mode show the raw text. `<leader>um` turns it off, and a review does
while it is open (see [git](git.md)). Cursor's `.mdc` rule files are Markdown too.
LaTeX math is not rendered there: `,p` builds an HTML page with
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

render-markdown sets `conceallevel` on every redraw, so an `OptionSet` autocmd sets it up again
with the global value whenever `<leader>uc` changes it. mini.pairs leaves the backtick alone;
the ftplugin adds a pair that does not fire next to another backtick, so typing a code fence
still works.

## Pitfalls

- None of its own.

## Checks

`tests/keys.lua` (`,p`, the backtick pair); full: `test_markdown` and `test_notes` in
`tests/markdown.sh`; the repository's own Markdown: quick `rumdl`.

## Changing it

- **A lint rule**: `config/rumdl/rumdl.toml`; then `rumdl check . --config
  config/rumdl/rumdl.toml` on the repository, which follows the same rules.
- **Preview look**: the CSS at the top of `markdown_preview.lua`, Dracula colors in dark mode.
