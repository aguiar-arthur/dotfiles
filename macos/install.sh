#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=()

for part in terminal apps nvim; do
  "$HERE/$part/install.sh" || FAILED+=("$part")
done

if [ "${#FAILED[@]}" -gt 0 ]; then
  printf '\nFailed: %s. Fix the errors above and run macos/install.sh (or macos/<part>/install.sh) again.\n' "${FAILED[*]}"
  exit 1
fi
printf '\nDone. Open a new terminal (or run: exec zsh).\n'
