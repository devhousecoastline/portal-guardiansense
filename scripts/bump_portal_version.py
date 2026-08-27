#!/usr/bin/env python3
"""Sobe patch e build do portal (pubspec.yaml + AppConstants).

Convenção: a cada publish, 1.0.N+M → 1.0.(N+1)+(M+1).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBSPEC = ROOT / "pubspec.yaml"
CONSTANTS = ROOT / "lib" / "app" / "constants.dart"

VERSION_RE = re.compile(
    r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*(#.*)?$",
    re.MULTILINE,
)
PORTAL_VERSION_RE = re.compile(
    r"(static const String portalVersion = ')(\d+\.\d+\.\d+)(';)",
)
PORTAL_BUILD_RE = re.compile(
    r"(static const int portalBuild = )(\d+)(;)",
)


def main() -> int:
    pubspec = PUBSPEC.read_text(encoding="utf-8")
    match = VERSION_RE.search(pubspec)
    if not match:
        print("Não achei version: x.y.z+build em pubspec.yaml", file=sys.stderr)
        return 1

    major, minor, patch, build = (int(g) for g in match.groups()[:4])
    new_patch = patch + 1
    new_build = build + 1
    new_semver = f"{major}.{minor}.{new_patch}"
    new_full = f"{new_semver}+{new_build}"

    pubspec = VERSION_RE.sub(
        lambda m: f"version: {new_full}"
        + (f" {m.group(5)}" if m.group(5) else ""),
        pubspec,
        count=1,
    )
    PUBSPEC.write_text(pubspec, encoding="utf-8")

    constants = CONSTANTS.read_text(encoding="utf-8")
    if not PORTAL_VERSION_RE.search(constants) or not PORTAL_BUILD_RE.search(
        constants
    ):
        print("Não achei portalVersion/portalBuild em constants.dart", file=sys.stderr)
        return 1

    constants = PORTAL_VERSION_RE.sub(
        rf"\g<1>{new_semver}\g<3>", constants, count=1
    )
    constants = PORTAL_BUILD_RE.sub(rf"\g<1>{new_build}\g<3>", constants, count=1)
    CONSTANTS.write_text(constants, encoding="utf-8")

    print(f"Versao: {major}.{minor}.{patch}+{build} -> {new_full}")
    print(f"NEW_VERSION={new_semver}")
    print(f"NEW_BUILD={new_build}")
    print(f"NEW_FULL={new_full}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
