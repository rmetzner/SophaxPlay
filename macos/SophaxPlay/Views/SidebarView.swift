import SwiftUI

struct SidebarView: View {
    @ObservedObject var library: LibraryService
    @ObservedObject var player:  AudioPlayerService
    @Binding var selectedAlbum: Album?
    let onAddFiles: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header label
            HStack {
                Text("ALBUMS")
                    .font(.system(size: 9, weight: .bold).monospaced())
                    .foregroundColor(.secondary)
                    .kerning(2)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            // Album list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(library.albums.enumerated()), id: \.element.id) { i, album in
                        AlbumSidebarRow(
                            number: i + 1,
                            album: album,
                            isSelected: selectedAlbum?.id == album.id,
                            isPlaying: player.currentTrack.map { t in album.tracks.contains(t) } ?? false
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { selectedAlbum = album }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }

            Divider()

            // Add files button
            Button(action: onAddFiles) {
                Label("Add Files", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct AlbumSidebarRow: View {
    let number: Int
    let album: Album
    let isSelected: Bool
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Numbered circle
            ZStack {
                Circle()
                    .fill(isPlaying ? Color.primary : Color.clear)
                    .stroke(isPlaying ? Color.clear : Color(nsColor: .separatorColor), lineWidth: 1.5)
                    .frame(width: 26, height: 26)
                Text("\(number)")
                    .font(.system(size: 10, weight: .semibold).monospaced())
                    .foregroundColor(isPlaying ? Color(nsColor: .windowBackgroundColor) : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text("\(album.tracks.count) track\(album.tracks.count == 1 ? "" : "s")")
                    .font(.system(size: 11).monospaced())
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color.primary.opacity(0.08) : Color.clear)
        )
    }
}
