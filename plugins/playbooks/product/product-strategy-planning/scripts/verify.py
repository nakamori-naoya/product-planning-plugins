#!/usr/bin/env python3
import argparse
import hashlib
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
    return json.loads(result.stdout)["playbook"]


def read_regular(path: Path, label: str) -> tuple[Path, bytes]:
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"{label}が通常ファイルではない")
    return path.resolve(), path.read_bytes()


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
    parser.add_argument("--north-star-sha256", required=True)
    parser.add_argument("--strategy", required=True)
    parser.add_argument("--critique", required=True)
    args = parser.parse_args()
    try:
        playbook = load_playbook(Path(args.config))
        north_path, north_raw = read_regular(Path(args.north_star), "North Star")
        if hashlib.sha256(north_raw).hexdigest() != args.north_star_sha256:
            raise ValueError("Strategy工程中にNorth Starが変更された")
        strategy_path, strategy_raw = read_regular(Path(args.strategy), "Strategy")
        _, critique_raw = read_regular(Path(args.critique), "Critique")
        expected = playbook["contract"]["strategy_sections"]
        headings, content = sections(strategy_raw.decode("utf-8"))
        if headings != expected:
            raise ValueError("Strategyの節と順序が契約に一致しない")
        empty = [heading for heading in expected if not content.get(heading)]
        if empty:
            raise ValueError("Strategyの必須節が空: " + ", ".join(empty))
        _, critique = sections(critique_raw.decode("utf-8"))
        verdict = critique.get("判定", "").strip()
        allowed = playbook["contract"]["critique_verdicts"]
        if verdict not in allowed:
            raise ValueError("反証結果の判定が契約外")
        if verdict == "要修正":
            return fail("反証結果が要修正のため戦略を検証済みにしない", 3)
    except (KeyError, OSError, UnicodeDecodeError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        return fail(str(exc))
    print(json.dumps({
        "verified_strategy_path": str(strategy_path),
        "product_north_star_path": str(north_path),
        "verdict": "合格",
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
