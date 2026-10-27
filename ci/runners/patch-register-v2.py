#!/usr/bin/env python3
"""Fix runner v2's incorrect GitHub SHA-256 release note parser, safely."""
from pathlib import Path
import subprocess
import sys

if len(sys.argv) != 2:
    raise SystemExit("Usage: python3 patch-register-v2.py /path/to/cc-dkr01-register-runners-v2.sh")
p = Path(sys.argv[1]).resolve()
source = p.read_text()
start_marker = 'read -r download_url expected_sha archive_name < <(python3 -c'
end_marker = '[[ "$expected_sha" =~ ^[a-f0-9]{64}$ ]]'
if start_marker not in source or end_marker not in source:
    raise SystemExit("STOP: expected v2 checksum parser not found; no changes")
start = source.index(start_marker)
end = source.index(end_marker, start)
replacement = '''resolved="$(python3 -c '\nimport json, re, sys\ntry:\n    meta = json.load(sys.stdin)\nexcept ValueError as exc:\n    raise SystemExit(f"Invalid GitHub release metadata: {exc}")\npattern = re.compile(r"actions-runner-linux-x64-[0-9]+(?:\\.[0-9]+)+\\.tar\\.gz")\nassets = [a for a in meta.get("assets", []) if pattern.fullmatch(a.get("name", ""))]\nif len(assets) != 1:\n    raise SystemExit("Expected exactly one GitHub runner Linux x64 archive")\na = assets[0]\nname = a["name"]\nurl = a.get("browser_download_url", "")\nif not url.startswith("https://github.com/actions/runner/releases/download/"):\n    raise SystemExit("Unexpected GitHub runner download URL")\ndig = re.fullmatch(r"sha256:([a-fA-F0-9]{64})", a.get("digest") or "")\nbody = meta.get("body") or ""\nnotes = re.search(re.escape(name)+r"[\\x60\\s:|–-]+(?:SHA-?256[\\s:=]+)?([a-fA-F0-9]{64})(?![a-fA-F0-9])", body, re.I)\nif dig and notes and dig.group(1).lower() != notes.group(1).lower():\n    raise SystemExit("Checksum disagreement between API digest and release notes")\nsha = dig or notes\nif sha is None:\n    raise SystemExit("No official SHA256 for Linux runner; refusing to proceed")\nprint(f"{url}\\t{sha.group(1).lower()}\\t{name}")\n' <<< "$metadata")" || fail 'Release information/checksum incomplete'\nIFS=$'\\t' read -r download_url expected_sha archive_name <<< "$resolved"\n'''
updated = source[:start] + replacement + source[end:]
backup = p.with_name(p.name + ".before-digest-fix")
if backup.exists():
    raise SystemExit("STOP: backup already exists; refusing to overwrite")
subprocess.run(["bash", "-n"], input=updated, text=True, check=True)
backup.write_text(source)
p.write_text(updated)
print(f"PATCHED: {p}\nBACKUP: {backup}\nVALIDATED: bash -n passed")
