#!/usr/bin/env python3
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
manifest = json.loads((ROOT / "repos.json").read_text())
makefile = (ROOT / "Makefile").read_text()

match = re.search(r"ALL_REPOS\s*:=\s*((?:.*\\\n)*.*)", makefile)
if not match:
    print("ALL_REPOS not found in Makefile")
    sys.exit(1)

declared = set(match.group(1).replace("\\\n", " ").split())
listed = {entry["name"] for entry in manifest["repositories"]}

missing_in_makefile = listed - declared
missing_in_manifest = declared - listed

if missing_in_makefile or missing_in_manifest:
    for name in sorted(missing_in_makefile):
        print(f"{name} is in repos.json but not in ALL_REPOS")
    for name in sorted(missing_in_manifest):
        print(f"{name} is in ALL_REPOS but not in repos.json")
    sys.exit(1)

print(f"repos.json and the Makefile agree on {len(listed)} repositories")
