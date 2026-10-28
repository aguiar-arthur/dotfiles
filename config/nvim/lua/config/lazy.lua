local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local clone = vim
    .system(
      { "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath },
      { text = true }
    )
    :wait()
  if clone.code ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { clone.stderr or "", "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    if #vim.api.nvim_list_uis() > 0 then
      vim.fn.getchar()
    end
    os.exit(1)
  end
  local ok, lock = pcall(function()
    return vim.json.decode(
      table.concat(vim.fn.readfile(vim.fn.stdpath("config") .. "/lazy-lock.json"))
    )
  end)
  local commit = ok and lock["lazy.nvim"] and lock["lazy.nvim"].commit
  if commit then
    local res = vim.system({ "git", "-C", lazypath, "checkout", "--quiet", commit }):wait()
    if res.code ~= 0 then
      vim.notify(
        "lazy.nvim stays on its default branch: " .. vim.trim(res.stderr),
        vim.log.levels.WARN
      )
    end
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "dracula", "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
  ui = { border = "rounded" },
  rocks = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor" },
    },
  },
})
