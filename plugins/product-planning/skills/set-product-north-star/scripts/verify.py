#!/usr/bin/env python3
"""Product North Star本文の構造契約を検査する。

  verify.py --config <同じdirectoryのplaybook.yml>  < <North Star本文（Markdown）>

入力は標準入力の本文と、引数の playbook.yml（contract.north_star_sections / forbidden_sections）だけである。
検査用fileは受け取らない。合格時は標準出力へ {"verified": true, "sections": [...]} を返す。

exit 0 = 契約を満たす / 2 = 標準入力が空、契約が読めない、必須節の欠落・順序不正・空欄、戦略の節の混入（診断は標準エラー）。
検査するのは述語であって、North Starの内容の良し悪しではない。
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


def fail(message: str, code: int = 2) -> int:
    print(f"[error] {message}", file=sys.stderr)
    return code


def load_playbook(config_path: Path) -> dict:
    if config_path.is_symlink() or not config_path.is_file():
        raise ValueError(f"契約fileが通常ファイルではない: {config_path}")
    result = subprocess.run(
        ["yq", "-o=json", "-I=0", ".", str(config_path)],
        check=True,
        capture_output=True,
        text=True,
    )
    resolved = json.loads(result.stdout)
    if not isinstance(resolved, dict) or not isinstance(resolved.get("contract"), dict):
        raise ValueError("契約fileは top-level に contract を持つ playbook.yml にする")
    return resolved


def read_stdin() -> str:
    if sys.stdin.isatty():
        raise ValueError("North Star本文を標準入力で渡す")
    body = sys.stdin.read()
    if not body.strip():
        raise ValueError("標準入力が空。North Star本文を標準入力で渡す")
    return body


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
    args = parser.parse_args()
    try:
        playbook = load_playbook(Path(args.config))
        expected = playbook["contract"]["north_star_sections"]
        forbidden = set(playbook["contract"]["forbidden_sections"])
        body = read_stdin()
        headings, content = sections(body)
        if headings != expected:
            raise ValueError("North Starの節と順序が契約に一致しない")
        empty = [heading for heading in expected if not content.get(heading)]
        if empty:
            raise ValueError("North Starの必須節が空: " + ", ".join(empty))
        mixed = forbidden.intersection(headings)
        if mixed:
            raise ValueError("North Starに戦略の節が混入している: " + ", ".join(sorted(mixed)))
    except (KeyError, OSError, UnicodeDecodeError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        return fail(str(exc))
    print(json.dumps({"verified": True, "sections": headings}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
