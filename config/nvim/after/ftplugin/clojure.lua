local ok, wk = pcall(require, "which-key")
if ok then
  wk.add({
    buffer = 0,
    { "<localleader>c", group = "connect" },
    { "<localleader>e", group = "evaluate" },
    { "<localleader>l", group = "log" },
    { "<localleader>r", group = "refresh" },
    { "<localleader>s", group = "nREPL session" },
    { "<localleader>v", group = "view" },
    { "<localleader>x", group = "macroexpand" },
  })
end
