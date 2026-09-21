#!/usr/bin/env python3
"""戦略候補と反証の構造契約、North Starの同一性を検査する。

  verify.py --config <同じdirectoryのplaybook.yml> --north-star <Product North Star資料の絶対path> --north-star-sha256 <validate-north-star.pyが返したsha256> \
    < '{"strategy": "<戦略本文（Markdown）>", "critique": "<反証本文（Markdown）>"}'

入力は標準入力のJSON object（keyは strategy と critique のちょうど2つ。値は空でない文字列）、
引数の playbook.yml（contract.strategy_sections / critique_verdicts）、Product North Star資料のpathとsha256だけである。
検査用fileは受け取らない。合格時は標準出力へ {"verdict": ..., "product_north_star_path": ...} を返す。
verdict は反証の「## 判定」節の値をそのまま返し、合格・要修正の意味判定は変えない。

exit 0 = 構造が契約に合う（判定は合格でも要修正でも 0） /
     2 = 標準入力が空か不正JSON、keyの過不足、契約が読めない、North Starが変更された、戦略の節の欠落・順序不正・空欄、判定欄が無いか許容語彙外（診断は標準エラー）。
"""
import argparse
import hashlib
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


def read_regular(path: Path, label: str) -> tuple[Path, bytes]:
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"{label}が通常ファイルではない")
    return path.resolve(), path.read_bytes()


def read_stdin_object() -> dict[str, str]:
    if sys.stdin.isatty():
        raise ValueError("戦略と反証を標準入力のJSON objectで渡す")
    raw = sys.stdin.read()
    if not raw.strip():
        raise ValueError("標準入力が空。{\"strategy\": ..., \"critique\": ...} を標準入力で渡す")
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"標準入力がJSONとして読めない: {exc}") from exc
    if not isinstance(payload, dict) or set(payload) != {"strategy", "critique"}:
        raise ValueError("標準入力のJSON objectは strategy と critique のちょうど2 keyを持つ")
    for key in ("strategy", "critique"):
        if not isinstance(payload[key], str) or not payload[key].strip():
            raise ValueError(f"{key} は空でない文字列にする")
    return payload


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
    args = parser.parse_args()
    try:
        playbook = load_playbook(Path(args.config))
        north_path, north_raw = read_regular(Path(args.north_star), "North Star")
        if hashlib.sha256(north_raw).hexdigest() != args.north_star_sha256:
            raise ValueError("Strategy工程中にNorth Starが変更された")
        payload = read_stdin_object()
        expected = playbook["contract"]["strategy_sections"]
        headings, content = sections(payload["strategy"])
        if headings != expected:
            raise ValueError("Strategyの節と順序が契約に一致しない")
        empty = [heading for heading in expected if not content.get(heading)]
        if empty:
            raise ValueError("Strategyの必須節が空: " + ", ".join(empty))
        _, critique = sections(payload["critique"])
        verdict = critique.get("判定", "").strip()
        allowed = playbook["contract"]["critique_verdicts"]
        if verdict not in allowed:
            raise ValueError("反証結果の判定が契約外")
    except (KeyError, OSError, UnicodeDecodeError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        return fail(str(exc))
    print(json.dumps({
        "verdict": verdict,
        "product_north_star_path": str(north_path),
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
