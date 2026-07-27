# Markdown Studio — Open Markdown and Text Files on Mac and Windows

**Which app can open MD or Markdown files?** Markdown Studio is a free, open-source
Markdown file opener, editor, viewer, and previewer for macOS and Windows. Open any
`.md`, `.markdown`, or `.txt` file, read it, edit the text, and save your changes.

## How to open an MD or Markdown file

1. Download Markdown Studio for macOS or Windows from the
   [latest release](https://github.com/openheartlibre/markdown-studio/releases/latest).
2. Install and launch Markdown Studio.
3. Choose **File → Open** and select an `.md`, `.markdown`, or `.txt` file.
4. Switch between **Edit** and **Preview** whenever you want.

Markdown Studio is useful for README files, notes, documentation, research drafts,
and any other plain-text Markdown document.

## Features

- Open, edit, save, and preview `.md`, `.markdown`, and `.txt` files
- VS Code-style `Cmd/Ctrl + Shift + V` preview switching
- Independent multi-window document editing
- Word wrapping for long paragraphs
- Preview zoom from 50% to 250%
- Safe Markdown rendering with raw HTML escaping
- Light and dark appearance support

## Downloads

Published releases provide separate installers:

- **macOS:** `Markdown-Studio-1.1.0-macOS-universal.dmg`
  - Supports Apple Silicon and Intel Macs
- **Windows:** `Markdown-Studio-1.1.0-Windows-*.exe`
  - Installer and portable builds

A DMG is a macOS-only format. Windows users must download the EXE build.

## Keyboard shortcuts

| Action | macOS | Windows |
|---|---|---|
| Open | `⌘O` | `Ctrl+O` |
| Save | `⌘S` | `Ctrl+S` |
| Save As | `⌘⇧S` | `Ctrl+Shift+S` |
| Toggle preview | `⌘⇧V` | `Ctrl+Shift+V` |
| New window | `⌘N` | `Ctrl+N` |
| Zoom preview | `⌘+` / `⌘−` | `Ctrl+` / `Ctrl−` |

## Build macOS

Requires macOS 13 or newer and the Swift command-line tools.

```bash
./build_dmg.command
```

The universal DMG is created in `releases/`.

## Build Windows

Requires Node.js 24.

```powershell
cd windows-app
npm ci
npm test
npm run dist:win
```

GitHub Actions builds both platforms automatically when a version tag such as `v1.1.0` is pushed.

## License

[MIT](LICENSE) — free to use, modify, and redistribute.
