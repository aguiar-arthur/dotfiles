local M = {}

local function lifecycle()
  return require("codediff.ui.lifecycle")
end

local function explorer(tab)
  local panel = lifecycle().get_panel(tab)
  return panel and panel.name == "explorer" and panel.view and panel or nil
end

function M.files(tab)
  local panel = explorer(tab)
  if not panel then
    return {}
  end
  local tree, files = panel.view.tree, {}
  local function walk(ids)
    for _, id in ipairs(ids) do
      local node = tree:get_node(id)
      if node and node.data and not node.data.type then
        files[#files + 1] = node.data
      elseif node then
        walk(node:get_child_ids() or {})
      end
    end
  end
  walk(vim.tbl_map(function(node)
    return node:get_id()
  end, tree:get_nodes()))
  return files
end

function M.current(tab)
  local panel = explorer(tab)
  return panel and panel.data.current_selection
end

function M.select(tab, file)
  local panel = explorer(tab)
  if not panel then
    return
  end
  local view = panel.view
  if vim.api.nvim_win_is_valid(view.winid or -1) then
    for line = 1, vim.api.nvim_buf_line_count(view.bufnr) do
      local node = view.tree:get_node(line)
      if node and node.data and node.data.path == file.path and node.data.group == file.group then
        vim.api.nvim_win_set_cursor(view.winid, { line, 0 })
        break
      end
    end
  end
  view.on_file_select(file)
end

function M.revisions(tab)
  local panel = explorer(tab)
  return panel
    and {
      root = panel.data.git_root,
      base = panel.data.base_revision,
      target = panel.data.target_revision,
    }
end

function M.side(buf, tab)
  tab = tab or vim.api.nvim_get_current_tabpage()
  local session = lifecycle().get_session(tab)
  if not session then
    return nil
  end
  local original, modified = lifecycle().get_buffers(tab)
  local name = buf == original and "original" or buf == modified and "modified" or nil
  return name
    and {
      root = session.git_root,
      path = session[name] and session[name].relative,
      revision = session[name .. "_revision"],
    }
end

function M.windows(tab)
  return lifecycle().get_windows(tab)
end

function M.hunks(tab)
  local session = lifecycle().get_session(tab)
  local result = session and session.stored_diff_result
  return result and result.changes or {}
end

function M.redraw(tab)
  local panel = explorer(tab)
  if panel and vim.api.nvim_buf_is_valid(panel.view.bufnr or -1) then
    panel.view.tree:render()
  end
end

local base_ignore

function M.hide(tab, paths)
  local filter = require("codediff.config").options.explorer.file_filter
  base_ignore = base_ignore or vim.deepcopy(filter.ignore or {})
  filter.ignore = vim.list_extend(
    vim.deepcopy(base_ignore),
    vim.tbl_map(function(path)
      return "/" .. path
    end, paths)
  )
  local panel = explorer(tab)
  if panel and vim.api.nvim_buf_is_valid(panel.view.bufnr or -1) then
    require("codediff.ui.explorer.tree").rebuild(panel.view)
  end
end

return M
