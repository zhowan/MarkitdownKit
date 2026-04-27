# MarkItDown Kit

[English](./README.md) | [中文](./README.zh-CN.md)

MarkItDown Kit is a lightweight macOS app for converting files into Markdown with [Microsoft MarkItDown](https://github.com/microsoft/markitdown).

The UI is built with SwiftUI, and the app calls a globally installed `markitdown` command on your machine. That keeps the `.app` bundle very small while still giving you a simple drag-and-drop desktop workflow.

## Features

- Native macOS app built with SwiftUI
- Drag and drop files into the window
- Batch conversion
- Default output next to the source file
- Optional shared output folder
- Small app bundle size
- Conversion log inside the app

## Requirements

- macOS
- Xcode command line tools or Xcode
- `pipx`
- `markitdown` installed globally through `pipx`

## Install `pipx`

If you do not already have `pipx`:

```bash
brew install pipx
pipx ensurepath
```

Restart Terminal after that, or run:

```bash
source ~/.zshrc
```

## Install MarkItDown

Recommended full office-friendly install:

```bash
pipx install --force "markitdown[pdf,docx,pptx,xlsx,xls]>=0.1.5,<0.2"
```

Smaller install without Excel support:

```bash
pipx install --force "markitdown[pdf,docx,pptx]>=0.1.5,<0.2"
```

## Verify Your Setup

Run:

```bash
~/.local/bin/markitdown --help
```

If that works, the app should be able to find `markitdown`.

If `markitdown` is not found in your shell, add this to `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.zshrc
```

## Run the App

### Option 1: Double-click

Double-click [start.command](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/start.command).

It will build and launch the app.

### Option 2: From Terminal

```bash
cd /Users/wong/CodeHub/WongsCodesx/MarkitdownKit
swift run MarkitdownKitMac
```

## Package the App

To build the `.app` bundle:

```bash
cd /Users/wong/CodeHub/WongsCodesx/MarkitdownKit
./scripts/package_app.sh
```

That will generate:

[MarkitdownKitMac.app](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/MarkitdownKitMac.app)

## Release Model

This app does not embed Python or MarkItDown.

That means:

- The app stays very small
- The target machine must already have `markitdown` installed
- The easiest setup is `pipx`

## Supported File Types

Supported formats depend on how you installed `markitdown`.

Recommended coverage includes:

- PDF
- Word `.docx`
- PowerPoint `.pptx`
- Excel `.xlsx` and `.xls`
- HTML
- CSV, JSON, XML, and other text-based formats

## Useful Commands

Upgrade MarkItDown:

```bash
pipx upgrade markitdown
```

Reinstall MarkItDown:

```bash
pipx install --force "markitdown[pdf,docx,pptx,xlsx,xls]>=0.1.5,<0.2"
```

Check where `markitdown` is installed:

```bash
command -v markitdown
```

## Project Structure

- [Package.swift](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/Package.swift): Swift package manifest
- [Sources/MarkitdownKitMac/MarkitdownKitMacApp.swift](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/Sources/MarkitdownKitMac/MarkitdownKitMacApp.swift): app UI and conversion logic
- [scripts/package_app.sh](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/scripts/package_app.sh): packaging script
- [scripts/render_icon.swift](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/scripts/render_icon.swift): app icon generator
- [start.command](/Users/wong/CodeHub/WongsCodesx/MarkitdownKit/start.command): double-click launcher

## Notes

If you want a fully self-contained version later, that is possible, but the app bundle will become much larger because it would need to include Python and the MarkItDown dependency stack.
