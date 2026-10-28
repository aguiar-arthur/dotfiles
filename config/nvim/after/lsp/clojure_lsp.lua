local function with_call_sites(calls)
  for _, call in ipairs(calls or {}) do
    local item = call.from or call.to
    if item and vim.tbl_isempty(call.fromRanges or {}) then
      call.fromRanges = { item.selectionRange }
      item.selectionRange = item.range
    end
  end
  return calls
end

return {
  root_dir = function(buf, on_dir)
    local name = vim.api.nvim_buf_get_name(buf)
    if not vim.fs.basename(name):match("^conjure%-log%-.+%.cljc$") then
      on_dir(vim.fs.root(buf, vim.lsp.config.clojure_lsp.root_markers))
    end
  end,
  on_init = function(client)
    local request = client.request
    function client:request(method, params, handler, bufnr)
      if handler and method:find("^callHierarchy/") then
        local on_calls = handler
        handler = function(err, result, ...)
          return on_calls(err, with_call_sites(result), ...)
        end
      end
      return request(self, method, params, handler, bufnr)
    end
  end,
}
