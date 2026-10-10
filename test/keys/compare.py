import re
import sys
from collections import defaultdict

NONE = "—"
CONTEXTUAL = {"co", "ct", "cb", "ca"}


def absent(cell):
    return cell.startswith(NONE)


def read_dump(path):
    keys = {}
    actions = defaultdict(set)
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            parts = line.rstrip("\n").split("\t")
            if len(parts) == 4:
                mode, _scope, key, action = parts
                keys.setdefault(key, set()).add(mode)
                actions[(mode, action)].add(key)
            elif len(parts) == 2:
                key, action = parts
                keys.setdefault(key, set()).add("n")
                actions[("n", action)].add(key)
    return keys, actions


def expand(cell, group):
    found = []
    tokens = re.findall(r"`([^`]+)`(\s*…\s*`([^`]+)`)?", cell)
    for first, ranged, last in tokens:
        if ranged:
            prefix = re.match(r"^(\D+)(\d+)$", first)
            tail = re.match(r"^(\D+)(\d+)$", last)
            if prefix and tail:
                for number in range(int(prefix.group(2)), int(tail.group(2)) + 1):
                    found.append(f"{prefix.group(1)}{number}")
            continue
        for key in first.split():
            key = key.replace("<Space>", "")
            if key.startswith("C-") or not re.match(r"^[A-Za-z0-9=/.?]+$", key):
                continue
            found.append(key if group == "" or key.startswith(group) else group + key)
    return found


def read_docs(path):
    rows = []
    emacs_only = []
    group = None
    in_emacs_only = False
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.rstrip("\n")
            heading = re.match(r"^### `(\w)`", line)
            if heading:
                group, in_emacs_only = heading.group(1), False
                continue
            if line.startswith("### Top level"):
                group, in_emacs_only = "", False
                continue
            if line.startswith("### Emacs only"):
                group, in_emacs_only = None, True
                continue
            if line.startswith("## ") or (line.startswith("### ") and not in_emacs_only):
                group, in_emacs_only = None, False
                continue
            if not line.startswith("| `"):
                continue
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            if in_emacs_only:
                letter = re.findall(r"`(\w)`", cells[0])
                if letter and len(cells) >= 2:
                    for key in re.findall(r"`([^`]+)`", cells[1]):
                        if re.match(r"^[A-Za-z0-9=/.?]+$", key) and key.startswith(letter[0]):
                            emacs_only.append(key)
                continue
            if group is None or len(cells) < 2:
                continue
            nvim_cell = cells[1]
            emacs_cell = cells[2] if len(cells) > 2 else cells[1]
            for key in expand(cells[0], group):
                rows.append((key, nvim_cell, emacs_cell))
    return rows, emacs_only


def main():
    nvim_file, emacs_file, docs_file = sys.argv[1:4]
    nvim_keys, nvim_actions = read_dump(nvim_file)
    emacs_keys, emacs_actions = read_dump(emacs_file)
    rows, emacs_only = read_docs(docs_file)
    problems = []

    documented = set()
    for key, nvim_cell, emacs_cell in rows:
        documented.add(key)
        if key in CONTEXTUAL:
            continue
        if not absent(nvim_cell) and key not in nvim_keys:
            problems.append(f"Neovim lacks <Space>{key}, which docs/keymaps.md documents")
        if not absent(emacs_cell) and key not in emacs_keys:
            problems.append(f"Emacs lacks SPC {key}, which docs/keymaps.md documents")
        if absent(nvim_cell) and key in nvim_keys:
            problems.append(f"<Space>{key} exists in Neovim but docs/keymaps.md says it does not")
        if absent(emacs_cell) and key in emacs_keys:
            problems.append(f"SPC {key} exists in Emacs but docs/keymaps.md says it does not")
    for key in emacs_only:
        documented.add(key)
        if key not in emacs_keys:
            problems.append(f"Emacs lacks SPC {key}, which docs/keymaps.md documents")

    for key in sorted(nvim_keys):
        if key not in documented and key not in CONTEXTUAL:
            problems.append(f"Neovim <Space>{key} is not in docs/keymaps.md")
    for key in sorted(emacs_keys):
        if key not in documented and key not in CONTEXTUAL:
            problems.append(f"Emacs SPC {key} is not in docs/keymaps.md")

    for label, actions in (("Neovim", nvim_actions), ("Emacs", emacs_actions)):
        for (mode, action), keys in sorted(actions.items()):
            if len(keys) > 1:
                joined = ", ".join(sorted(keys))
                problems.append(f"{label} binds one action ({action}) to several leader keys: {joined}")

    print(f"{len(documented)} documented keys, {len(nvim_keys)} in Neovim, {len(emacs_keys)} in Emacs")
    for problem in problems:
        print(problem)
    return 1 if problems else 0


sys.exit(main())
