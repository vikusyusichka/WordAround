#!/usr/bin/env python3
"""Add new localization keys to every <lang>.lproj/Localizable.strings at once.

Usage:
    python3 scripts/add_strings.py path/to/new_strings.json

Input JSON format (English is required; other languages optional):
    {
      "homeWelcome": {
        "en": "Welcome back",
        "uk": "З поверненням",
        "es": "Bienvenido",
        ...
      },
      "homeDailyGoal": {
        "en": "Daily goal"
      }
    }

For any language missing from a key's dict, the script writes the English
value verbatim (so the build doesn't fail and the user at least sees something
intelligible). Mark these stubs by appending "  /* TODO translate */" so a
later translation pass can grep for them.

The script:
- Refuses to overwrite an existing key (run `--update` to allow that).
- Preserves comments and existing keys in each file.
- Sorts new keys alphabetically at the bottom of each file under a header
  comment so they're easy to find.

This is the canonical workflow for Phase 2 (migrating hardcoded strings from
views into Localizable.strings). Each screen migration should produce one of
these JSON files.
"""

import json
import pathlib
import re
import sys
from typing import Dict

OUT_ROOT = pathlib.Path("WordAround/Resources")

# Must match AppLanguage.rawValue. Keep alphabetical for diff readability.
LANG_CODES = [
    "ar", "bg", "bn", "cs", "da", "de", "el", "en", "es", "fa",
    "fi", "fr", "he", "hi", "hu", "id", "it", "ja", "ko", "nl",
    "no", "pl", "pt", "ro", "ru", "sv", "th", "tr", "uk", "ur",
    "vi", "zh",
]


def parse_existing(path: pathlib.Path) -> Dict[str, str]:
    """Read an existing .strings file into a {key: value} dict. Skips
    comments and blank lines."""
    if not path.exists():
        return {}
    entry_re = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')
    out = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        m = entry_re.match(line.strip())
        if m:
            out[m.group(1)] = m.group(2)
    return out


def escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    allow_update = "--update" in sys.argv
    json_path = pathlib.Path(
        [a for a in sys.argv[1:] if not a.startswith("--")][0]
    )
    new_keys = json.loads(json_path.read_text(encoding="utf-8"))

    # English is the canonical fallback. Refuse keys without an `en` value
    # because the build will read this file at runtime and we'd be writing
    # English-stub fallbacks for nothing.
    for key, by_lang in new_keys.items():
        if "en" not in by_lang:
            sys.exit(f"Key {key!r} is missing an 'en' value (required)")

    added = 0
    stubbed = 0
    skipped = 0

    for code in LANG_CODES:
        path = OUT_ROOT / f"{code}.lproj" / "Localizable.strings"
        existing = parse_existing(path)

        to_add: list[tuple[str, str, bool]] = []  # (key, value, is_stub)
        for key, by_lang in new_keys.items():
            if key in existing and not allow_update:
                skipped += 1
                continue
            if code in by_lang:
                to_add.append((key, by_lang[code], False))
                added += 1
            else:
                # Stub with English so the bundle lookup still returns
                # something the user can read instead of the raw key.
                to_add.append((key, by_lang["en"], True))
                stubbed += 1

        if not to_add:
            continue

        with path.open("a", encoding="utf-8") as f:
            f.write(f"\n/* Added by add_strings.py from {json_path.name} */\n")
            for key, value, is_stub in sorted(to_add):
                stub_marker = "  /* TODO translate */" if is_stub else ""
                f.write(f'"{key}" = "{escape(value)}";{stub_marker}\n')

    print(f"Added: {added}, stubbed (English fallback): {stubbed}, skipped: {skipped}")
    if stubbed:
        print(f"\nFind stubs with: grep -rn 'TODO translate' WordAround/Resources/")


if __name__ == "__main__":
    main()
