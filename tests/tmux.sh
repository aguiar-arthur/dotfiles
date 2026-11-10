tmux_config() {
  local sock="dotfiles-tmux-check-$$" status=0
  GIT_EDITOR=true tmux -L "$sock" -f /dev/null new-session -d \; source-file "$DOT/config/tmux/tmux.conf" || status=1
  if [ "$status" = 0 ] && tmux -L "$sock" show-environment -g GIT_EDITOR >/dev/null 2>&1; then
    echo "GIT_EDITOR reaches the panes, so git commit would not open Neovim"
    status=1
  fi
  tmux -L "$sock" kill-server 2>/dev/null
  return "$status"
}

tmux_until() {
  for _ in $(seq 50); do
    "$@" && return 0
    sleep 0.2
  done
  return 1
}

tmux_keys() {
  local -a t=(tmux -L "dotfiles-tmux-keys-$$")
  local left right client scratch file out=""
  active() { [ "$("${t[@]}" display -p -t main '#{pane_id}')" = "$1" ]; }
  runs_nvim() { [ "$("${t[@]}" display -p -t "$right" '#{pane_current_command}')" = nvim ]; }
  screen_shows() { "${t[@]}" capture-pane -p -t "$right" | grep -q "$1"; }
  clients() { [ "$("${t[@]}" list-clients | wc -l | tr -d ' ')" = "$1" ]; }
  press() { perl -e 'alarm 3; exec @ARGV' "${t[@]}" send-keys -K -c "$@"; }
  "${t[@]}" -f "$DOT/config/tmux/tmux.conf" new-session -d -x 120 -y 30 -s main sh
  left="$("${t[@]}" display -p -t main '#{pane_id}')"
  file="$QUICK_STATE/nav.txt"
  printf 'navigation\n' >"$file"
  right="$("${t[@]}" split-window -h -P -F '#{pane_id}' -t main "env XDG_STATE_HOME='$QUICK_STATE' nvim -n -i NONE '$file'")"
  script -q /dev/null env TERM=xterm-256color "${t[@]}" attach -t main >/dev/null 2>&1 < <(sleep 20) &
  tmux_until clients 1 || out="$out
no client attached"
  tmux_until runs_nvim || out="$out
Neovim did not start in the right pane"
  client="$("${t[@]}" list-clients -F '#{client_name}')"
  "${t[@]}" select-pane -t "$left"
  press "$client" C-l
  tmux_until active "$right" || out="$out
C-l in a shell does not move to the pane on the right"
  tmux_until screen_shows navigation || out="$out
Neovim did not show the file"
  press "$client" : v s p l i t Enter
  sleep 0.5
  press "$client" C-h
  sleep 0.5
  active "$right" || out="$out
C-h in Neovim's right window left the pane instead of moving to its left window"
  press "$client" C-h
  tmux_until active "$left" || out="$out
C-h in Neovim's leftmost window did not move to the tmux pane on the left"
  press "$client" C-b t &
  tmux_until clients 2 || out="$out
prefix t opens no scratch popup"
  [ "$("${t[@]}" show -t scratch -v status 2>&1)" = off ] || out="$out
the scratch session shows a status bar"
  scratch="$("${t[@]}" list-clients -t scratch -F '#{client_name}' 2>/dev/null)"
  [ -n "$scratch" ] && press "$scratch" C-b t
  tmux_until clients 1 || out="$out
prefix t in the popup does not close it"
  "${t[@]}" has-session -t scratch 2>/dev/null || out="$out
closing the popup ended the scratch session"
  "${t[@]}" kill-server 2>/dev/null
  [ -z "$out" ] || {
    echo "${out#$'\n'}"
    return 1
  }
}

tmux_without_whichkey() {
  local home sock="dotfiles-tmux-bare-$$" status=0 prefix
  home="$(mktemp -d)"
  HOME="$home" tmux -L "$sock" -f /dev/null new-session -d \; source-file "$DOT/config/tmux/tmux.conf" || status=1
  prefix="$(tmux -L "$sock" show -gv prefix 2>&1)"
  tmux -L "$sock" kill-server 2>/dev/null
  rm -rf "$home"
  [ "$status" = 0 ] || {
    echo "tmux.conf fails to load without ~/.config/tmux/plugins/whichkey-tmux"
    return 1
  }
  [ "$prefix" = C-b ] || {
    echo "without the plugin the prefix is $prefix, not C-b"
    return 1
  }
}

tmux_whichkey_step() {
  local home dir out=""
  home="$(mktemp -d)"
  dir="$home/.config/tmux/plugins/whichkey-tmux"
  mkdir -p "$dir"
  echo keep >"$dir/file"
  HOME="$home" "$DOT/macos/tmux/whichkey.sh" >/dev/null 2>&1 && out="$out
a folder that is not the plugin was accepted"
  [ "$(cat "$dir/file" 2>/dev/null)" = keep ] || out="$out
a folder that is not the plugin was changed"
  rm -rf "$dir"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" remote add origin https://example.com/other.git
  HOME="$home" "$DOT/macos/tmux/whichkey.sh" >/dev/null 2>&1 && out="$out
a clone of another repository was accepted"
  git -C "$dir" remote set-url origin https://github.com/aguiar-arthur/whichkey-tmux.git
  printf '#!/bin/sh\n' >"$dir/whichkey.tmux"
  chmod +x "$dir/whichkey.tmux"
  HOME="$home" "$DOT/macos/tmux/whichkey.sh" >/dev/null 2>&1 || out="$out
an existing clone of the plugin was not accepted"
  rm -rf "$home"
  [ -z "$out" ] || {
    echo "${out#$'\n'}"
    return 1
  }
}
