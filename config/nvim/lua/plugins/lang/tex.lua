return {
  {
    "lervag/vimtex",
    cond = require("config.settings").languages.tex,
    lazy = false,
    init = function()
      local g = vim.g

      g.vimtex_view_method = "skim"
      g.vimtex_view_skim_sync = 1
      g.vimtex_view_skim_activate = 1
      g.vimtex_view_skim_reading_bar = 1

      g.vimtex_compiler_method = "latexmk"

      g.vimtex_quickfix_open_on_warning = 0
      g.vimtex_quickfix_ignore_filters = {
        "Underfull \\\\hbox",
        "Overfull \\\\hbox",
        "Underfull \\\\vbox",
        "Overfull \\\\vbox",
        "LaTeX Font Warning: Font shape",
      }

      g.vimtex_toc_config = {
        split_pos = "vert topleft",
        split_width = 40,
        show_help = 0,
        mode = 2,
      }
      g.vimtex_syntax_conceal = {
        accents = 1,
        ligatures = 1,
        cites = 1,
        fancy = 1,
        spacing = 0,
        greek = 1,
        math_bounds = 0,
        math_delimiters = 1,
        math_fracs = 1,
        math_super_sub = 1,
        math_symbols = 1,
        sections = 0,
        styles = 1,
      }

      g.vimtex_imaps_enabled = 0

      g.vimtex_complete_enabled = 0
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("user_vimtex", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VimtexEventCompileSuccess",
        callback = function()
          vim.notify("Compiled successfully", vim.log.levels.INFO, { title = "LaTeX" })
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VimtexEventCompileFailed",
        callback = function()
          vim.notify(
            "Compilation failed — <localleader>le lists the errors",
            vim.log.levels.ERROR,
            { title = "LaTeX" }
          )
        end,
      })
    end,
  },
}
