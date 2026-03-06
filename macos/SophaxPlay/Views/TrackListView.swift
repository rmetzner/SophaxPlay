import SwiftUI

struct TrackListView: View {
    let album: Album
    @ObservedObject var player: AudioPlayerService

    var body: some View {
        VStack(spacing: 0) {
            albumHeader
            Divider()
            trackList
        }
    }

    // MARK: - Album header

    private var albumHeader: some View {
        HStack(spacing: 20) {
            artworkView
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(album.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Text(album.artist)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(album.tracks.count) tracks  ·  \(totalDuration)")
                    .font(.system(size: 11).monospaced())
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            }
            .padding(.vertical, 4)

            Spacer()

            // Play album button
            Button(action: playAlbum) {
                Label("Play", systemImage: "play.fill")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.primary)
        }
        .padding(24)
        .frame(height: 168)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var artworkView: some View {
        if let art = album.artwork {
            Image(nsImage: art).resizable().scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(nsColor: .separatorColor).opacity(0.3))
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 36))
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                )
        }
    }

    // MARK: - Track list

    private var trackList: some View {
        List(Array(album.tracks.enumerated()), id: \.element.id) { i, track in
            TrackRow(
                index:     i + 1,
                track:     track,
                isCurrent: player.currentTrack == track,
                isPlaying: player.currentTrack == track && player.isPlaying
            )
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { playFrom(index: i) }
            .onTapGesture(count: 1) { playFrom(index: i) }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Helpers

    private var totalDuration: String {
        let total = album.tracks.reduce(0) { $0 + $1.duration }
        let m = Int(total) / 60
        return "\(m) min"
    }

    private func playFrom(index: Int) {
        player.play(track: album.tracks[index], queue: album.tracks)
    }

    private func playAlbum() {
        guard !album.tracks.isEmpty else { return }
        player.play(track: album.tracks[0], queue: album.tracks)
    }
}

// MARK: - Track row

private struct TrackRow: View {
    let index: Int
    let track: Track
    let isCurrent: Bool
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Playing indicator / number
            ZStack {
                if isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else if isCurrent {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Text("\(index)")
                        .font(.system(size: 12).monospaced())
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                }
            }
            .frame(width: 48, alignment: .center)

            // Title + artist
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
                    .foregroundColor(isCurrent ? .accentColor : .primary)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Duration
            Text(track.duration.mmss)
                .font(.system(size: 12).monospaced())
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                .padding(.trailing, 20)
        }
        .frame(height: 52)
        .background(isCurrent ? Color.accentColor.opacity(0.06) : Color.clear)
    }
}
