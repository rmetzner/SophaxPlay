import SwiftUI

struct PlayerToolbar: View {
    @ObservedObject var player: AudioPlayerService

    var body: some View {
        VStack(spacing: 0) {
            // Seek bar
            SeekBar(progress: player.progress, onSeek: { player.seek(to: $0) })
                .frame(height: 3)

            HStack(spacing: 0) {
                // Time
                Text(player.currentTime.mmss)
                    .font(.system(size: 11).monospaced())
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                    .padding(.leading, 20)

                Spacer()

                // Transport controls (centered)
                HStack(spacing: 6) {
                    TransportButton(icon: "backward.fill", size: 14) { player.previous() }

                    // Play/pause — main button
                    Button(action: {
                        if player.currentTrack != nil { player.togglePause() }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.primary)
                                .frame(width: 80, height: 30)
                            HStack(spacing: 6) {
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text(player.isPlaying ? "PAUSE" : "PLAY")
                                    .font(.system(size: 10, weight: .bold).monospaced())
                                    .kerning(1)
                            }
                            .foregroundColor(Color(nsColor: .windowBackgroundColor))
                        }
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(" ", modifiers: [])

                    TransportButton(icon: "forward.fill", size: 14) { player.next() }
                }

                Spacer()

                // Volume + duration
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))

                    Slider(value: Binding(
                        get: { Double(player.volume) },
                        set: { player.setVolume(Float($0)) }
                    ), in: 0...1)
                    .frame(width: 80)

                    Text(player.duration.mmss)
                        .font(.system(size: 11).monospaced())
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                        .padding(.trailing, 20)
                }
            }
            .frame(height: 47)
        }
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color(nsColor: .separatorColor)), alignment: .top)
    }
}

// MARK: - Now playing info bar (below seek bar)

struct NowPlayingBar: View {
    @ObservedObject var player: AudioPlayerService

    var body: some View {
        HStack(spacing: 12) {
            // Artwork thumbnail
            Group {
                if let art = player.currentTrack?.artwork {
                    Image(nsImage: art).resizable().scaledToFill()
                } else {
                    Color(nsColor: .separatorColor)
                        .overlay(Image(systemName: "music.note").font(.system(size: 10)).foregroundColor(.secondary))
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 3))

            VStack(alignment: .leading, spacing: 1) {
                Text(player.currentTrack?.title ?? "—")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(player.currentTrack.map { "\($0.artist)  ·  \($0.album)" } ?? "No track selected")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .frame(maxWidth: 320, alignment: .leading)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color(nsColor: .separatorColor)), alignment: .top)
    }
}

// MARK: - Seek bar

private struct SeekBar: View {
    let progress: Double
    let onSeek: (Double) -> Void
    @State private var hovering = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                onSeek(max(0, min(1, v.location.x / geo.size.width)))
            })
            .onHover { hovering = $0 }
            .frame(height: hovering ? 4 : 3)
            .animation(.easeInOut(duration: 0.1), value: hovering)
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Transport button

private struct TransportButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 36, height: 30)
        }
        .buttonStyle(.plain)
    }
}
