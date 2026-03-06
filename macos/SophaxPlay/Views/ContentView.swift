import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var player  = AudioPlayerService()
    @StateObject private var library = LibraryService()
    @State private var selectedAlbum: Album?
    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                SidebarView(
                    library: library,
                    player:  player,
                    selectedAlbum: $selectedAlbum,
                    onAddFiles: { showFilePicker = true }
                )
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            } detail: {
                if let album = selectedAlbum {
                    TrackListView(album: album, player: player)
                } else {
                    emptyState
                }
            }

            // Bottom player bar
            HStack(spacing: 0) {
                NowPlayingBar(player: player)
                PlayerToolbar(player: player)
                    .frame(maxWidth: .infinity)
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.audio, .mp3,
                UTType(filenameExtension: "flac") ?? .audio],
            allowsMultipleSelection: true
        ) { result in
            if let urls = try? result.get() {
                library.addFiles(urls)
                if selectedAlbum == nil { selectedAlbum = library.albums.first }
            }
        }
        // Drag & drop onto the window
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            var urls: [URL] = []
            let group = DispatchGroup()
            for p in providers {
                group.enter()
                _ = p.loadObject(ofClass: URL.self) { url, _ in
                    if let url { urls.append(url) }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                let audio = urls.filter { ["mp3","flac","m4a","aac","wav","aiff"].contains($0.pathExtension.lowercased()) }
                library.addFiles(audio)
                if selectedAlbum == nil { selectedAlbum = library.albums.first }
            }
            return true
        }
        // Keyboard shortcuts
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            Text("No music yet")
                .font(.system(size: 18, weight: .semibold))
            Text("Click \"+\" in the sidebar or drag audio files here")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
