import Foundation
import Combine

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var sources: [MediaSource] = []
    @Published var message: String?
    @Published private(set) var importing = false
    private let fileURL: URL
    private var recoveryRequired = false

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.applicationSupportDirectory
            .appendingPathComponent("AutoPulse TV", isDirectory: true).appendingPathComponent("library.json")
        load()
    }
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let backup = try JSONDecoder().decode(LibraryBackup.self, from: Data(contentsOf: fileURL))
            guard backup.version == 1 else { throw MediaError.corruptLibrary }
            sources = backup.sources
        } catch {
            recoveryRequired = true
            message = MediaError.corruptLibrary.localizedDescription
        }
    }
    private func commit(_ changed: [MediaSource]) throws {
        guard !recoveryRequired else { throw MediaError.corruptLibrary }
        let data = try JSONEncoder().encode(LibraryBackup(sources: changed))
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        sources = changed
    }
    #if DEBUG
    func addPreviewSource(_ source: MediaSource) throws { try commit(sources + [source]) }
    #endif
    @discardableResult
    func add(title: String, address: String) throws -> MediaSource {
        let url = try SourceValidation.secureURL(address)
        if let existing = sources.first(where: { $0.url == url }) { return existing }
        guard sources.count < M3UParser.entryLimit else { throw MediaError.playlistTooLarge }
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = MediaSource(title: clean.isEmpty ? url.lastPathComponent : clean, url: url)
        try commit(sources + [source])
        return source
    }
    func update(_ source: MediaSource) {
        guard let index = sources.firstIndex(where: { $0.id == source.id }) else { return }
        var changed = sources
        changed[index] = source
        do { try commit(changed) } catch { message = error.localizedDescription }
    }
    func remove(_ source: MediaSource) {
        do {
            try commit(sources.filter { $0.id != source.id })
            if source.isLocal {
                try? FileManager.default.removeItem(at: source.resolvedURL)
                if source.photoMovieFileName != nil { try? FileManager.default.removeItem(at: source.playbackURL) }
            }
            if let id = source.providerID, !sources.contains(where: { $0.providerID == id }) { try? AccountVault.remove(id) }
        }
        catch { message = error.localizedDescription }
    }
    func favorite(_ source: MediaSource) {
        var changed = source
        changed.isFavorite.toggle()
        update(changed)
    }
    func recordPlayback(_ id: UUID, seconds: Double) {
        guard var source = sources.first(where: { $0.id == id }) else { return }
        source.lastPlayed = Date()
        source.resumeTime = seconds.isFinite ? max(seconds, 0) : 0
        update(source)
    }
    func importText(_ text: String, baseURL: URL? = nil) throws -> Int {
        try merge(M3UParser.parse(text, baseURL: baseURL))
    }
    private func merge(_ incoming: [MediaSource]) throws -> Int {
        var urls = Set(sources.map { $0.url.absoluteString })
        let unique = incoming.filter { urls.insert($0.url.absoluteString).inserted }
        guard sources.count + unique.count <= M3UParser.entryLimit else { throw MediaError.playlistTooLarge }
        try commit(sources + unique)
        return unique.count
    }
    func importRemote(_ address: String) async throws -> Int {
        guard !importing else { return 0 }
        let url = try SourceValidation.secureURL(address)
        importing = true
        defer { importing = false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let finalURL = response.url, finalURL.scheme?.lowercased() == "https" else { throw MediaError.badResponse }
        if response.expectedContentLength > Int64(M3UParser.byteLimit) { throw MediaError.playlistTooLarge }
        var data = Data()
        for try await byte in bytes {
            guard data.count < M3UParser.byteLimit else { throw MediaError.playlistTooLarge }
            data.append(byte)
        }
        guard let text = String(data: data, encoding: .utf8) else { throw MediaError.emptyPlaylist }
        try Task.checkCancellation()
        return try importText(text, baseURL: finalURL)
    }
    func importFile(_ url: URL) throws -> Int {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: M3UParser.byteLimit + 1) ?? Data()
        guard data.count <= M3UParser.byteLimit else { throw MediaError.playlistTooLarge }
        if url.pathExtension.lowercased() == "json" {
            let backup = try JSONDecoder().decode(LibraryBackup.self, from: data)
            guard backup.version == 1 else { throw MediaError.corruptLibrary }
            let validated = try backup.sources.map { source -> MediaSource in
                _ = try SourceValidation.secureURL(source.url.absoluteString)
                var copy = source
                copy.id = UUID()
                copy.kind = .video
                copy.localFileName = nil
                copy.photoMovieFileName = nil
                copy.providerID = nil
                copy.providerStreamPath = nil
                copy.resumeTime = source.resumeTime.isFinite ? min(max(source.resumeTime, 0), 31_536_000) : 0
                return copy
            }
            return try merge(validated)
        }
        guard let text = String(data: data, encoding: .utf8) else { throw MediaError.emptyPlaylist }
        return try importText(text)
    }
    func importMedia(_ url: URL, title: String? = nil) async throws {
        guard sources.count < M3UParser.entryLimit else { throw MediaError.playlistTooLarge }
        let source = try await MediaImporter.shared.copy(url, title: title)
        do {
            guard sources.count < M3UParser.entryLimit else { throw MediaError.playlistTooLarge }
            try commit(sources + [source])
        } catch {
            try? FileManager.default.removeItem(at: source.resolvedURL)
            if source.photoMovieFileName != nil { try? FileManager.default.removeItem(at: source.playbackURL) }
            throw error
        }
    }
    func exportData() throws -> Data {
        // Local media is copied separately by the user; a JSON backup must not
        // contain sandbox-specific paths that break after restore/reinstall.
        try JSONEncoder().encode(LibraryBackup(sources: sources.filter { !$0.isLocal && $0.providerID == nil }))
    }

    func importXtream(_ account: XtreamAccount) async throws -> Int {
        guard !importing else { throw MediaError.badResponse }
        importing = true
        defer { importing = false }
        var request = URLRequest(url: account.playlistURL)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
            response.url?.scheme == "https", response.expectedContentLength <= Int64(M3UParser.byteLimit) else { throw MediaError.badResponse }
        var data = Data()
        for try await byte in bytes {
            guard data.count < M3UParser.byteLimit else { throw MediaError.playlistTooLarge }
            data.append(byte)
        }
        guard let text = String(data: data, encoding: .utf8) else { throw MediaError.emptyPlaylist }
        let sanitized = try M3UParser.parse(text).compactMap { account.sanitize($0) }
        guard !sanitized.isEmpty else { throw MediaError.emptyPlaylist }
        try Task.checkCancellation()
        let previous = AccountVault.read(account.id)
        try AccountVault.save(account)
        do { return try merge(sanitized) }
        catch {
            if let previous { try? AccountVault.save(previous) }
            else { try? AccountVault.remove(account.id) }
            throw error
        }
    }
    func removeXtreamAccounts() throws {
        let ids = Set(sources.compactMap(\.providerID))
        // Delete the credential first: a storage failure leaves an entry that
        // asks to reconnect, rather than an account with no removal control.
        for id in ids { try AccountVault.remove(id) }
        try commit(sources.filter { $0.providerID == nil })
    }
}
