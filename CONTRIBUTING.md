# Contributing

These are one person's dotfiles, kept small on purpose. Issues and pull requests are welcome,
and so is forking it as the start of your own setup. Report a security problem privately, as
[SECURITY.md](SECURITY.md) says, not in an issue.

## Making a change

1. **Find the context.** The repository is split into contexts (core, workspace, code, git,
   LaTeX, Markdown, install, tests, Windows), each with one doc in [docs/](docs). The table in
   [AGENTS.md](AGENTS.md#context-map) says which one owns what. Read that doc before the code:
   its "Changing it" section has the steps for the usual changes (a server, a formatter, a key,
   a toggle, a snippet, a program).
2. **Change three things together:** the code, its check in `tests/` and its docs (the README
   table of its keys, the context doc).
3. **Run the tests.** `tests/nvim.sh` takes seconds; `tests/nvim.sh full` drives a real Neovim
   in tmux and takes minutes. Run `full` when the context doc names a `full:` test you touched.
   In the pull request, say what you could not check (GUI, real language servers, LaTeX).

## The rules that surprise people

The full list is in [AGENTS.md](AGENTS.md#rules); these are the ones a pull request most
often misses:

- **No comments in code.** Names and key descriptions say what; a reason worth keeping goes in
  one sentence in the context's doc.
- **Only proven plugins.** Not archived, a commit in the last two years, at least 500 GitHub
  stars, not a fork. Prefer a built-in feature or a plugin already here.
- **Our code is tested.** Code of our own gets a check in `tests/`, and a fixed bug gets a check
  that fails without the fix.
- **Every program goes in a Brewfile**, the one of the part that needs it.
- **macOS only**, and Dracula everywhere.
- **Never run `:Lazy update` or `:Lazy sync` just to check something.** They rewrite the
  committed `lazy-lock.json`.
- **English** in code, docs and commit messages. A commit message is in the imperative and
  says why.

## With an AI assistant

[AGENTS.md](AGENTS.md) is written for one: the context map, the rules and the steps above.
Claude Code reads it through `CLAUDE.md`; other assistants read `AGENTS.md` directly.
