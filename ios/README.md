# SophaxPlay — iOS

SwiftUI music player for iPhone. Plays MP3 and FLAC. Minimal black-and-white design.

## Setup in Xcode

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**, set:
   - Product Name: `SophaxPlay`
   - Bundle Identifier: `com.sophax.sophaxplay`
   - Interface: **SwiftUI**
   - Language: **Swift**
3. Save the project inside this `ios/` folder
4. In Xcode, delete the generated `ContentView.swift` and `SophaxPlayApp.swift`
5. Drag all `.swift` files from `ios/SophaxPlay/` into the Xcode project (check **Copy if needed**)
6. Replace the generated `Info.plist` content with the one from this folder
7. In **Signing & Capabilities**, add your Apple Developer account
8. Run on device or simulator (⌘R)

## Features

- Import MP3 / FLAC files from Files app, AirDrop, or any source
- Background playback with lock screen controls
- Album art display
- Seek bar, volume control
- Full-screen now playing view (tap mini player)
- Same minimal SophaxPay-inspired design as the Mac app
