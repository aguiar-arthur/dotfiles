local function move(direction, query)
  return function()
    require("nvim-treesitter-textobjects.move")[direction](query, "textobjects")
  end
end

return {

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote flash",
      },
      {
        "<c-s>",
        mode = "c",
        function()
          require("flash").toggle()
        end,
        desc = "Toggle flash search",
      },
    },
  },

  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" } },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          u = ai.gen_spec.function_call(),
        },
      }
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    keys = {
      {
        "]f",
        move("goto_next_start", "@function.outer"),
        mode = { "n", "x", "o" },
        desc = "Next function",
      },
      {
        "[f",
        move("goto_previous_start", "@function.outer"),
        mode = { "n", "x", "o" },
        desc = "Previous function",
      },
      {
        "]a",
        move("goto_next_start", "@parameter.inner"),
        mode = { "n", "x", "o" },
        desc = "Next argument",
      },
      {
        "[a",
        move("goto_previous_start", "@parameter.inner"),
        mode = { "n", "x", "o" },
        desc = "Previous argument",
      },
    },
  },

  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
    keys = {
      {
        "<leader>r",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "Replace in project",
      },
      { "<leader>r", ":GrugFar<CR>", mode = "x", desc = "Replace selection in project" },
      {
        "<leader>R",
        function()
          require("grug-far").open({
            engine = "astgrep",
            prefills = { search = vim.fn.expand("<cword>") },
          })
        end,
        desc = "Structural replace in project (ast-grep)",
      },
      {
        "<leader>R",
        ":GrugFar astgrep<CR>",
        mode = "x",
        desc = "Structural replace of the selection (ast-grep)",
      },
    },
  },

  {
    "nvim-mini/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
      },
    },
  },

  {
    "nvim-mini/mini.pairs",
    event = "VeryLazy",
    opts = {
      modes = { insert = true, command = false, terminal = false },

      mappings = { ["`"] = false },
    },
  },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next todo",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous todo",
      },
      {
        "<leader>dt",
        function()
          Snacks.picker.todo_comments()
        end,
        desc = "Todos (project)",
      },
    },
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    config = function(_, opts)
      require("persistence").setup(opts)
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("user_persistence", { clear = true }),
        pattern = "PersistenceSavePre",
        callback = function()
          require("dotfiles.git").close_reviews()
        end,
      })
    end,
    keys = {
      {
        "<leader>Sr",
        function()
          require("persistence").load()
        end,
        desc = "Restore session (cwd)",
      },
      {
        "<leader>Sl",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore last session",
      },
      {
        "<leader>Ss",
        function()
          require("persistence").select()
        end,
        desc = "Select session",
      },
      {
        "<leader>Sd",
        function()
          require("persistence").stop()
        end,
        desc = "Don't save this session",
      },
    },
  },
}
