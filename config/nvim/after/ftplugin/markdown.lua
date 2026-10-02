-- Browser preview via pandoc: `,p` builds a standalone HTML page (in Neovim's cache dir)
-- and opens it in the browser. Understands $...$, $$...$$ and \( ... \), \[ ... \] math, rendered as
-- MathML (no JS/CDN needed). Images are embedded. Saving the buffer rebuilds the file
-- after the first `,p`; refresh the browser tab (Cmd+R) to see the update.
local css = [[
body { max-width: 46em; margin: 2em auto; padding: 0 1em; font: 18px/1.6 -apple-system, "Helvetica Neue", sans-serif; }
@media (prefers-color-scheme: dark) { body { background: #282a36; color: #f8f8f2; } a { color: #8be9fd; } code, pre { background: #44475a; } }
pre { padding: .8em; overflow-x: auto; } code { padding: .1em .3em; } img { max-width: 100%; }
table { border-collapse: collapse; } td, th { border: 1px solid #8884; padding: .3em .7em; }
blockquote { border-left: 4px solid #8884; margin-left: 0; padding-left: 1em; }
]]

local function build(buf, open)
  if vim.fn.executable("pandoc") == 0 then
    vim.notify("pandoc not found: brew install pandoc", vim.log.levels.ERROR)
    return
  end
  local src = vim.api.nvim_buf_get_name(buf)
  if src == "" then
    vim.notify("Save the file first", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_buf_call(buf, function() vim.cmd("silent update") end)

  local dir = vim.fn.stdpath("cache") .. "/md-preview"
  vim.fn.mkdir(dir, "p")
  local cssfile = dir .. "/style.css"
  vim.fn.writefile(vim.split(css, "\n"), cssfile)
  local name = vim.fn.fnamemodify(src, ":t:r")
  local out = dir .. "/" .. name .. ".html"

  vim.system({
    "pandoc", "-f", "markdown+tex_math_single_backslash", "-t", "html5", "-s",
    "--mathml", "--embed-resources",
    "--resource-path=" .. vim.fn.fnamemodify(src, ":p:h"),
    "--metadata", "pagetitle=" .. name,
    "-c", cssfile, "-o", out, src,
  }, { text = true }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then
      vim.notify("pandoc failed:\n" .. (res.stderr or ""), vim.log.levels.ERROR)
    elseif open then
      vim.ui.open(out)
    end
  end))
end

vim.keymap.set("n", "<localleader>p", function()
  vim.b.md_preview_on = true
  build(0, true)
end, { buffer = true, silent = true, desc = "Markdown preview (browser)" })

vim.api.nvim_create_autocmd("BufWritePost", {
  buffer = 0,
  group = vim.api.nvim_create_augroup("user_md_preview_" .. vim.api.nvim_get_current_buf(), { clear = true }),
  callback = function(ev)
    if vim.b[ev.buf].md_preview_on then build(ev.buf, false) end
  end,
})
