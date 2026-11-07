local function real(path)
  return vim.uv.fs_realpath(path)
    or vim.fs.joinpath(real(vim.fs.dirname(path)), vim.fs.basename(path))
end

return {
  root_dir = function(buf, on_dir)
    local name = vim.api.nvim_buf_get_name(buf)
    local notes = vim.fn.expand(require("config.settings").notes.dir)
    if vim.uv.fs_stat(notes) and vim.fs.relpath(real(notes), real(name)) then
      return
    end
    on_dir(vim.fs.root(name, { ".marksman.toml", ".git" }) or vim.fs.dirname(name))
  end,
}
