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
  local i
  for i in $(seq 50); do
    "$@" && return 0
    sleep 0.2
  done
  return 1
}

tmux_keys() {
  local -a t=(tmux -L "dotfiles-tmux-keys-$$")
  local left right client scratch out=""
  active() { [ "$("${t[@]}" display -p -t main '#{pane_id}')" = "$1" ]; }
  runs_nvim() { [ "$("${t[@]}" display -p -t "$right" '#{pane_current_command}')" = nvim ]; }
  clients() { [ "$("${t[@]}" list-clients | wc -l | tr -d ' ')" = "$1" ]; }
  press() { perl -e 'alarm 3; exec @ARGV' "${t[@]}" send-keys -K -c "$@"; }
  "${t[@]}" -f "$DOT/config/tmux/tmux.conf" new-session -d -x 120 -y 30 -s main sh
  left="$("${t[@]}" display -p -t main '#{pane_id}')"
  right="$("${t[@]}" split-window -h -P -F '#{pane_id}' -t main "nvim --clean -n -i NONE")"
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
  press "$client" C-h
  sleep 0.5
  active "$right" || out="$out
C-h in Neovim left its pane instead of reaching Neovim"
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
