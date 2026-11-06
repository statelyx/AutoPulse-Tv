import XCTest
import UIKit
import AVFoundation
@testable import AutoPulseTV

final class MediaTests: XCTestCase {
    func testVersionOneSourcesRemainReadable() throws {
        let json = #"{"id":"7CF58B77-BA47-4603-BA40-13D831143750","title":"Existing video","url":"https://example.com/video.mp4","group":"Old group","isFavorite":true,"resumeTime":12}"#
        let source = try JSONDecoder().decode(MediaSource.self, from: Data(json.utf8))
        XCTAssertEqual(source.mediaKind, .video)
        XCTAssertEqual(source.resolvedURL, source.url)
        XCTAssertFalse(source.isLocal)
    }
    func testXtreamCredentialsAreRemovedFromPersistedSources() throws {
        let account = XtreamAccount(server: URL(string: "https://provider.example")!, username: "my-user", password: "private-password")
        let source = MediaSource(title: "My stream", url: URL(string: "https://provider.example/live/my-user/private-password/42.m3u8")!)
        let clean = try XCTUnwrap(account.sanitize(source))
        let encoded = String(decoding: try JSONEncoder().encode(clean), as: UTF8.self)
        XCTAssertFalse(encoded.contains("private-password"))
        XCTAssertFalse(encoded.contains("my-user"))
        XCTAssertEqual(account.streamURL(try XCTUnwrap(clean.providerStreamPath)), source.url)
        XCTAssertNil(account.sanitize(MediaSource(title: "Other origin", url: URL(string: "https://other.example/live/my-user/private-password/42.m3u8")!)))
        XCTAssertNil(account.streamURL(["live", "../42.m3u8"]))
    }
    func testLiveAndCompletedPlaybackNeverSeekToOldPosition() {
        XCTAssertNil(PlaybackPositionPolicy.resumeTarget(saved: 100, duration: .infinity))
        XCTAssertNil(PlaybackPositionPolicy.resumeTarget(saved: .nan, duration: 60))
        XCTAssertEqual(PlaybackPositionPolicy.resumeTarget(saved: 100, duration: 60), 59)
        XCTAssertEqual(PlaybackPositionPolicy.savedPosition(current: 59, duration: 60), 0)
        XCTAssertEqual(PlaybackPositionPolicy.savedPosition(current: 20, duration: 60), 20)
        XCTAssertEqual(PlaybackPositionPolicy.savedPosition(current: 20, duration: .nan), 0)
    }
    func testQuotedCommaRelativeURLAndDeduplication() throws {
        let sources = try M3UParser.parse("""
        #EXTM3U
        #EXTINF:-1 group-title="Talks, Live",First, title
        media/a.m3u8
        #EXTINF:-1,Duplicate
        media/a.m3u8
        #EXTINF:-1,Insecure
        http://example.com/b.mp4
        """, baseURL: URL(string: "https://example.com/list.m3u"))
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources[0].title, "First, title")
        XCTAssertEqual(sources[0].group, "Talks, Live")
        XCTAssertEqual(sources[0].url.absoluteString, "https://example.com/media/a.m3u8")
    }
    func testHLSIsNotExpandedIntoSegments() throws {
        let url = URL(string: "https://example.com/master.m3u8")!
        let sources = try M3UParser.parse("#EXTM3U\n#EXT-X-TARGETDURATION:10\nsegment.ts", baseURL: url)
        XCTAssertEqual(sources.map(\.url), [url])
        XCTAssertThrowsError(try M3UParser.parse("#EXTM3U\n#EXT-X-TARGETDURATION:10"))
    }
    func testUnsafeAndEmptyInputsAreRejected() {
        for text in ["http://example.com", "javascript:alert(1)", "https://user:pass@example.com", ""] {
            XCTAssertThrowsError(try SourceValidation.secureURL(text))
        }
        XCTAssertThrowsError(try M3UParser.parse("#EXTM3U\n# No sources"))
        XCTAssertThrowsError(try M3UParser.parse(String(repeating: "a", count: M3UParser.byteLimit + 1)))
    }
}

@MainActor
final class LibraryStoreTests: XCTestCase {
    func testPhotoImportCreatesPlayablePresentationAndPrivateBackup() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 80)).image { renderer in
            UIColor.orange.setFill(); renderer.fill(CGRect(x: 0, y: 0, width: 120, height: 80))
        }
        let original = directory.appendingPathComponent("photo.jpg")
        try XCTUnwrap(image.jpegData(compressionQuality: 0.9)).write(to: original)
        let store = LibraryStore(fileURL: directory.appendingPathComponent("library.json"))
        try await store.importMedia(original, title: "Test photo")
        let photo = try XCTUnwrap(store.sources.first)
        defer { store.remove(photo) }
        XCTAssertEqual(photo.mediaKind, .photo)
        XCTAssertTrue(FileManager.default.fileExists(atPath: photo.resolvedURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: photo.playbackURL.path))
        let asset = AVURLAsset(url: photo.playbackURL)
        let playable = try await asset.load(.isPlayable)
        let duration = try await asset.load(.duration)
        XCTAssertTrue(playable)
        XCTAssertEqual(duration.seconds, 10, accuracy: 0.3)
        let backup = try JSONDecoder().decode(LibraryBackup.self, from: store.exportData())
        XCTAssertTrue(backup.sources.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
        let restored = LibraryStore(fileURL: directory.appendingPathComponent("library.json"))
        XCTAssertEqual(restored.sources.first?.resolvedURL, photo.resolvedURL)
    }
    func testRemoteRestoreCannotInjectLocalFileReferences() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var remote = MediaSource(title: "Remote", url: URL(string: "https://example.com/a.mp4")!)
        remote.localFileName = "other-photo.jpg"
        remote.photoMovieFileName = "other-video.mp4"
        remote.kind = .photo
        remote.providerID = "other-account"
        let backup = directory.appendingPathComponent("backup.json")
        try JSONEncoder().encode(LibraryBackup(sources: [remote])).write(to: backup)
        let store = LibraryStore(fileURL: directory.appendingPathComponent("library.json"))
        XCTAssertEqual(try store.importFile(backup), 1)
        XCTAssertFalse(try XCTUnwrap(store.sources.first).isLocal)
        XCTAssertNil(store.sources.first?.providerID)
        XCTAssertEqual(store.sources.first?.mediaKind, .video)
    }
    func testPersistenceDeduplicationAndResume() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("library.json")
        let store = LibraryStore(fileURL: file)
        let source = try store.add(title: "A", address: "https://example.com/a.mp4")
        _ = try store.add(title: "Duplicate", address: source.url.absoluteString)
        store.favorite(source)
        store.recordPlayback(source.id, seconds: 42)
        let restored = LibraryStore(fileURL: file)
        XCTAssertEqual(restored.sources.count, 1)
        XCTAssertEqual(restored.sources[0].resumeTime, 42)
        XCTAssertTrue(restored.sources[0].isFavorite)
        restored.remove(restored.sources[0])
        XCTAssertTrue(LibraryStore(fileURL: file).sources.isEmpty)
    }
    func testCorruptStorageIsNotOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("library.json")
        let original = Data("corrupt".utf8)
        try original.write(to: file)
        let store = LibraryStore(fileURL: file)
        XCTAssertThrowsError(try store.add(title: "A", address: "https://example.com/a.mp4"))
        XCTAssertEqual(try Data(contentsOf: file), original)
    }
}
