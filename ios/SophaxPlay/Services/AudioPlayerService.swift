import AVFoundation
import MediaPlayer
import Combine

final class AudioPlayerService: NSObject, ObservableObject {

    // MARK: - Published state
    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var progress: Double = 0        // 0…1
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    // MARK: - Private
    private var player: AVAudioPlayer?
    private var timer: Timer?

    override init() {
        super.init()
        configureSession()
    }

    // MARK: - Public API

    func play(track: Track) {
        stop()
        guard let player = try? AVAudioPlayer(contentsOf: track.url) else { return }
        self.player = player
        player.delegate = self
        player.prepareToPlay()
        player.play()

        currentTrack = track
        duration = player.duration
        isPlaying = true
        startTimer()
        updateNowPlaying(track: track)
    }

    func togglePlayPause() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            timer?.invalidate()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
        updateNowPlayingState()
    }

    func stop() {
        player?.stop()
        player = nil
        timer?.invalidate()
        isPlaying = false
        progress = 0
        currentTime = 0
        duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func seek(to fraction: Double) {
        guard let player else { return }
        player.currentTime = player.duration * fraction
        currentTime = player.currentTime
        progress = fraction
    }

    // MARK: - Private helpers

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget   { [weak self] _ in self?.togglePlayPause(); return .success }
        center.pauseCommand.addTarget  { [weak self] _ in self?.togglePlayPause(); return .success }
        center.nextTrackCommand.addTarget  { _ in .noSuchContent }
        center.previousTrackCommand.addTarget { _ in .noSuchContent }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
            self.duration = player.duration
            self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
        }
    }

    private func updateNowPlaying(track: Track) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:           track.title,
            MPMediaItemPropertyArtist:          track.artist,
            MPMediaItemPropertyAlbumTitle:      track.album,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
            MPMediaItemPropertyPlaybackDuration: track.duration,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
        ]
        if let art = track.artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                boundsSize: CGSize(width: 300, height: 300)
            ) { _ in art }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingState() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo,
              let player else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.progress = 0
            self.currentTime = 0
        }
    }
}

// MARK: - Time formatting
extension TimeInterval {
    var mmss: String {
        let m = Int(self) / 60
        let s = Int(self) % 60
        return String(format: "%d:%02d", m, s)
    }
}
