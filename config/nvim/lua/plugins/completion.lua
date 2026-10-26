return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        config = function()
          local ls = require("luasnip")
          ls.setup({
            enable_autosnippets = true,
            update_events = { "TextChanged", "TextChangedI" },
            region_check_events = "InsertEnter",
            delete_check_events = "TextChanged",
          })

          require("luasnip.loaders.from_vscode").lazy_load({
            exclude = { "latex", "tex", "plaintex" },
          })

          require("luasnip.loaders.from_lua").lazy_load({
            paths = { vim.fn.stdpath("config") .. "/snippets" },
          })
        end,
      },
    },

    opts = {
      keymap = {
        preset = "none",
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<C-s>"] = { "show_signature", "hide_signature", "fallback" },
      },
      completion = {
        list = { selection = { preselect = false, auto_insert = true } },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
        },
      },
      signature = { enabled = true },
      snippets = { preset = "luasnip" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
          clojure = { inherit_defaults = true, "omni" },
        },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
      cmdline = {
        keymap = {
          preset = "none",
          ["<Tab>"] = { "show_and_insert_or_accept_single", "select_next", "fallback" },
          ["<S-Tab>"] = { "select_prev", "fallback" },
          ["<C-e>"] = { "cancel", "fallback" },
        },
        completion = {
          menu = {
            auto_show = function()
              return vim.fn.getcmdtype() == ":"
            end,
          },
          list = { selection = { preselect = false } },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
}
