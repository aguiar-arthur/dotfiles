return {
  root_dir = function(buf, on_dir)
    local name = vim.api.nvim_buf_get_name(buf)
    local notes = vim.fs.normalize(vim.fn.expand(require("config.settings").notes.dir))
    if vim.fs.relpath(notes, name) then
      return
    end
    on_dir(vim.fs.root(name, { ".marksman.toml", ".git" }) or vim.fs.dirname(name))
  end,
}
