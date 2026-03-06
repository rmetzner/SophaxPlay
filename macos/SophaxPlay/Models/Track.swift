import Foundation
import AppKit

struct Track: Identifiable, Equatable, Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artwork: NSImage?

    static func == (lhs: Track, rhs: Track) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Album: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let artist: String
    var tracks: [Track]
    var artwork: NSImage? { tracks.first(where: { $0.artwork != nil })?.artwork }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Album, rhs: Album) -> Bool { lhs.id == rhs.id }
}

extension TimeInterval {
    var mmss: String {
        guard self > 0, !self.isNaN else { return "0:00" }
        let m = Int(self) / 60
        let s = Int(self) % 60
        return String(format: "%d:%02d", m, s)
    }
}
