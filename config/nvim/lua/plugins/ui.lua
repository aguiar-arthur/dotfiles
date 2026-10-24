return {

  {
    "nvim-mini/mini.icons",
    lazy = true,
    opts = {},
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  {
    "nvim-mini/mini.statusline",
    event = "VeryLazy",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_statusline_dashboard", { clear = true }),
        pattern = "snacks_dashboard",
        callback = function(ev)
          vim.b[ev.buf].ministatusline_disable = true
        end,
      })
    end,
    opts = function()
      local statusline = require("mini.statusline")

      local function lsp_clients()
        local names = {}
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          names[#names + 1] = c.name
        end
        return #names > 0 and ("LSP: " .. table.concat(names, ",")) or ""
      end

      local function vimtex_status()
        if vim.bo.filetype ~= "tex" then
          return ""
        end
        local ok, running =
          pcall(vim.api.nvim_eval, "exists('b:vimtex.compiler') && b:vimtex.compiler.is_running()")
        return (ok and running == 1) and "⟳ latexmk" or ""
      end

      return {
        content = {
          active = function()
            local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
            return statusline.combine_groups({
              { hl = mode_hl, strings = { mode } },
              {
                hl = "MiniStatuslineDevinfo",
                strings = {
                  statusline.section_git({ trunc_width = 40 }),
                  statusline.section_diff({ trunc_width = 75 }),
                  statusline.section_diagnostics({ trunc_width = 75 }),
                },
              },
              "%<",
              { hl = "MiniStatuslineFilename", strings = { vimtex_status() } },
              "%=",
              {
                hl = "MiniStatuslineFileinfo",
                strings = { lsp_clients(), statusline.section_fileinfo({ trunc_width = 120 }) },
              },
              {
                hl = mode_hl,
                strings = {
                  statusline.section_searchcount({ trunc_width = 75 }),
                  statusline.section_location({ trunc_width = 75 }),
                },
              },
            })
          end,
        },
      }
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3, multiline_threshold = 1, mode = "cursor" },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 300,
      spec = {
        { "<leader>a", group = "ai (Claude Code)", mode = { "n", "x" } },
        { "<leader>b", group = "buffer" },
        { "<leader>d", group = "diagnostics" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>gm", group = "merge conflict (review)" },
        { "<leader>l", group = "lsp" },
        { "<leader>n", group = "notes" },
        { "<leader>o", group = "open/toggle" },
        { "<leader>S", group = "session" },
        { "<leader>t", group = "terminal" },
        { "<leader>u", group = "ui toggles" },
        { "<localleader>d", group = "debug" },
        { "<localleader>t", group = "tests" },
      },
    },
  },
}
