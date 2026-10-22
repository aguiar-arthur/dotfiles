#!/usr/bin/env bash
frames="${1:-0}"

trap 'printf "\033[?25h"' EXIT

awk -v frames="$frames" '
function digit(x, n,    s, r, c, lit) {
  for (s = 0; s < 7; s++) {
    lit = n >= 0 && int(mask[n] / 2 ^ s) % 2
    for (r = r0[s]; r <= r1[s]; r++)
      for (c = c0[s]; c <= c1[s]; c++) {
        kind[top + r, x + c] = lit ? 1 : 2
        glyph[top + r, x + c] = lit ? "█" : "░"
      }
  }
}

function colon(x, on,    r, c) {
  for (r = 2; r <= 4; r += 2)
    for (c = 0; c < 2; c++) {
      kind[top + r, x + c] = on ? 1 : 2
      glyph[top + r, x + c] = on ? "█" : "░"
    }
}

BEGIN {
  cols = 70
  rows = 11
  top = 1
  split("0 1 4 6 4 1 3", r0s)
  split("0 2 5 6 5 2 3", r1s)
  split("2 6 6 2 0 0 2", c0s)
  split("5 7 7 5 1 1 5", c1s)
  for (s = 0; s < 7; s++) {
    r0[s] = r0s[s + 1]
    r1[s] = r1s[s + 1]
    c0[s] = c0s[s + 1]
    c1[s] = c1s[s + 1]
  }
  split("63 6 91 79 102 109 125 7 127 111", m)
  for (n = 0; n < 10; n++) mask[n] = m[n + 1]
  color[1] = "189;147;249"
  color[2] = "68;71;90"
  color[3] = "98;114;164"
  cmd = "LC_ALL=C date +\"%H %M %S %A %e %B %Y\""

  printf "\033[?25l"
  for (f = 0; frames == 0 || f < frames; f++) {
    cmd | getline line
    close(cmd)
    split(line, p, " ")
    if (p[3] != last) {
      last = p[3]
      since = f
    }
    on = (f - since) % 2 == 0
    delete kind
    delete glyph
    x = int((cols - 66) / 2)
    for (i = 0; i < 3; i++) {
      if (i > 0) {
        colon(x + 2, on)
        x += 6
      }
      v = p[i + 1] + 0
      digit(x, int(v / 10))
      digit(x + 10, v % 10)
      x += 18
    }
    text = tolower(p[4] " " (p[5] + 0) " " p[6] " " p[7])
    start = int((cols - length(text)) / 2)
    for (i = 0; i < length(text); i++) {
      kind[top + 8, start + i] = 3
      glyph[top + 8, start + i] = substr(text, i + 1, 1)
    }
    out = "\033[H"
    for (r = 0; r < rows; r++) {
      prev = 0
      for (c = 0; c < cols; c++) {
        k = kind[r, c] + 0
        if (k == 0) {
          out = out " "
          continue
        }
        if (k != prev) {
          out = out "\033[38;2;" color[k] "m"
          prev = k
        }
        out = out glyph[r, c]
      }
      out = out "\033[0m"
      if (r < rows - 1) out = out "\n"
    }
    printf "%s", out
    fflush()
    system("sleep 0.5")
  }
}
'
