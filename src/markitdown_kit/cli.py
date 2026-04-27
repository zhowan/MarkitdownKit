from __future__ import annotations

import argparse
from pathlib import Path

from .converter import MarkdownConverter


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert files to Markdown with MarkItDown.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    convert_parser = subparsers.add_parser("convert", help="Convert one file to a markdown file.")
    convert_parser.add_argument("source_path", help="Source file path")
    convert_parser.add_argument("output_dir", help="Output directory")

    args = parser.parse_args()

    if args.command == "convert":
        converter = MarkdownConverter()
        result = converter.convert_file(Path(args.source_path), Path(args.output_dir))
        print(result.output_path)


if __name__ == "__main__":
    main()
