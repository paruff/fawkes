#!/usr/bin/env python3
"""Fail if the design system's shared colours drift from the suite tokens.

Compares the indigo (primary) and neutral scales in
design-system/src/tokens/colors.ts with color.indigo / color.neutral in
tokens.json from https://ufawkes.dev/design/tokens.json.

Usage: check-design-token-sync.py [path-or-url-to-tokens.json]
"""

import json
import re
import sys
import urllib.request

DEFAULT = "https://ufawkes.dev/design/tokens.json"
COLORS_TS = "design-system/src/tokens/colors.ts"
# colors.ts scale name -> tokens.json scale name
SCALES = {"primary": "indigo", "gray": "neutral"}


def load_tokens(src):
    if src.startswith("http"):
        with urllib.request.urlopen(src, timeout=30) as r:
            return json.load(r)
    with open(src) as f:
        return json.load(f)


def ts_scale(text, name):
    m = re.search(rf"\b{name}:\s*\{{(.*?)\}}", text, re.DOTALL)
    if not m:
        sys.exit(f"scale {name!r} not found in {COLORS_TS}")
    return dict(re.findall(r"(\d+):\s*'(#[0-9a-fA-F]{6})'", m.group(1)))


def main():
    tokens = load_tokens(sys.argv[1] if len(sys.argv) > 1 else DEFAULT)["color"]
    with open(COLORS_TS) as f:
        text = f.read()
    bad = []
    for ts_name, tok_name in SCALES.items():
        have = ts_scale(text, ts_name)
        for step, value in tokens[tok_name].items():
            if step in have and have[step].lower() != value.lower():
                bad.append(f"{ts_name}.{step}: design system {have[step]}, tokens {value}")
    if bad:
        sys.exit("design system drifted from tokens.json:\n  " + "\n  ".join(bad))
    print("design system colours match tokens.json")


if __name__ == "__main__":
    main()
