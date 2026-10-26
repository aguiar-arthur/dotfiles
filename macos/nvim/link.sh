#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib.sh"

skim_preferences() {
  local skim=net.sourceforge.skim-app.skim
  pref "$skim" SKTeXEditorPreset ""
  pref "$skim" SKTeXEditorCommand "$(command -v nvim || echo nvim)"
  pref "$skim" SKTeXEditorArguments "--headless -c \"VimtexInverseSearch %line '%file'\""
  pref_bool "$skim" SKAutoCheckFileUpdate
  pref_bool "$skim" SKAutoReloadFileUpdate
}

link config/nvim "$HOME/.config/nvim"
link config/rumdl/rumdl.toml "$HOME/.config/rumdl/rumdl.toml"
link config/latex/latexmkrc "$HOME/.latexmkrc"
skim_preferences
echo "Done."
