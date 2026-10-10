import io
import json
import os
import re
import subprocess
import sys
import tokenize

root = sys.argv[1]
files = [line.strip() for line in sys.stdin if line.strip()]
problems = []


def strip_strings(line):
    line = re.sub(r'"(?:[^"\\]|\\.)*"', '""', line)
    return re.sub(r"'[^']*'", "''", line)


def shell_comments(path):
    with open(path, "rb") as handle:
        source = handle.read()
    result = subprocess.run(
        ["shfmt", "--to-json"], input=source, capture_output=True, check=False
    )
    if result.returncode != 0:
        return []
    found = []

    def walk(node):
        if isinstance(node, dict):
            for key in ("Comments", "Last"):
                for comment in node.get(key) or []:
                    if isinstance(comment, dict) and "Text" in comment:
                        found.append((comment["Pos"]["Line"], comment["Text"]))
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    walk(json.loads(result.stdout))
    return [(line, text) for line, text in found if not (line == 1 and text.startswith("!"))]


def python_comments(path):
    with open(path, "rb") as handle:
        tokens = tokenize.tokenize(io.BytesIO(handle.read()).readline)
        return [(tok.start[0], tok.string) for tok in tokens if tok.type == tokenize.COMMENT]


def text_comments(path):
    found = []
    with open(path, encoding="utf-8") as handle:
        for number, line in enumerate(handle, 1):
            if "#" in strip_strings(line):
                found.append((number, line.strip()))
    return found


for rel in files:
    path = os.path.join(root, rel)
    name = os.path.basename(rel)
    if not os.path.isfile(path):
        continue
    with open(path, "rb") as handle:
        first = handle.readline()
    if rel.endswith(".sh") or (first.startswith(b"#!") and b"bash" in first):
        hits = shell_comments(path)
    elif rel.endswith(".py"):
        hits = python_comments(path)
    elif rel.endswith((".toml", ".yml", ".yaml", ".zsh", ".gitignore", ".editorconfig")) or name in (
        "Brewfile",
        ".gitignore",
        ".editorconfig",
    ):
        hits = text_comments(path)
    else:
        continue
    for line, text in hits:
        problems.append(f"{rel}:{line}: comment {text[:40]!r}")

print("\n".join(problems))
