from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from markitdown import MarkItDown


@dataclass(slots=True)
class ConversionResult:
    source_path: Path
    output_path: Path
    text_length: int


class MarkdownConverter:
    def __init__(self) -> None:
        self._client = MarkItDown(enable_plugins=False)

    def convert_file(self, source_path: Path, output_dir: Path) -> ConversionResult:
        source = source_path.expanduser().resolve()
        target_dir = output_dir.expanduser().resolve()
        target_dir.mkdir(parents=True, exist_ok=True)

        result = self._client.convert(str(source))
        markdown_text = result.text_content.strip()
        output_path = self._build_output_path(source, target_dir)
        output_path.write_text(f"{markdown_text}\n", encoding="utf-8")

        return ConversionResult(
            source_path=source,
            output_path=output_path,
            text_length=len(markdown_text),
        )

    def _build_output_path(self, source_path: Path, output_dir: Path) -> Path:
        safe_stem = source_path.stem.strip() or "converted"
        candidate = output_dir / f"{safe_stem}.md"
        counter = 1

        while candidate.exists():
            candidate = output_dir / f"{safe_stem}_{counter}.md"
            counter += 1

        return candidate
