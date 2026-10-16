local function snack(path, ...)
  local args, count = { ... }, select("#", ...)
  return function()
    local target = Snacks
    for part in path:gmatch("[^.]+") do
      target = target[part]
    end
    target(unpack(args, 1, count))
  end
end

local function picker(name, opts)
  return snack("picker." .. name, opts)
end

local function key(lhs, rhs, desc, mode)
  return { lhs, rhs, desc = desc, mode = mode }
end

local function words_jump(direction)
  return function()
    Snacks.words.jump(direction * vim.v.count1)
  end
end

local float_terminal = { count = 1, win = require("dotfiles.float").win("Terminal") }
local bottom_terminal = { count = 2, win = { position = "bottom", height = 15 } }

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
    lazygit = { enabled = true, win = require("dotfiles.float").win("Lazygit") },
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
      actions = {
        confirm = function(picker, item, action)
          local git = require("dotfiles.git")
          local review = git.review() and vim.api.nvim_get_current_tabpage()
          if review then
            action = vim.tbl_extend("force", action or {}, { cmd = "tab" })
          end
          require("snacks.picker.actions").jump(picker, item, action)
          if review then
            vim.schedule(function()
              git.mark_jump(review)
              require("dotfiles.toggles").apply(vim.api.nvim_get_current_win())
            end)
          end
        end,
      },
      win = {
        input = { keys = { ["<c-j>"] = false, ["<c-k>"] = false } },
        list = { keys = { ["<c-j>"] = false, ["<c-k>"] = false } },
      },
    },
    quickfile = { enabled = true },
    scroll = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
    terminal = { enabled = true },
    words = { enabled = true },
  },
  keys = {
    key("<leader>op", snack("explorer"), "Toggle file tree"),
    key("<leader>of", snack("explorer.reveal"), "Find file in tree"),
    key("<leader>on", snack("notifier.show_history"), "Notification history"),
    key("<leader>od", snack("dashboard"), "Dashboard"),

    key("<leader>ff", picker("smart"), "Find files (smart)"),
    key("<leader>fF", picker("files", { ignored = true }), "Find files (all)"),
    key("<leader>fg", picker("grep"), "Live grep"),
    key("<leader>fw", picker("grep_word"), "Grep word / selection", { "n", "x" }),
    key("<leader>fr", picker("recent"), "Recent files"),
    key("<leader>fc", picker("files", { cwd = vim.fn.stdpath("config") }), "Neovim config files"),
    key("<leader>fh", picker("help"), "Help pages"),
    key("<leader>fk", picker("keymaps"), "Keymaps"),
    key("<leader>fd", picker("diagnostics"), "Diagnostics"),
    key("<leader>fs", picker("lsp_symbols"), "LSP symbols"),
    key("<leader>fS", picker("lsp_workspace_symbols"), "LSP workspace symbols"),
    key("<leader>fu", picker("undo"), "Undo history"),
    key("<leader>fC", picker("colorschemes"), "Colorschemes"),
    key("<leader>fR", picker("resume"), "Resume last picker"),
    key("<leader>f/", picker("lines"), "Search in buffer"),
    key("<leader>fm", picker("marks"), "Marks"),
    key("<leader>fp", picker("projects"), "Projects"),
    key("<leader>bb", picker("buffers"), "List buffers"),

    key("<leader>gg", snack("lazygit"), "Lazygit"),
    key("<leader>gl", picker("git_log"), "Git log"),
    key("<leader>gt", picker("git_status"), "Changed files"),
    key("<leader>gc", picker("git_diff"), "Changes (hunks)"),
    key("<leader>gh", picker("git_log_file"), "File history"),
    key("<leader>gL", picker("git_log_line"), "Line history"),
    key("<leader>gO", snack("gitbrowse"), "Open in browser", { "n", "v" }),

    key("<leader>tf", snack("terminal", nil, float_terminal), "Float terminal"),
    key("<leader>th", snack("terminal", nil, bottom_terminal), "Horizontal terminal"),
    key(
      "<leader>tv",
      snack("terminal", nil, { count = 3, win = { position = "right", width = 60 } }),
      "Vertical terminal"
    ),

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
        Snacks.toggle({
          name = "Auto-format (global)",
          get = function()
            return not vim.g.disable_autoformat
          end,
          set = function(state)
            vim.g.disable_autoformat = not state
          end,
        }):map("<leader>uf")
        vim.keymap.set("n", "<leader>un", function()
          Snacks.notifier.hide()
        end, { desc = "Dismiss notifications" })
      end,
    })
  end,
}
