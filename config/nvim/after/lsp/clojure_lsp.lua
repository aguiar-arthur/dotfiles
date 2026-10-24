return {
  root_dir = function(buf, on_dir)
    local name = vim.api.nvim_buf_get_name(buf)
    if not vim.fs.basename(name):match("^conjure%-log%-.+%.cljc$") then
      on_dir(vim.fs.root(buf, vim.lsp.config.clojure_lsp.root_markers))
    end
  end,
}
