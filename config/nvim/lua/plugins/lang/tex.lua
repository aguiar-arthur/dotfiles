-- LaTeX: vimtex (latexmk compilation, PDF + SyncTeX, TOC, text objects,
-- surround for commands/environments) + texlab (LSP: completion, \cite/\ref,
-- chktex diagnostics; see after/lsp/texlab.lua) + LuaSnip snippets
-- (snippets/tex.lua) + latexindent (formatting, via conform).
--
-- Requires MacTeX (latexmk, latexindent, chktex) and the Skim viewer on macOS.
-- On Linux it uses zathura when available.
return {
  {
    "lervag/vimtex",
    lazy = false, -- vimtex handles its own lazy-loading; do not use `ft = "tex"`
    init = function()
      local g = vim.g

      -- PDF viewer -------------------------------------------------
      if vim.fn.has("mac") == 1 then
        g.vimtex_view_method = "skim"
        g.vimtex_view_skim_sync = 1 -- forward search on compile/view
        g.vimtex_view_skim_activate = 1 -- brings Skim to the front on \lv
        g.vimtex_view_skim_reading_bar = 1 -- highlight bar for the current line
      elseif vim.fn.executable("zathura") == 1 then
        g.vimtex_view_method = "zathura"
      else
        g.vimtex_view_method = "general"
      end

      -- Compilation ------------------------------------------------------------
      -- latexmk in continuous mode (recompiles on save). The default engine is pdflatex;
      -- for lualatex/xelatex put this at the top of the .tex:   % !TEX program = lualatex
      g.vimtex_compiler_method = "latexmk"

      -- Quickfix: opens only on errors (without stealing focus) and filters noise
      g.vimtex_quickfix_open_on_warning = 0
      g.vimtex_quickfix_ignore_filters = {
        "Underfull \\\\hbox",
        "Overfull \\\\hbox",
        "Underfull \\\\vbox",
        "Overfull \\\\vbox",
        "LaTeX Font Warning: Font shape",
      }

      -- Navigation / appearance -----------------------------------------------------
      g.vimtex_toc_config = {
        split_pos = "vert topleft",
        split_width = 40,
        show_help = 0,
        mode = 2,
      }
      g.vimtex_syntax_conceal = {
        accents = 1, ligatures = 1, cites = 1, fancy = 1, spacing = 0, greek = 1,
        math_bounds = 0, math_delimiters = 1, math_fracs = 1, math_super_sub = 1,
        math_symbols = 1, sections = 0, styles = 1,
      }

      -- vimtex imaps (`a → \alpha) clash with the LuaSnip snippets: disabled
      g.vimtex_imaps_enabled = 0
      -- Completion comes from texlab (via blink.cmp), not vimtex's omnifunc
      g.vimtex_complete_enabled = 0
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("user_vimtex", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VimtexEventCompileSuccess",
        callback = function() vim.notify("Compiled successfully", vim.log.levels.INFO, { title = "LaTeX" }) end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VimtexEventCompileFailed",
        callback = function()
          vim.notify("Compilation failed — <localleader>le lists the errors", vim.log.levels.ERROR, { title = "LaTeX" })
        end,
      })
    end,
  },
}
