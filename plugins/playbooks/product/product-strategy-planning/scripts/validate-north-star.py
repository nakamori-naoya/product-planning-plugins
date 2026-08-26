#!/usr/bin/env python3
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys


def fail(message: str) -> int:
    print(f"[error] {message}", file=sys.stderr)
    return 2


def load_playbook(config_path: Path) -> dict:
    result = subprocess.run(
        ["yq", "-o=json", "-I=0", ".", str(config_path)],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)["playbook"]


def sections(body: str) -> tuple[list[str], dict[str, str]]:
    headings: list[str] = []
    content: dict[str, list[str]] = {}
    current: str | None = None
    for line in body.splitlines():
        match = re.match(r"^##[ ]+(.+?)[ ]*$", line)
        if match:
            current = match.group(1)
            if current in content:
                raise ValueError(f"節が重複している: {current}")
            headings.append(current)
            content[current] = []
        elif current is not None:
            content[current].append(line)
    return headings, {key: "\n".join(value).strip() for key, value in content.items()}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--north-star", required=True)
    args = parser.parse_args()
    path = Path(args.north_star)
    try:
        if path.is_symlink() or not path.is_file():
            raise ValueError("North Starが通常ファイルではない")
        raw = path.read_bytes()
        body = raw.decode("utf-8")
        contract = load_playbook(Path(args.config))["contract"]
        required = contract["north_star_sections"]
        forbidden = set(contract["forbidden_north_star_sections"])
        headings, content = sections(body)
        positions = [headings.index(heading) for heading in required if heading in headings]
        if len(positions) != len(required) or positions != sorted(positions):
            raise ValueError("North Starの必須節が欠落または順序不正")
        empty = [heading for heading in required if not content.get(heading)]
        if empty:
            raise ValueError("North Starの必須節が空: " + ", ".join(empty))
        mixed = forbidden.intersection(headings)
        if mixed:
            raise ValueError("North Starに戦略の節が混入している: " + ", ".join(sorted(mixed)))
    except (KeyError, OSError, UnicodeDecodeError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        return fail(str(exc))
    print(json.dumps({
        "product_north_star_path": str(path.resolve()),
        "product_north_star_sha256": hashlib.sha256(raw).hexdigest(),
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
