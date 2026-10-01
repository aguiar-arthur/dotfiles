-- LaTeX: vimtex (compilação com latexmk, PDF + SyncTeX, TOC, text objects,
-- surround de comandos/ambientes) + texlab (LSP: completion, \cite/\ref,
-- diagnósticos chktex; ver after/lsp/texlab.lua) + snippets LuaSnip
-- (snippets/tex.lua) + latexindent (formatação, via conform).
--
-- Requer MacTeX (latexmk, latexindent, chktex) e o visualizador Skim no macOS.
-- Em Linux usa zathura quando disponível.
return {
  {
    "lervag/vimtex",
    lazy = false, -- o vimtex cuida do próprio lazy-loading; não use `ft = "tex"`
    init = function()
      local g = vim.g

      -- Visualizador de PDF -------------------------------------------------
      if vim.fn.has("mac") == 1 then
        g.vimtex_view_method = "skim"
        g.vimtex_view_skim_sync = 1 -- forward search ao compilar/visualizar
        g.vimtex_view_skim_activate = 1 -- traz o Skim para frente no \lv
        g.vimtex_view_skim_reading_bar = 1 -- barra de destaque da linha atual
      elseif vim.fn.executable("zathura") == 1 then
        g.vimtex_view_method = "zathura"
      else
        g.vimtex_view_method = "general"
      end

      -- Compilação ------------------------------------------------------------
      -- latexmk em modo contínuo (recompila ao salvar). O motor padrão é pdflatex;
      -- para lualatex/xelatex use no topo do .tex:   % !TEX program = lualatex
      g.vimtex_compiler_method = "latexmk"

      -- Quickfix: abre só em erros (sem roubar o foco) e filtra ruído
      g.vimtex_quickfix_open_on_warning = 0
      g.vimtex_quickfix_ignore_filters = {
        "Underfull \\\\hbox",
        "Overfull \\\\hbox",
        "Underfull \\\\vbox",
        "Overfull \\\\vbox",
        "LaTeX Font Warning: Font shape",
      }

      -- Navegação / aparência -----------------------------------------------------
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

      -- Os imaps (`a → \alpha) colidem com os snippets LuaSnip: desligados
      g.vimtex_imaps_enabled = 0
      -- Completion vem do texlab (via blink.cmp), não do omnifunc do vimtex
      g.vimtex_complete_enabled = 0
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("user_vimtex", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VimtexEventCompileSuccess",
        callback = function() vim.notify("Compilado com sucesso", vim.log.levels.INFO, { title = "LaTeX" }) end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VimtexEventCompileFailed",
        callback = function()
          vim.notify("Falha na compilação — <localleader>le lista os erros", vim.log.levels.ERROR, { title = "LaTeX" })
        end,
      })
    end,
  },
}
