import Foundation
import AVFoundation
import AppKit

final class LibraryService: ObservableObject {
    @Published var albums: [Album] = []

    func addFiles(_ urls: [URL]) {
        for url in urls {
            _ = url.startAccessingSecurityScopedResource()
            loadFile(at: url)
        }
        sortAlbums()
    }

    private func loadFile(at url: URL) {
        let asset = AVURLAsset(url: url)
        let meta  = asset.commonMetadata

        func str(_ id: AVMetadataIdentifier) -> String? {
            AVMetadataItem.metadataItems(from: meta, filteredByIdentifier: id)
                .first.flatMap { try? $0.value?.copy() as? String }
        }

        let stem   = url.deletingPathExtension().lastPathComponent
        let folder = url.deletingLastPathComponent().lastPathComponent
        let title  = str(.commonIdentifierTitle)    ?? stem
        let artist = str(.commonIdentifierArtist)   ?? "Unknown Artist"
        let album  = str(.commonIdentifierAlbumName) ?? folder
        let dur    = CMTimeGetSeconds(asset.duration)

        var artwork: NSImage?
        if let data = AVMetadataItem.metadataItems(
            from: meta, filteredByIdentifier: .commonIdentifierArtwork
        ).first.flatMap({ try? $0.value?.copy() as? Data }) {
            artwork = NSImage(data: data)
        }

        let track = Track(url: url, title: title, artist: artist,
                          album: album, duration: dur, artwork: artwork)

        if let idx = albums.firstIndex(where: { $0.name == album }) {
            if !albums[idx].tracks.contains(track) {
                albums[idx].tracks.append(track)
            }
        } else {
            albums.append(Album(name: album, artist: artist, tracks: [track]))
        }
    }

    private func sortAlbums() {
        albums.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}
