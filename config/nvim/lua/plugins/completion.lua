return {
  {
    "saghen/blink.cmp",
    version = "1.*", -- releases com binário pré-compilado (sem toolchain Rust)
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        config = function()
          local ls = require("luasnip")
          ls.setup({
            history = true,
            enable_autosnippets = true, -- necessário para os snippets LaTeX (snippets/tex.lua)
            update_events = { "TextChanged", "TextChangedI" },
            region_check_events = "InsertEnter",
            delete_check_events = "TextChanged",
          })
          -- Snippets do VSCode (friendly-snippets), exceto LaTeX: usamos os nossos
          require("luasnip.loaders.from_vscode").lazy_load({ exclude = { "latex", "tex", "plaintex" } })
          -- Snippets próprios em Lua: ~/.config/nvim/snippets/<filetype>.lua
          require("luasnip.loaders.from_lua").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
        end,
      },
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- Mesmos atalhos da configuração anterior (nvim-cmp)
      keymap = {
        preset = "none",
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<C-s>"] = { "show_signature", "hide_signature", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        -- Nada pré-selecionado: <CR> só aceita se você escolheu um item
        -- (evita engolir a quebra de linha ao escrever prosa/LaTeX).
        list = { selection = { preselect = false, auto_insert = true } },
        menu = { border = "rounded" },
        documentation = { auto_show = true, auto_show_delay_ms = 250, window = { border = "rounded" } },
        ghost_text = { enabled = false },
      },
      signature = { enabled = true, window = { border = "rounded" } },
      snippets = { preset = "luasnip" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
        },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
      cmdline = {
        keymap = {
          preset = "none",
          ["<Tab>"] = { "show", "select_next", "fallback" },
          ["<S-Tab>"] = { "select_prev", "fallback" },
          ["<C-j>"] = { "select_next", "fallback" },
          ["<C-k>"] = { "select_prev", "fallback" },
          ["<CR>"] = { "accept", "fallback" },
          ["<C-e>"] = { "cancel", "fallback" },
        },
        completion = { menu = { auto_show = true } },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
