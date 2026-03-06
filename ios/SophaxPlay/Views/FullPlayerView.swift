import SwiftUI

struct FullPlayerView: View {
    @ObservedObject var player: AudioPlayerService
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color(hex: "c0c0c0"))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            // Header
            HStack {
                Button(action: { isPresented = false }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
                Spacer()
                Text("NOW PLAYING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "888888"))
                    .kerning(2)
                Spacer()
                Color.clear.frame(width: 24)
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            Spacer()

            // Artwork
            Group {
                if let art = player.currentTrack?.artwork {
                    Image(uiImage: art)
                        .resizable().scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "f5f5f5"))
                        .overlay(
                            Text("♪")
                                .font(.system(size: 64))
                                .foregroundColor(Color(hex: "c0c0c0"))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 40)

            Spacer()

            // Track info
            VStack(spacing: 6) {
                Text(player.currentTrack?.title ?? "—")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Text(player.currentTrack?.artist ?? "—")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "888888"))
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 24)

            // Seek bar
            VStack(spacing: 6) {
                Slider(value: Binding(
                    get: { player.progress },
                    set: { player.seek(to: $0) }
                ))
                .accentColor(.black)

                HStack {
                    Text(player.currentTime.mmss)
                    Spacer()
                    Text(player.duration.mmss)
                }
                .font(.system(size: 11).monospacedDigit())
                .foregroundColor(Color(hex: "888888"))
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 32)

            // Transport controls
            HStack(spacing: 48) {
                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(Color(hex: "c0c0c0"))
                }

                Button(action: { player.togglePlayPause() }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black)
                            .frame(width: 72, height: 52)
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(Color(hex: "c0c0c0"))
                }
            }

            Spacer().frame(height: 20)

            // Volume
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "c0c0c0"))
                Slider(value: .constant(0.7))
                    .accentColor(.black)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "c0c0c0"))
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 40)
        }
        .background(Color.white)
    }
}
