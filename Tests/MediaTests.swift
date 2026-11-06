import XCTest
@testable import Molaqo

final class MediaTests: XCTestCase {
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
