import Foundation
import AVFoundation
import UIKit
import UniformTypeIdentifiers

final class LibraryService: ObservableObject {
    @Published var albums: [Album] = []

    // MARK: - Import files from document picker

    func importFiles(urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            // Copy to app's Documents so we can read later
            let dest = documentsURL.appendingPathComponent(url.lastPathComponent)
            if !FileManager.default.fileExists(atPath: dest.path) {
                try? FileManager.default.copyItem(at: url, to: dest)
            }
            loadFile(at: dest)
        }
        sortAlbums()
    }

    // MARK: - Private

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func loadFile(at url: URL) {
        let asset = AVURLAsset(url: url)
        let meta  = asset.commonMetadata

        func stringValue(_ id: AVMetadataIdentifier) -> String? {
            AVMetadataItem.metadataItems(from: meta, filteredByIdentifier: id).first
                .flatMap { try? $0.value?.copy() as? String }
        }

        let stem    = url.deletingPathExtension().lastPathComponent
        let folder  = url.deletingLastPathComponent().lastPathComponent
        let title   = stringValue(.commonIdentifierTitle)   ?? stem
        let artist  = stringValue(.commonIdentifierArtist)  ?? "Unknown Artist"
        let album   = stringValue(.commonIdentifierAlbumName) ?? folder
        let dur     = CMTimeGetSeconds(asset.duration)

        var artwork: UIImage?
        if let data = AVMetadataItem.metadataItems(from: meta, filteredByIdentifier: .commonIdentifierArtwork)
            .first.flatMap({ try? $0.value?.copy() as? Data }) {
            artwork = UIImage(data: data)
        }

        let track = Track(url: url, title: title, artist: artist,
                          album: album, duration: dur, artwork: artwork)

        if let idx = albums.firstIndex(where: { $0.name == album }) {
            albums[idx].tracks.append(track)
        } else {
            albums.append(Album(name: album, artist: artist, tracks: [track]))
        }
    }

    private func sortAlbums() {
        albums.sort { $0.name < $1.name }
        for i in albums.indices {
            albums[i].tracks.sort { $0.title < $1.title }
        }
    }
}
