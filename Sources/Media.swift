import Foundation

struct MediaSource: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var url: URL
    var group: String = "Kütüphanem"
    var isFavorite: Bool = false
    var lastPlayed: Date?
    var resumeTime: Double = 0
}

enum SourceValidation {
    static func secureURL(_ text: String) throws -> URL {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { throw MediaError.invalidURL }
        return url
    }
}

enum MediaError: LocalizedError {
    case invalidURL, emptyPlaylist, playlistTooLarge, badResponse, corruptLibrary
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçerli bir HTTPS adresi gir. Adreste kullanıcı adı veya parola bulunmamalı."
        case .emptyPlaylist: return "Listede desteklenen HTTPS video kaynağı bulunamadı."
        case .playlistTooLarge: return "Liste sınırı aşıldı: en fazla 2 MB ve 2.000 kaynak."
        case .badResponse: return "Sunucu listeyi gönderemedi. Adresi ve erişim hakkını kontrol et."
        case .corruptLibrary: return "Kütüphane okunamadı. Verilerin korundu; dosya düzeltilene kadar değişiklik kaydedilmeyecek."
        }
    }
}

enum M3UParser {
    static let byteLimit = 2_000_000
    static let entryLimit = 2_000
    static func parse(_ text: String, baseURL: URL? = nil) throws -> [MediaSource] {
        guard text.utf8.count <= byteLimit else { throw MediaError.playlistTooLarge }
        var title: String?
        var group = "İçe aktarılanlar"
        var seen = Set<String>()
        var result: [MediaSource] = []
        // HLS segment manifests are playable media, not lists of channels.
        if text.contains("#EXT-X-") {
            guard let baseURL, (try? SourceValidation.secureURL(baseURL.absoluteString)) != nil else {
                throw MediaError.emptyPlaylist
            }
            return [MediaSource(title: baseURL.deletingPathExtension().lastPathComponent, url: baseURL)]
        }
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\u{FEFF}", with: "")
            guard !line.isEmpty else { continue }
            if line.hasPrefix("#EXTINF:") {
                var quoted = false
                var separator: String.Index?
                for index in line.indices {
                    if line[index] == "\"" { quoted.toggle() }
                    if line[index] == "," && !quoted { separator = index; break }
                }
                title = separator.map { String(line[line.index(after: $0)...]).trimmingCharacters(in: .whitespaces) }
                if let range = line.range(of: "group-title=\""),
                   let end = line[range.upperBound...].firstIndex(of: "\"") {
                    group = String(line[range.upperBound..<end])
                } else { group = "İçe aktarılanlar" }
                continue
            }
            guard !line.hasPrefix("#") else { continue }
            defer { title = nil; group = "İçe aktarılanlar" }
            guard let resolved = URL(string: line, relativeTo: baseURL)?.absoluteURL,
                  let url = try? SourceValidation.secureURL(resolved.absoluteString),
                  seen.insert(url.absoluteString).inserted else { continue }
            guard result.count < entryLimit else { throw MediaError.playlistTooLarge }
            result.append(MediaSource(title: title.flatMap { $0.isEmpty ? nil : $0 } ?? url.lastPathComponent,
                                      url: url, group: group))
        }
        guard !result.isEmpty else { throw MediaError.emptyPlaylist }
        return result
    }
}

struct LibraryBackup: Codable {
    var version: Int = 1
    var sources: [MediaSource]
}
