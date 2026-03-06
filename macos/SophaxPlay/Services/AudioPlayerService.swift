import AVFoundation
import MediaPlayer
import Combine

final class AudioPlayerService: NSObject, ObservableObject {

    @Published var currentTrack: Track?
    @Published var queue: [Track] = []
    @Published var isPlaying = false
    @Published var isPaused  = false
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.75

    private var player: AVAudioPlayer?
    private var timer: Timer?

    override init() {
        super.init()
        setupRemoteCommands()
    }

    // MARK: - Public

    func play(track: Track, queue: [Track] = []) {
        stop()
        guard let p = try? AVAudioPlayer(contentsOf: track.url) else { return }
        self.queue   = queue
        player       = p
        p.delegate   = self
        p.volume     = volume
        p.prepareToPlay()
        p.play()
        currentTrack = track
        duration     = p.duration
        isPlaying    = true
        isPaused     = false
        startTimer()
        updateNowPlaying()
    }

    func togglePause() {
        guard let p = player else { return }
        if p.isPlaying {
            p.pause(); isPlaying = false; isPaused = true
        } else {
            p.play();  isPlaying = true;  isPaused = false
        }
        updateNowPlaying()
    }

    func stop() {
        player?.stop(); player = nil
        timer?.invalidate(); timer = nil
        isPlaying = false; isPaused = false
        progress = 0; currentTime = 0; duration = 0
    }

    func next() {
        guard let cur = currentTrack,
              let idx = queue.firstIndex(of: cur),
              idx + 1 < queue.count else { return }
        play(track: queue[idx + 1], queue: queue)
    }

    func previous() {
        guard let cur = currentTrack,
              let idx = queue.firstIndex(of: cur) else { return }
        if currentTime > 3 { seek(to: 0); return }
        if idx > 0 { play(track: queue[idx - 1], queue: queue) }
    }

    func seek(to fraction: Double) {
        guard let p = player else { return }
        p.currentTime = p.duration * fraction
        currentTime   = p.currentTime
        progress      = fraction
    }

    func setVolume(_ v: Float) {
        volume = v
        player?.volume = v
    }

    // MARK: - Private

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let p = self.player, p.isPlaying else { return }
            self.currentTime = p.currentTime
            self.duration    = p.duration
            self.progress    = p.duration > 0 ? p.currentTime / p.duration : 0
            self.updateNowPlayingTime()
        }
    }

    private func setupRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget    { [weak self] _ in self?.togglePause(); return .success }
        c.pauseCommand.addTarget   { [weak self] _ in self?.togglePause(); return .success }
        c.nextTrackCommand.addTarget    { [weak self] _ in self?.next();     return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
        c.changePlaybackPositionCommand.addTarget { [weak self] e in
            if let e = e as? MPChangePlaybackPositionCommandEvent {
                self?.seekTo(seconds: e.positionTime)
            }
            return .success
        }
    }

    private func seekTo(seconds: TimeInterval) {
        guard let p = player else { return }
        p.currentTime = seconds
        currentTime   = seconds
        progress      = p.duration > 0 ? seconds / p.duration : 0
    }

    private func updateNowPlaying() {
        guard let t = currentTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:            t.title,
            MPMediaItemPropertyArtist:           t.artist,
            MPMediaItemPropertyAlbumTitle:       t.album,
            MPMediaItemPropertyPlaybackDuration: t.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let art = t.artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                boundsSize: CGSize(width: 300, height: 300)) { _ in art }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingTime() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.next() }
    }
}
