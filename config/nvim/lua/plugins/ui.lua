return {

  {
    "echasnovski/mini.icons",
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
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local function lsp_clients()
        local names = {}
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          names[#names + 1] = c.name
        end
        return #names > 0 and ("LSP: " .. table.concat(names, ",")) or ""
      end

      local function vimtex_status()
        if vim.bo.filetype ~= "tex" or not vim.b.vimtex then return "" end
        local ok, running = pcall(vim.fn["vimtex#compiler#is_running"])
        return (ok and running == 1) and "⟳ latexmk" or ""
      end

      return {
        options = {
          theme = "auto",
          globalstatus = true,
          section_separators = { left = "", right = "" },
          component_separators = { left = "│", right = "│" },
          disabled_filetypes = { statusline = { "snacks_dashboard" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 }, vimtex_status },
          lualine_x = { lsp_clients, "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        extensions = { "lazy", "mason", "trouble", "nvim-dap-ui" },
      }
    end,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 300,
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code", mode = { "n", "v" } },
        { "<leader>d", group = "diagnostics" },
        { "<leader>D", group = "debug" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>l", group = "lsp" },
        { "<leader>m", group = "marks (harpoon)" },
        { "<leader>o", group = "open/toggle" },
        { "<leader>S", group = "session" },
        { "<leader>t", group = "terminal" },
        { "<leader>u", group = "ui toggles" },
        { "<leader>w", group = "window" },
        { "<localleader>l", group = "vimtex (LaTeX)", cond = function() return vim.bo.filetype == "tex" end },
      },
    },
  },
}
