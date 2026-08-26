#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys


def fail(message: str, code: int = 2) -> int:
    print(f"[error] {message}", file=sys.stderr)
    return code


def load_playbook(config_path: Path) -> dict:
    result = subprocess.run(
        ["yq", "-o=json", "-I=0", ".", str(config_path)],
        check=True,
        capture_output=True,
        text=True,
    )
    resolved = json.loads(result.stdout)
    return resolved["playbook"]


def read_regular(path: Path, label: str) -> tuple[Path, str]:
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"{label}が通常ファイルではない")
    absolute = path.resolve()
    return absolute, path.read_text(encoding="utf-8")


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
    try:
        playbook = load_playbook(Path(args.config))
        expected = playbook["contract"]["north_star_sections"]
        forbidden = set(playbook["contract"]["forbidden_sections"])
        path, body = read_regular(Path(args.north_star), "North Star")
        headings, content = sections(body)
        if headings != expected:
            raise ValueError("North Starの節と順序が契約に一致しない")
        empty = [heading for heading in expected if not content.get(heading)]
        if empty:
            raise ValueError("North Starの必須節が空: " + ", ".join(empty))
        mixed = forbidden.intersection(headings)
        if mixed:
            raise ValueError("North Starに戦略の節が混入している: " + ", ".join(sorted(mixed)))
    except (KeyError, OSError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        return fail(str(exc))
    print(json.dumps({"product_north_star_path": str(path)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
