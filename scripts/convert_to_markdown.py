from __future__ import annotations

import argparse
from pathlib import Path

from markitdown import MarkItDown


def build_output_path(source_path: Path, output_dir: Path) -> Path:
    safe_stem = source_path.stem.strip() or "converted"
    candidate = output_dir / f"{safe_stem}.md"
    counter = 1

    while candidate.exists():
        candidate = output_dir / f"{safe_stem}_{counter}.md"
        counter += 1

    return candidate


def convert_file(source_path: Path, output_dir: Path) -> Path:
    source = source_path.expanduser().resolve()
    target_dir = output_dir.expanduser().resolve()
    target_dir.mkdir(parents=True, exist_ok=True)

    converter = MarkItDown(enable_plugins=False)
    result = converter.convert(str(source))
    markdown_text = result.text_content.strip()
    output_path = build_output_path(source, target_dir)
    output_path.write_text(f"{markdown_text}\n", encoding="utf-8")
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert one file to Markdown.")
    parser.add_argument("source_path")
    parser.add_argument("output_dir")
    args = parser.parse_args()

    output_path = convert_file(Path(args.source_path), Path(args.output_dir))
    print(output_path)


if __name__ == "__main__":
    main()
