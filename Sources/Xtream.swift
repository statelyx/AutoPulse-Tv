import Foundation
import Security
import CryptoKit
import SwiftUI

struct XtreamAccount: Codable {
    let server: URL
    let username: String
    let password: String
    var id: String { SHA256.hash(data: Data((server.absoluteString + "\n" + username).utf8)).map { String(format: "%02x", $0) }.joined() }
    var playlistURL: URL {
        var parts = URLComponents(url: server.appendingPathComponent("get.php"), resolvingAgainstBaseURL: false)!
        parts.queryItems = [URLQueryItem(name: "username", value: username), URLQueryItem(name: "password", value: password),
            URLQueryItem(name: "type", value: "m3u_plus"), URLQueryItem(name: "output", value: "m3u8")]
        return parts.url!
    }
    func sanitize(_ source: MediaSource) -> MediaSource? {
        // Only native Xtream stream paths from the configured HTTPS origin are
        // retained. Credentials never enter library.json, exports or artwork.
        guard source.url.host == server.host, source.url.port == server.port,
              source.url.query == nil else { return nil }
        let path = source.url.pathComponents.filter { $0 != "/" }
        guard path.count == 4, ["live", "movie", "series"].contains(path[0]),
              path[1] == username, path[2] == password else { return nil }
        var result = source
        result.url = server.appendingPathComponent("autopulse-reference/\(id)/\(path[0])/\(path[3])")
        result.providerID = id
        result.providerStreamPath = [path[0], path[3]]
        return result
    }
    func streamURL(_ path: [String]) -> URL? {
        guard path.count == 2, ["live", "movie", "series"].contains(path[0]),
              !path[1].contains("/"), !path[1].isEmpty else { return nil }
        return [path[0], username, password, path[1]].reduce(server) { $0.appendingPathComponent($1) }
    }
}

enum AccountVault {
    private static let service = "com.statelyxx.autopulsetv.xtream"
    static func read(_ id: String) -> XtreamAccount? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
            kSecAttrAccount as String: id, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne] as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(XtreamAccount.self, from: data)
    }
    static func save(_ account: XtreamAccount) throws {
        let query = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account.id] as [String: Any]
        let data = try JSONEncoder().encode(account)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw MediaError.badResponse }
        } else if status != errSecSuccess { throw MediaError.badResponse }
    }
    static func remove(_ id: String) throws {
        let status = SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
            kSecAttrAccount as String: id] as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw MediaError.badResponse }
    }
}

struct XtreamScreen: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var server = "https://"
    @State private var username = ""
    @State private var password = ""
    @State private var busy = false
    @State private var status: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Kendi sağlayıcın") {
                    TextField("HTTPS sunucu adresi", text: $server).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Kullanıcı adı", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Parola", text: $password)
                }.disabled(busy)
                Section {
                    Button {
                        busy = true; status = nil
                        Task {
                            do {
                                let url = try SourceValidation.secureURL(server)
                                guard url.query == nil, url.fragment == nil, url.path.isEmpty || url.path == "/" else { throw MediaError.invalidURL }
                                let count = try await library.importXtream(XtreamAccount(server: url, username: username, password: password))
                                status = "\(count) yeni kaynak eklendi."
                                password = ""
                            } catch { status = "Bağlantı kurulamadı. Sunucu, hesap bilgileri ve liste boyutunu kontrol et." }
                            busy = false
                        }
                    } label: { if busy { ProgressView("Bağlanıyor…") } else { Text("Hesaptan içe aktar") } }
                        .disabled(busy || username.isEmpty || password.isEmpty)
                    if let status { Text(status).font(.footnote) }
                }
                Section {
                    Text("Hesap bilgileri yalnız bu cihazın Anahtar Zinciri’nde saklanır. HTTPS ve HLS (m3u8) sunan Xtream uyumlu sağlayıcı gerekir. En fazla 2.000 kaynak / 2 MB liste. Sağlayıcı hesabı veya içerik satılmaz.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("Xtream hesabı").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Bitti") { dismiss() }.disabled(busy) }.interactiveDismissDisabled(busy)
        }
    }
}
