local function picker(name, opts)
  return function()
    Snacks.picker[name](opts)
  end
end

local function terminal(opts)
  return function()
    Snacks.terminal(nil, opts)
  end
end

local function key(lhs, rhs, desc, mode)
  return { lhs, rhs, desc = desc, mode = mode }
end

local function words_jump(direction)
  return function()
    Snacks.words.jump(direction * vim.v.count1)
  end
end

local hide_keys = {
  hide_slash = { "<c-/>", "hide", mode = "t", desc = "Hide terminal" },
  hide_underscore = { "<c-_>", "hide", mode = "t", desc = "Hide terminal" },
}
local float_terminal = {
  count = 1,
  win = vim.tbl_extend("force", require("dotfiles.float").win("Terminal"), { keys = hide_keys }),
}
local bottom_terminal = { count = 2, win = { position = "bottom", height = 15, keys = hide_keys } }
local right_terminal = { count = 3, win = { position = "right", width = 60, keys = hide_keys } }

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,

  opts = {
    bigfile = { enabled = true },
    dashboard = {
      enabled = true,
      width = 70,
      sections = {
        {
          section = "terminal",
          cmd = "bash " .. vim.fn.shellescape(vim.fn.stdpath("config") .. "/dashboard/clock.sh"),
          ttl = 0,
          height = 11,
          width = 70,
          align = "center",
          padding = 1,
        },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    picker = {
      enabled = true,
      layout = { layout = { backdrop = 60 } },
      sources = {
        explorer = { hidden = true, ignored = false },
        files = { hidden = true },
        grep = { hidden = true },
        lsp_references = { auto_confirm = false },
      },
      win = {
        input = { keys = { ["<c-j>"] = false, ["<c-k>"] = false } },
        list = { keys = { ["<c-j>"] = false, ["<c-k>"] = false } },
      },
    },
    quickfile = { enabled = true },
    scroll = { enabled = true, animate = { duration = { step = 10, total = 100 } } },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
    terminal = { enabled = true },
    words = { enabled = true },
  },
  keys = {
    key("<leader>op", function()
      Snacks.explorer()
    end, "Toggle file tree"),
    key("<leader>of", function()
      Snacks.explorer.reveal()
    end, "Find file in tree"),
    key("<leader>on", function()
      Snacks.notifier.show_history()
    end, "Notification history"),
    key("<leader>od", function()
      Snacks.dashboard()
    end, "Dashboard"),

    key("<leader>ff", picker("smart"), "Find files (smart)"),
    key("<leader>fF", picker("files", { ignored = true }), "Find files (all)"),
    key("<leader>fg", picker("grep"), "Live grep"),
    key("<leader>fw", picker("grep_word"), "Grep word / selection", { "n", "x" }),
    key("<leader>fr", picker("recent"), "Recent files"),
    key("<leader>fc", picker("files", { cwd = vim.fn.stdpath("config") }), "Neovim config files"),
    key("<leader>fh", picker("help"), "Help pages"),
    key("<leader>fk", picker("keymaps"), "Keymaps"),
    key("<leader>fu", picker("undo"), "Undo history"),
    key("<leader>fC", picker("colorschemes"), "Colorschemes"),
    key("<leader>fR", picker("resume"), "Resume last picker"),
    key("<leader>f/", picker("lines"), "Search in buffer"),
    key("<leader>fm", picker("marks"), "Marks"),
    key("<leader>fp", picker("projects"), "Projects"),
    key("<leader>bb", picker("buffers"), "List buffers"),

    key("<leader>dx", picker("diagnostics"), "Diagnostics (project)"),
    key("<leader>dd", picker("diagnostics_buffer"), "Diagnostics (this file)"),
    key("<leader>dq", picker("qflist"), "Quickfix list"),
    key("<leader>dl", picker("loclist"), "Location list"),

    key("<leader>tf", terminal(float_terminal), "Float terminal"),
    key("<leader>th", terminal(bottom_terminal), "Horizontal terminal"),
    key("<leader>tv", terminal(right_terminal), "Vertical terminal"),

    key("]r", words_jump(1), "Next reference"),
    key("[r", words_jump(-1), "Previous reference"),
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        require("dotfiles.toggles").map()
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.scroll():map("<leader>uS")
        vim.keymap.set("n", "<leader>un", function()
          Snacks.notifier.hide()
        end, { desc = "Dismiss notifications" })
      end,
    })
  end,
}
