term_has() {
  echo "(function() for _, b in ipairs(vim.api.nvim_list_bufs()) do if vim.bo[b].buftype == \"terminal\" and table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), \" \"):find(\"$1\", 1, true) then return 1 end end return 0 end)()"
}

terminal_windows() {
  echo '#vim.tbl_filter(function(w) return vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "terminal" end, vim.api.nvim_list_wins())'
}

run_case() {
  local label="$1" tool="$2" file="$3" marker="$4"
  if ! have "$tool"; then
    skip "$label: ,r runs the file" "$tool not installed"
    return
  fi
  start_nvim "$PROJ/run" "$file"
  keys ,r
  probe "$label: ,r runs the file" "$(term_has "$marker")" 1 30
  stop_nvim
}

test_run() {
  mkdir -p "$PROJ/run"
  printf 'print("RUN_OK_python")\n' >"$PROJ/run/hello.py"
  printf 'print("RUN_OK_lua")\n' >"$PROJ/run/hello.lua"
  printf 'echo RUN_OK_sh\n' >"$PROJ/run/hello.sh"
  run_case Python python3 hello.py RUN_OK_python
  run_case Lua nvim hello.lua RUN_OK_lua
  run_case Shell bash hello.sh RUN_OK_sh
  start_nvim "$PROJ/run" hello.py
  keys ,r
  probe "Python: first run opens one terminal window" "$(terminal_windows)" 1 20
  keys ,r
  sleep 2
  probe "Python: running again reuses the window" "$(terminal_windows)" 1 10
  stop_nvim
}

test_debug() {
  mkdir -p "$PROJ/run"
  printf 'x = 1\ny = x + 1\nprint(y)\n' >"$PROJ/run/dbg.py"
  start_nvim "$PROJ/run" dbg.py
  menu_shows "Python: the , menu lists the debug group" "debug"
  keys :2 Enter
  keys ,db
  probe "Python: ,db sets a breakpoint" 'vim.tbl_count(require("dap.breakpoints").get())' 1 20
  keys ,dc
  probe "Python: ,dc stops at the breakpoint" 'require("dap").session() and require("dap").session().stopped_thread_id and 1 or 0' 1 60
  keys ,dt
  probe "Python: ,dt ends the session" 'require("dap").session() and 1 or 0' 0 20
  stop_nvim
}

test_language_actions() {
  mkdir -p "$PROJ/lang"
  printf 'import sys\nimport os\n\nprint(os.name, sys.argv)\n' >"$PROJ/lang/imp.py"
  printf 'vim.g.test_sourced = 1\n' >"$PROJ/lang/src.lua"
  if mason ruff; then
    start_nvim "$PROJ/lang" imp.py
    probe "ruff attaches to Python" "$(clients ruff)" 1 60
    keys ,o
    probe "Python: ,o sorts the imports" 'vim.fn.getline(1)' 'import os' 20
    stop_nvim
  else
    skip "Python: ,o sorts the imports" "ruff not installed by Mason"
  fi
  start_nvim "$PROJ/lang" src.lua
  keys ,s
  probe "Lua: ,s sources the file" 'vim.g.test_sourced or 0' 1 10
  stop_nvim
}

neotest_count() {
  echo "(function() local n = require(\"neotest\") for _, id in ipairs(n.state.adapter_ids()) do local c = n.state.status_counts(id, { buffer = vim.api.nvim_get_current_buf() }) if c and c.$1 > 0 then return c.$1 end end return 0 end)()"
}

test_test_keys() {
  local base="$PROJ/tests"
  mkdir -p "$base/py"
  printf 'def test_ok():\n    assert 1 + 1 == 2\n' >"$base/py/test_ok.py"
  start_nvim "$base/py" test_ok.py
  menu_shows "Python: the , menu lists the tests group" "tests"
  if [ ! -x "$base/py/.venv/bin/python" ]; then
    python3 -m venv "$base/py/.venv" >/dev/null 2>&1
    perl -e 'alarm 120; exec @ARGV' "$base/py/.venv/bin/pip" install -q pytest >/dev/null 2>&1
  fi
  if "$base/py/.venv/bin/python" -c "import pytest" 2>/dev/null; then
    keys ,tf
    probe "Python: ,tf passes the file through Neotest" "$(neotest_count passed)" 1 60
  else
    skip "Python: ,tf passes the file through Neotest" "pytest could not be installed"
  fi
  stop_nvim
}

test_clojure() {
  mkdir -p "$PROJ/clj"
  printf '(ns demo)\n(defn f [x] x)\n' >"$PROJ/clj/demo.clj"
  start_nvim "$PROJ/clj" demo.clj
  probe "Clojure: Conjure keeps ,rr for refresh" 'vim.fn.maparg(",rr", "n", false, true).desc or ""' "Refresh changed namespaces" 30
  probe "Clojure: Conjure keeps ,tc for the test under the cursor" 'vim.fn.maparg(",tc", "n", false, true).desc or ""' "Run the test under the cursor" 10
  menu_shows "Clojure: the , menu lists the evaluate group" "evaluate"
  probe "Clojure: ,r does not run a file" 'vim.fn.maparg(",r", "n") == "" and 1 or 0' 1 5
  if have clojure-lsp; then
    probe "Clojure: clojure-lsp attaches" "$(clients clojure_lsp)" 1 60
    probe "Clojure: ,o stays paredit's raise" 'vim.fn.maparg(",o", "n", false, true).desc or ""' "Raise form"
  fi
  stop_nvim
}

test_review() {
  local repo="$PROJ/review" g=(git -c user.name=t -c user.email=t@t)
  rm -rf "$repo" "$PROJ/review.git"
  git init -q --bare "$PROJ/review.git" && git -C "$PROJ" clone -q review.git review 2>/dev/null
  printf 'a = 1\n\nb = 2\n' >"$repo/r.lua"
  "${g[@]}" -C "$repo" add r.lua && "${g[@]}" -C "$repo" commit -qm base && git -C "$repo" push -q origin HEAD 2>/dev/null
  printf 'a = 1\n\nb = 3\n' >"$repo/r.lua"
  "${g[@]}" -C "$repo" commit -qam change
  start_nvim "$repo" other.txt
  keys Space g V
  wait_for 'vim.fn.tabpagenr("$")' 2 20
  keys C-l C-l gg
  wait_for 'vim.fn.expand("%:t")' r.lua 10
  keys ]c
  probe "Space g V: ]c goes to the branch's change" 'vim.fn.line(".")' 3 10
  stop_nvim
}
