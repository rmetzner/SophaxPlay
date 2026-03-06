import SwiftUI

@main
struct SophaxPlayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 480)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Playback") {
                Button("Play / Pause") {}
                    .keyboardShortcut(" ", modifiers: [])
                Divider()
                Button("Next Track")     {}.keyboardShortcut(.rightArrow, modifiers: .command)
                Button("Previous Track") {}.keyboardShortcut(.leftArrow,  modifiers: .command)
            }
        }
    }
}
