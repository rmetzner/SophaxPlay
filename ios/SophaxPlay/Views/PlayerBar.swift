import SwiftUI

struct PlayerBar: View {
    @ObservedObject var player: AudioPlayerService
    @Binding var showFullPlayer: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Progress line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(hex: "e8e8e8")).frame(height: 2)
                    Rectangle().fill(Color.black)
                        .frame(width: geo.size.width * player.progress, height: 2)
                }
            }
            .frame(height: 2)

            HStack(spacing: 16) {
                // Artwork thumbnail
                Group {
                    if let art = player.currentTrack?.artwork {
                        Image(uiImage: art)
                            .resizable().scaledToFill()
                    } else {
                        Color(hex: "f5f5f5")
                            .overlay(Text("♪").font(.system(size: 18)).foregroundColor(Color(hex: "c0c0c0")))
                    }
                }
                .frame(width: 44, height: 44)
                .clipped()

                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentTrack?.title ?? "Not playing")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    Text(player.currentTrack?.artist ?? "—")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "888888"))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Controls
                HStack(spacing: 20) {
                    Button(action: { player.togglePlayPause() }) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "e8e8e8")), alignment: .top)
        .onTapGesture { showFullPlayer = true }
    }
}
