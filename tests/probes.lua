local P = {}

function P.claude_stub(cmd)
  local claude = require("claudecode")
  claude.start()
  require("claudecode.terminal").setup({}, cmd)
  claude.is_claude_connected = function()
    return true
  end
  claude._broadcast_at_mention = function()
    return true, nil, { file_path = "x" }
  end
end

function P.terminal_has(text)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local lines = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), " ")
    if vim.bo[buf].buftype == "terminal" and lines:find(text, 1, true) then
      return 1
    end
  end
  return 0
end

local function windows(list, match)
  return vim.tbl_filter(function(win)
    return match(vim.bo[vim.api.nvim_win_get_buf(win)].filetype)
  end, list)
end

local function hover(filetype)
  return filetype == "dap-view-hover"
end

function P.hovers()
  return #windows(vim.api.nvim_list_wins(), hover)
end

function P.close_hovers()
  for _, win in ipairs(windows(vim.api.nvim_list_wins(), hover)) do
    vim.api.nvim_win_close(win, true)
  end
end

function P.dap_panels()
  return #windows(vim.api.nvim_tabpage_list_wins(0), function(filetype)
    return filetype:find("dap") ~= nil
  end)
end

function P.dap_line()
  local session = require("dap").session()
  return session and session.current_frame and session.current_frame.line or 0
end

function P.test_count(status)
  local neotest = require("neotest")
  for _, id in ipairs(neotest.state.adapter_ids()) do
    local counts = neotest.state.status_counts(id, { buffer = vim.api.nvim_get_current_buf() })
    if counts and counts[status] > 0 then
      return counts[status]
    end
  end
  return 0
end

function P.lua_ls_restarted()
  local client = vim.lsp.get_clients({ name = "lua_ls" })[1]
  return client and client.id ~= vim.g.lsp_id and 1 or 0
end

function P.picker_count()
  local picker = Snacks.picker.get()[1]
  return picker and picker:count() or 0
end

_G.P = P
