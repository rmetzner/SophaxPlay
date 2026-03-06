import Foundation
import UIKit

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artwork: UIImage?

    static func == (lhs: Track, rhs: Track) -> Bool { lhs.id == rhs.id }
}

struct Album: Identifiable {
    let id = UUID()
    let name: String
    let artist: String
    var tracks: [Track]
    var artwork: UIImage? { tracks.first(where: { $0.artwork != nil })?.artwork }
}
