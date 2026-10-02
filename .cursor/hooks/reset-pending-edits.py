#!/usr/bin/env python3
"""Clear leftover source-edit records at the start of each user prompt.

Ask/Plan turns must not inherit pending-edits.json from a previous Agent chat.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pending_edits import empty_pending


def main() -> None:
    sys.stdin.read()
    empty_pending()
    print(json.dumps({}))


if __name__ == "__main__":
    main()
