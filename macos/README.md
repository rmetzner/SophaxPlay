# SophaxPlay — macOS

Native macOS SwiftUI music player. MP3 + FLAC. Minimal design.

## Setup in Xcode

1. **File → New → Project** → macOS → App
   - Product Name: `SophaxPlay`
   - Bundle ID: `com.sophax.sophaxplay.mac`
   - Interface: SwiftUI · Language: Swift
2. Save inside `macos/`
3. Delete generated `ContentView.swift` + `SophaxPlayApp.swift`
4. Drag all `.swift` files from `macos/SophaxPlay/` into the project (**Copy if needed** ✓)
5. **Signing & Capabilities** → add your Apple Developer account
6. In **Capabilities** add: **Background Modes → Audio** (for lock screen controls)
7. Run: **⌘R**

## Controls

| Action | Shortcut |
|--------|----------|
| Play / Pause | `Space` |
| Next track | `⌘ →` |
| Previous | `⌘ ←` |
| Add files | `⌘ O` |

## Features

- Drag & drop MP3/FLAC files directly onto the window
- NavigationSplitView — sidebar albums + track list
- Album header with cover art, artist, track count
- Now playing bar (bottom left) + transport controls (bottom right)
- Lock screen / TouchBar / Control Center integration
- Background audio playback
