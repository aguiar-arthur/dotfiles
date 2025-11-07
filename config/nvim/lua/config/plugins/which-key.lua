return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
    end,
    config = function(_, _)
        local wk = require("which-key")

        wk.setup({
            plugins = {
                marks = true,
                registers = true,
                spelling = { enabled = true, suggestions = 20 },
                presets = {
                    operators = true,
                    motions = true,
                    text_objects = true,
                    windows = true,
                    nav = true,
                    z = true,
                    g = true,
                },
            },
            win = { -- ✅ changed from `window` → `win`
                border = "single",
                position = "bottom",
            },
        })

        wk.add({
            -- Buffer
            { "<leader>b", group = "Buffer" },
            { "<leader>bb", "<cmd>Telescope buffers<CR>", desc = "Buffer List" },
            { "<leader>bd", "<cmd>bp<bar>bd #<CR>", desc = "Delete Buffer" },

            -- File Explorer
            { "<leader>e", ":NvimTreeToggle<CR>", desc = "Toggle File Explorer" },
            { "<leader>n", ":NvimTreeRefresh<CR>", desc = "Refresh File Explorer" },

            -- Find
            { "<leader>f", group = "Find" },
            { "<leader>ff", ":Telescope find_files<CR>", desc = "Find Files" },
            { "<leader>fg", ":Telescope live_grep<CR>", desc = "Live Grep" },
            { "<leader>ft", ":NvimTreeFindFile<CR>", desc = "Find in Tree" },

            -- Git Hunk
            { "<leader>h", group = "Git Hunk" },
            { "<leader>hb", ":Gitsigns blame_line<CR>", desc = "Blame Line" },
            { "<leader>hd", ":Gitsigns diffthis<CR>", desc = "Diff This" },
            { "<leader>hp", ":Gitsigns preview_hunk<CR>", desc = "Preview Hunk" },
            { "<leader>hr", ":Gitsigns reset_hunk<CR>", desc = "Reset Hunk" },
            { "<leader>hs", ":Gitsigns stage_hunk<CR>", desc = "Stage Hunk" },
            { "<leader>hu", ":Gitsigns undo_stage_hunk<CR>", desc = "Undo Stage Hunk" },

            -- LSP
            { "<leader>l", group = "LSP" },
            { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action" },
            { "<leader>ld", vim.diagnostic.open_float, desc = "Show Diagnostics" },
            { "<leader>lr", vim.lsp.buf.rename, desc = "Rename Symbol" },

            -- Splits
            { "<leader>s", group = "Split" },
            { "<leader>sc", "<C-w>c", desc = "Close Split" },
            { "<leader>sh", "<cmd>split<CR>", desc = "Horizontal Split" },
            { "<leader>so", "<C-w>o", desc = "Close Other Splits" },
            { "<leader>sv", "<cmd>vsplit<CR>", desc = "Vertical Split" },

            -- Terminal
            { "<leader>t", group = "Terminal" },
            { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Float Terminal" },
            { "<leader>tg", "<cmd>lua _lazygit_toggle()<cr>", desc = "Lazygit" },
            { "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", desc = "Horizontal Terminal" },
            { "<leader>tv", "<cmd>ToggleTerm size=60 direction=vertical<cr>", desc = "Vertical Terminal" },

            -- Trouble / Diagnostics
            { "<leader>x", group = "Trouble/Diagnostics" },
            { "<leader>xT", "<cmd>TodoTelescope<cr>", desc = "Todo Telescope" },
            { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics" },
            { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List" },
            { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List" },
            { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo List" },
            { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics" },
            { "<leader>xx", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble" },

            -- Misc
            { "<leader>w", ":w<CR>", desc = "Save" },
            { "<leader>q", ":q<CR>", desc = "Quit" },

            -- LSP Navigation
            { "K", vim.lsp.buf.hover, desc = "Show Hover Documentation" },
            { "[c", ":Gitsigns prev_hunk<CR>", desc = "Previous Git Hunk" },
            { "]c", ":Gitsigns next_hunk<CR>", desc = "Next Git Hunk" },
            { "[d", vim.diagnostic.goto_prev, desc = "Previous Diagnostic" },
            { "]d", vim.diagnostic.goto_next, desc = "Next Diagnostic" },
            { "[t", "<cmd>TodoTrouble previous<cr>", desc = "Previous Todo" },
            { "]t", "<cmd>TodoTrouble next<cr>", desc = "Next Todo" },
            { "gd", vim.lsp.buf.definition, desc = "Go to Definition" },
            { "gi", vim.lsp.buf.implementation, desc = "Go to Implementation" },
            { "gr", vim.lsp.buf.references, desc = "Find References" },
        })
    end,
}
