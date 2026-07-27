# Markdown Studio

Markdown Studio is a free, open-source Markdown editor and previewer for macOS and Windows.

## Features

- Open, edit, save, and preview `.md` and `.markdown` files
- VS Code-style `Cmd/Ctrl + Shift + V` preview switching
- Independent multi-window document editing
- Word wrapping for long paragraphs
- Preview zoom from 50% to 250%
- Safe Markdown rendering with raw HTML escaping
- Light and dark appearance support

## Downloads

Published releases provide separate installers:

- **macOS:** `Markdown-Studio-1.0.0-macOS-universal.dmg`
  - Supports Apple Silicon and Intel Macs
- **Windows:** `Markdown-Studio-1.0.0-Windows-*.exe`
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

GitHub Actions builds both platforms automatically when a version tag such as `v1.0.0` is pushed.

## License

[MIT](LICENSE) — free to use, modify, and redistribute.
