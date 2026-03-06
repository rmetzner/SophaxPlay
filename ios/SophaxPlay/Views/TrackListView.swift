import SwiftUI

struct TrackListView: View {
    let album: Album
    @ObservedObject var player: AudioPlayerService

    var body: some View {
        List {
            // Album header
            HStack(spacing: 20) {
                Group {
                    if let art = album.artwork {
                        Image(uiImage: art)
                            .resizable().scaledToFill()
                    } else {
                        Color(hex: "f5f5f5")
                            .overlay(Text("♪").font(.system(size: 28)).foregroundColor(Color(hex: "c0c0c0")))
                    }
                }
                .frame(width: 100, height: 100)
                .clipped()

                VStack(alignment: .leading, spacing: 6) {
                    Text(album.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Text(album.artist)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "888888"))
                    Text("\(album.tracks.count) tracks")
                        .font(.system(size: 11).monospaced())
                        .foregroundColor(Color(hex: "c0c0c0"))
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            Divider().listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())

            // Tracks
            ForEach(Array(album.tracks.enumerated()), id: \.element.id) { i, track in
                TrackRow(index: i + 1, track: track,
                         isPlaying: player.currentTrack == track && player.isPlaying)
                    .contentShape(Rectangle())
                    .onTapGesture { player.play(track: track) }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(
                        player.currentTrack == track
                        ? Color.black
                        : Color.white
                    )
            }
        }
        .listStyle(.plain)
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TrackRow: View {
    let index: Int
    let track: Track
    let isPlaying: Bool

    var textColor: Color { isPlaying ? Color(hex: "f5f5f5") : .black }
    var mutedColor: Color { isPlaying ? Color(hex: "888888") : Color(hex: "c0c0c0") }

    var body: some View {
        HStack(spacing: 0) {
            Text(String(format: "%2d", index))
                .font(.system(size: 12).monospaced())
                .foregroundColor(mutedColor)
                .frame(width: 44, alignment: .center)

            Text(track.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(textColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(track.duration.mmss)
                .font(.system(size: 12).monospaced())
                .foregroundColor(mutedColor)
                .padding(.trailing, 20)
        }
        .frame(height: 56)
    }
}
