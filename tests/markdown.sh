test_markdown() {
  rm -rf "$T/home/notes"
  printf -- '- [ ] task\n\nSee [[other]] here.\n' >"$PROJ/note.md"
  printf '# Other\n' >"$PROJ/other.md"
  : >"$PROJ/.marksman.toml"
  start_nvim "$PROJ" note.md
  probe "render-markdown renders Markdown" 'require("render-markdown").get() and 1 or 0' 1 30
  keys Space u m
  probe "<leader>um turns rendering off" 'require("render-markdown").get() and 1 or 0' 0
  keys Space u m
  probe "<leader>um turns rendering on" 'require("render-markdown").get() and 1 or 0' 1
  keys Space u c
  probe "<leader>uc re-applies the conceal level to render-markdown" 'require("render-markdown.state").config.win_options.conceallevel.rendered' 0
  keys Space u c
  probe "<leader>uc restores it" 'require("render-markdown.state").config.win_options.conceallevel.rendered' 2
  probe "a Markdown file leaves ~/notes alone" 'vim.fn.isdirectory(vim.fn.expand("~/notes"))' 0
  if have rumdl; then
    probe "rumdl attaches to Markdown" "$(clients rumdl)" 1 30
  else
    skip "rumdl attaches to Markdown" "rumdl not installed"
  fi
  if mason marksman; then
    probe "marksman attaches to Markdown" "$(clients marksman)" 1 60
    sleep 3
    keys :3 Enter 6l g d
    probe "gd follows a [[link]]" 'vim.fn.expand("%:t")' other.md 15
  else
    skip "marksman attaches to Markdown" "not installed by Mason"
  fi
  stop_nvim
}

test_notes() {
  printf 'local f = "%s"\nrequire("config.settings").notes.dir = f\n' "$T/notes" >"$T/notes.lua"
  start_nvim "$PROJ" start.txt
  send ":luafile $T/notes.lua<CR>"
  keys Space n d
  probe "<leader>nd opens today's daily note" 'vim.fn.expand("%:p")' "$T/notes/daily/$(date +%F).md" 15
  probe "obsidian-ls attaches to a note" '#vim.lsp.get_clients({ name = "obsidian-ls", bufnr = 0 })' 1 30
  probe "marksman stays out of notes" '#vim.lsp.get_clients({ name = "marksman", bufnr = 0 })' 0
  keys o '- [ ] task' Escape Enter
  probe "Enter ticks a checkbox in a note" 'vim.fn.getline(".")' '- [x] task'
  stop_nvim
}
