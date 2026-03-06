import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var player  = AudioPlayerService()
    @StateObject private var library = LibraryService()

    @State private var showFilePicker  = false
    @State private var showFullPlayer  = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                albumList

                // Mini player bar (sticks to bottom)
                if player.currentTrack != nil {
                    VStack(spacing: 0) {
                        PlayerBar(player: player, showFullPlayer: $showFullPlayer)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("")
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPicker(types: [.audio]) { urls in
                library.importFiles(urls: urls)
            }
        }
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView(player: player, isPresented: $showFullPlayer)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .animation(.easeInOut(duration: 0.2), value: player.currentTrack != nil)
    }

    // MARK: - Album list

    private var albumList: some View {
        Group {
            if library.albums.isEmpty {
                emptyState
            } else {
                List(library.albums) { album in
                    NavigationLink(destination: TrackListView(album: album, player: player)) {
                        AlbumRow(album: album, number: (library.albums.firstIndex { $0.id == album.id } ?? 0) + 1)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(.plain)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: player.currentTrack != nil ? 72 : 0)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("♪")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "c0c0c0"))
            Text("No music yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            Text("Tap + to add MP3 or FLAC files")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "888888"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("SophaxPlay")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showFilePicker = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
    }
}

// MARK: - Album row

private struct AlbumRow: View {
    let album: Album
    let number: Int

    var body: some View {
        HStack(spacing: 14) {
            // Numbered circle (SophaxPay style)
            ZStack {
                Circle()
                    .stroke(Color(hex: "c0c0c0"), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.system(size: 11).monospaced())
                    .foregroundColor(Color(hex: "888888"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(album.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                Text("\(album.tracks.count) track\(album.tracks.count == 1 ? "" : "s")  ·  \(album.artist)")
                    .font(.system(size: 12).monospaced())
                    .foregroundColor(Color(hex: "888888"))
                    .lineLimit(1)
            }

            Spacer()

            if let art = album.artwork {
                Image(uiImage: art)
                    .resizable().scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipped()
            }
        }
        .padding(.vertical, 6)
    }
}
