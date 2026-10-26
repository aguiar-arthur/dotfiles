local M = {}

function M.show(ev)
  local params = ev.data.params
  local value = params.value
  if type(value) ~= "table" or not value.kind then
    return
  end
  local client = vim.lsp.get_client_by_id(ev.data.client_id)
  local name = client and client.name or "LSP"
  local done = value.kind == "end"
  vim.api.nvim_echo({ { value.message or "" } }, false, {
    id = ("dotfiles.lsp.%d.%s"):format(ev.data.client_id, tostring(params.token)),
    kind = "progress",
    source = "lsp",
    title = (value.title or "") == "" and name or name .. ": " .. value.title,
    status = done and "success" or "running",
    percent = done and 100 or value.percentage or 0,
  })
  vim.cmd.redrawstatus()
end

function M.setup()
  vim.ui.progress_status()
  vim.api.nvim_create_autocmd("LspProgress", {
    group = vim.api.nvim_create_augroup("user_lsp_progress", { clear = true }),
    callback = M.show,
  })
end

return M
