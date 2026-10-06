# Terminal

## Starship

A two-line prompt with icons (Nerd Font) and colored "pills" in Dracula colors:

```text
(mac) (~/dotfiles) (main !1 ?2) +4 (py 3.13) ───────────────── 3s  11:10
❯
```

- **Line 1:** OS, directory, git branch and status (`!` modified, `?` untracked, `+` staged,
  `»` renamed, `✘` deleted, `=` conflicted, `⇡` `⇣` ahead / behind, stash icon), lines added
  and removed, then language versions. On the right, after a `─` fill: the duration of
  commands longer than 2 s and the time.
- **Line 2:** user and host (only over SSH or as root), sudo, background jobs, the exit code
  of a failed command and `❯` (green, red after a failure, `❮` in vi command mode).

Details of `config/starship/starship.toml`:

- Colors are named in `[palettes.dracula]`; modules refer to them by name (`fg:pink`).
- The directory shows up to 3 components, truncated to the repository root, with icons for
  Documents, Downloads, Desktop and dotfiles.
- Language modules (Python, Node, Lua, Ruby, Rust, Go, Java, C, Docker context, Nix shell)
  appear only in directories that contain that kind of project.
- The git pill's closing cap sits outside the optional `(...)` group, so the pill closes even
  when the repository is clean and the status group is empty.
- Icons are written as `\uXXXX` escapes, so the file stays plain ASCII.
- Commands time out after 1 s, so a slow tool never blocks the prompt.

`starship explain` describes the current prompt; `starship timings` shows what is slow.

## iTerm2

`config/iterm2/dracula.json` is a **Dynamic Profile**: iTerm2 reads it from
`~/Library/Application Support/iTerm2/DynamicProfiles/` (linked by `install.sh`) and shows the
profile "Dotfiles (Dracula)". It inherits the *Default* profile, including the font, and only
changes:

- the Dracula palette (16 ANSI colors, background, cursor, selection);
- *Option* as Meta / Esc+, required for `Alt-j` / `Alt-k` in Neovim;
- bar cursor, slight transparency with blur, 140×40, 100 000 lines of scrollback.

The font must be a Nerd Font (the Brewfile installs JetBrainsMono Nerd Font) for the prompt
and editor icons. Set it in the profile inside iTerm2 or add `"Normal Font"` to the JSON.
iTerm2 reloads the file by itself after edits.

## zsh

`install.sh` adds two marked blocks to `~/.zshrc`, each only once:

| Block | Content |
|---|---|
| `dotfiles: starship` | `eval "$(starship init zsh)"` when `starship` is installed |
| `dotfiles: emacs` | `alias e='emacsclient -n -c -a ""'`: open a file in a new frame of the running Emacs, starting the daemon if needed |

To remove one, delete the lines between its `# >>>` and `# <<<` markers.
