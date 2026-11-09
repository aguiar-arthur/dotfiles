#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib.sh"

PACKAGES=(latexmk chktex texcount abntex2 cm-super enumitem fontname relsize sansmathaccent)

die() {
  echo "ERROR  $1"
  exit 1
}

PATH="$PATH:/Library/TeX/texbin"
have tlmgr || die "tlmgr not found; BasicTeX comes from the brew step (cask basictex)"
installed="$(tlmgr info --only-installed --data name)" || die "tlmgr could not list the installed packages"
missing=()
for package in "${PACKAGES[@]}"; do
  if grep -qx "$package" <<<"$installed"; then
    say ok "$package"
  else
    missing+=("$package")
  fi
done
[ "${#missing[@]}" -eq 0 ] && exit 0

tlmgr="$(command -v tlmgr)"
echo "Installing TeX packages into TeX Live: ${missing[*]} (sudo asks for your password)"
sudo -v || die "TeX Live belongs to root, so tlmgr needs sudo"
# why: a tlmgr older than the repository refuses every install until it updates itself.
perl -e 'alarm 300; exec @ARGV' sudo "$tlmgr" update --self || die "tlmgr could not update itself (network?)"
perl -e 'alarm 900; exec @ARGV' sudo "$tlmgr" install "${missing[@]}" || die "tlmgr could not install ${missing[*]} (network?)"
say install "${missing[*]}"
