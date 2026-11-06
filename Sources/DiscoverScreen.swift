import SwiftUI

struct WebShortcut: Identifiable, Codable {
    var id: String { address }
    let title: String
    let address: String
    let symbol: String
    static let defaults = [
        WebShortcut(title: "Google", address: "https://www.google.com", symbol: "magnifyingglass"),
        WebShortcut(title: "YouTube", address: "https://www.youtube.com", symbol: "play.rectangle.fill"),
        WebShortcut(title: "Vimeo", address: "https://vimeo.com", symbol: "video.fill"),
        WebShortcut(title: "Twitch", address: "https://www.twitch.tv", symbol: "bubble.left.and.bubble.right.fill"),
        WebShortcut(title: "Dailymotion", address: "https://www.dailymotion.com", symbol: "play.square.stack"),
        WebShortcut(title: "Wikipedia", address: "https://www.wikipedia.org", symbol: "book.fill")
    ]
}

struct DiscoverScreen: View {
    @State private var address = ""
    @State private var destination: WebDestination?
    @State private var error: String?
    @State private var custom: [WebShortcut] = []
    @State private var add = false
    @State private var title = ""
    @State private var bookmarkAddress = "https://"
    private var fileURL: URL { URL.applicationSupportDirectory.appendingPathComponent("AutoPulse TV/bookmarks.json") }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("UYGULAMA İÇİ TARAYICI", systemImage: "globe").font(.caption.bold()).foregroundStyle(.mint)
                        Text("Web, elinin altında.").font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Sevdiğin sitelere git, kendi kısayollarını oluştur.").foregroundStyle(.secondary)
                    }.padding(22).frame(maxWidth: .infinity, alignment: .leading).background(Theme.panel, in: RoundedRectangle(cornerRadius: 24))
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.mint)
                        TextField("Ara veya HTTPS adresi gir", text: $address)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .submitLabel(.go).onSubmit { navigate() }.accessibilityIdentifier("discoverAddress")
                        Button { navigate() } label: { Image(systemName: "arrow.right.circle.fill").font(.title2) }.accessibilityLabel("Web sayfasını aç")
                    }.padding(16).background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                    Text("Hızlı erişim").font(.title3.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 14)], spacing: 18) {
                        ForEach(WebShortcut.defaults + custom) { shortcut in
                            Button { open(shortcut.address) } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: shortcut.symbol).font(.title).foregroundStyle(.mint)
                                        .frame(width: 68, height: 68).background(Theme.panel, in: RoundedRectangle(cornerRadius: 20))
                                    Text(shortcut.title).font(.caption.bold()).foregroundStyle(.primary).lineLimit(1)
                                }.frame(maxWidth: .infinity)
                            }.contextMenu {
                                if custom.contains(where: { $0.id == shortcut.id }) {
                                    Button("Kısayolu sil", role: .destructive) { custom.removeAll { $0.id == shortcut.id }; save() }
                                }
                            }
                        }
                    }
                    Button("Kısayol ekle", systemImage: "plus.circle") { add = true }.buttonStyle(.bordered)
                    if let error { Text(error).foregroundStyle(.orange).font(.footnote) }
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Gezinmeye devam et", systemImage: "pip").font(.headline)
                        Text("Desteklenen videolarda sistemin Resim İçinde Resim kontrolünü kullanarak tarayıcıya dönebilirsin.").font(.subheadline).foregroundStyle(.secondary)
                        Text("Siteler kendi oturum ve abonelik koşullarını uygular. Kısayol, hizmetle ortaklık veya tüm videoların oynatılacağı anlamına gelmez.").font(.caption).foregroundStyle(.secondary)
                    }.padding(20).background(Theme.panel, in: RoundedRectangle(cornerRadius: 20))
                }.padding(20)
            }.background(Theme.background).navigationTitle("Keşfet")
                .fullScreenCover(item: $destination) { BrowserScreen(url: $0.url) }
                .sheet(isPresented: $add) {
                    NavigationStack {
                        Form {
                            TextField("Kısayol adı", text: $title)
                            TextField("HTTPS adresi", text: $bookmarkAddress).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                            if let error { Text(error).foregroundStyle(.orange) }
                        }.navigationTitle("Yeni kısayol").toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { add = false } }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Ekle") {
                                    do {
                                        let url = try SourceValidation.secureURL(bookmarkAddress)
                                        guard !(WebShortcut.defaults + custom).contains(where: { $0.address == url.absoluteString }) else { error = "Bu adres zaten ekli."; return }
                                        custom.append(WebShortcut(title: title, address: url.absoluteString, symbol: "bookmark.fill"))
                                        save(); add = false; title = ""; bookmarkAddress = "https://"; error = nil
                                    } catch { self.error = error.localizedDescription }
                                }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || custom.count >= 30)
                            }
                        }
                    }
                }.onAppear {
                    if let data = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder().decode([WebShortcut].self, from: data) { custom = saved }
                }
        }
    }
    private func navigate() {
        let text = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do { destination = WebDestination(url: try SourceValidation.browserURL(text)); error = nil }
        catch { self.error = error.localizedDescription }
    }
    private func open(_ value: String) {
        do { destination = WebDestination(url: try SourceValidation.secureURL(value)); error = nil }
        catch { self.error = error.localizedDescription }
    }
    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(custom).write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch { self.error = error.localizedDescription }
    }
}
