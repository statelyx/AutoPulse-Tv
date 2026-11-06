import SwiftUI
import SafariServices
import UniformTypeIdentifiers

enum Theme {
    static let background = Color(red: 0.035, green: 0.055, blue: 0.10)
    static let panel = Color(red: 0.075, green: 0.10, blue: 0.16)
    static let accent = Color.mint
}

struct RootView: View {
    @EnvironmentObject private var playback: PlaybackController
    var body: some View {
        TabView {
            MediaLibraryScreen().tabItem { Label("Kütüphane", systemImage: "square.grid.2x2.fill") }
            MediaLibraryScreen(favoritesOnly: true).tabItem { Label("Favoriler", systemImage: "heart.fill") }
            DiscoverScreen().tabItem { Label("Keşfet", systemImage: "globe") }
            SettingsScreen().tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }
        }.tint(Theme.accent)
            .safeAreaInset(edge: .bottom) {
                if let source = playback.source {
                    HStack {
                        Image(systemName: "play.circle.fill").foregroundStyle(.mint)
                        Text(source.title).font(.caption).lineLimit(1)
                        Spacer()
                        Button("Durdur") { playback.stop() }.font(.caption.bold())
                    }.padding(12).background(Theme.panel)
                }
            }
    }
}

struct LibraryScreen: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var query = ""
    @State private var favoritesOnly = false
    @State private var add = false
    @State private var selected: MediaSource?
    @State private var exporting = false
    @State private var backup = BackupDocument()
    private var filtered: [MediaSource] {
        library.sources.filter {
            (!favoritesOnly || $0.isFavorite) && (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query)
                || $0.group.localizedCaseInsensitiveContains(query))
        }.sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("PARK ET. ARKANA YASLAN.", systemImage: "sparkles")
                            .font(.caption.bold()).foregroundStyle(Theme.accent)
                        Text("Molanın oynatma listesi.").font(.largeTitle.bold())
                        Text("Kendi videoların. Kendi kütüphanen.").foregroundStyle(.secondary)
                        HStack {
                            Label("\(library.sources.count) kaynak", systemImage: "square.stack")
                            Spacer()
                            Label("AirPlay", systemImage: "airplayvideo")
                        }.font(.caption).padding(.top, 6)
                    }.padding(.vertical, 12)
                }.listRowBackground(Theme.panel)
                Section {
                    Toggle("Yalnız favoriler", isOn: $favoritesOnly)
                    if filtered.isEmpty {
                        ContentUnavailableView(query.isEmpty ? "Kütüphanen hazır" : "Sonuç bulunamadı",
                            systemImage: "play.rectangle", description: Text("+ düğmesinden bir video veya M3U listesi ekle."))
                    }
                    ForEach(filtered) { source in
                        Button { selected = source } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "play.fill").foregroundStyle(Theme.accent)
                                    .frame(width: 44, height: 44).background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(source.title).font(.headline).foregroundStyle(.primary)
                                    Text(source.group).font(.caption).foregroundStyle(.secondary)
                                    if source.resumeTime > 5 {
                                        Text("\(Int(min(source.resumeTime / 60, 525_600))) dk · kaldığın yerden").font(.caption2).foregroundStyle(Theme.accent)
                                    }
                                }
                                Spacer()
                                if source.isFavorite { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                            }.padding(.vertical, 6)
                        }
                        .swipeActions(edge: .trailing) { Button("Sil", role: .destructive) { library.remove(source) } }
                        .swipeActions(edge: .leading) {
                            Button(source.isFavorite ? "Favoriden çıkar" : "Favorile") { library.favorite(source) }.tint(.orange)
                        }
                        .contextMenu {
                            Button(source.isFavorite ? "Favoriden çıkar" : "Favorile", systemImage: "star") { library.favorite(source) }
                            Button("Sil", systemImage: "trash", role: .destructive) { library.remove(source) }
                        }
                    }
                }.listRowBackground(Theme.panel)
            }
            .scrollContentBackground(.hidden).background(Theme.background)
            .navigationTitle("AutoPulse TV")
            .searchable(text: $query, prompt: "Kaynak veya grup ara")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { do { backup = BackupDocument(data: try library.exportData()); exporting = true }
                        catch { library.message = error.localizedDescription }
                    } label: { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Kütüphaneyi dışa aktar")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { add = true } label: { Image(systemName: "plus.circle.fill") }
                        .accessibilityLabel("Kaynak ekle").accessibilityIdentifier("addSource")
                }
            }
            .sheet(isPresented: $add) { AddSourceScreen() }
            .sheet(item: $selected) { PlayerScreen(source: $0) }
            .fileExporter(isPresented: $exporting, document: backup, contentType: .json, defaultFilename: "AutoPulseTV-kutuphanem") { result in
                if case .failure(let error) = result { library.message = error.localizedDescription }
            }
            .alert("Kütüphane", isPresented: Binding(get: { library.message != nil }, set: { if !$0 { library.message = nil } })) {
                Button("Tamam") { library.message = nil }
            } message: { Text(library.message ?? "") }
        }
    }
}

struct AddSourceScreen: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var address = ""
    @State private var listAddress = ""
    @State private var error: String?
    @State private var chooseFile = false
    @State private var importTask: Task<Void, Never>?
    var body: some View {
        NavigationStack {
            Form {
                Section("Video bağlantısı") {
                    TextField("Kaynak adı", text: $title).accessibilityIdentifier("sourceTitle")
                    TextField("HTTPS video adresi", text: $address).urlInput().accessibilityIdentifier("sourceURL")
                    Button("Kaydet") {
                        do { _ = try library.add(title: title, address: address); dismiss() }
                        catch { self.error = error.localizedDescription }
                    }.accessibilityIdentifier("saveSource")
                    Text("Doğrudan HLS, MP4 veya MOV adresi kullan. Bir web sayfasının adresi doğrudan video kaynağı değildir.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("M3U listesi") {
                    TextField("HTTPS M3U liste adresi", text: $listAddress).urlInput()
                    Button {
                        importTask = Task {
                            do {
                                let count = try await library.importRemote(listAddress)
                                try Task.checkCancellation()
                                library.message = "\(count) yeni kaynak eklendi."
                                dismiss()
                            } catch is CancellationError { }
                            catch { self.error = error.localizedDescription }
                        }
                    } label: {
                        if library.importing { ProgressView("İçe aktarılıyor…") }
                        else { Label("Adresten içe aktar", systemImage: "arrow.down.doc") }
                    }.disabled(library.importing || listAddress.isEmpty)
                    Button("Dosyadan M3U / JSON içe aktar", systemImage: "folder") { chooseFile = true }
                        .disabled(library.importing)
                    Text("Yalnız kullanım hakkına sahip olduğun kaynakları ekle. 2 MB / 2.000 kaynak sınırı uygulanır.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let error { Section { Text(error).foregroundStyle(.orange) } }
            }
            .navigationTitle("Kaynak ekle").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Vazgeç") { importTask?.cancel(); dismiss() } }
            .fileImporter(isPresented: $chooseFile, allowedContentTypes: [.data, .text, .json]) { result in
                do {
                    let count = try library.importFile(result.get())
                    library.message = "\(count) yeni kaynak eklendi."
                    dismiss()
                } catch { self.error = error.localizedDescription }
            }
            .onDisappear { importTask?.cancel() }
        }
    }
}

struct WebScreen: View {
    @State private var address = "https://www.youtube.com"
    @State private var site: WebDestination?
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Web, telefonunda.", systemImage: "globe").font(.title.bold())
                    Text("Video sitelerini uygulamanın WebKit tarayıcısında aç.").foregroundStyle(.secondary)
                }
                Section("Adres") {
                    TextField("HTTPS web adresi", text: $address).urlInput()
                    Button("Sayfayı aç", systemImage: "arrow.up.right") { open(address) }
                    Button("YouTube", systemImage: "play.rectangle") { open("https://www.youtube.com") }
                    if let error { Text(error).foregroundStyle(.orange) }
                }
                Section {
                    Text("Bu bölüm araç ekranında tarayıcı açmaz. Web videolarının AirPlay ve harici ekran desteği ilgili hizmete bağlıdır.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("Web")
            .fullScreenCover(item: $site) { BrowserScreen(url: $0.url) }
        }
    }
    private func open(_ text: String) {
        do { site = WebDestination(url: try SourceValidation.secureURL(text)); error = nil }
        catch { self.error = error.localizedDescription }
    }
}

struct WebDestination: Identifiable { let id = UUID(); let url: URL }
struct SafariScreen: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

struct InformationScreen: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("AutoPulse TV 1.0") {
                    Label("Molan için tasarlandı", systemImage: "parkingsign.circle").font(.headline)
                    Text("Kendi video kaynaklarını kaydet, listelerini düzenle ve desteklenen alıcılarda AirPlay kullan.")
                }
                Section("Araç uyumluluğu") {
                    #if CARPLAY_ENABLED
                    Text("Bu derleme, Apple CarPlay video yetkisi ve Video in the Car destekli bir araç gerektirir. Kütüphane CarPlay'in ekranına uyarlanan yerel şablonlarıyla gösterilir.")
                    #else
                    Text("Bu sürüm iPhone/iPad ve AirPlay oynatıcısıdır. CarPlay ana ekranında uygulama veya web tarayıcısı arayüzü içermez.")
                    #endif
                    Text("Araçta video için resmi Video in the Car desteği gerekir. Eski CarPlay sistemlerinde videoyu etkinleştirme veya hareket kısıtlamasını aşma özelliği bulunmaz.")
                    Text("Araç ekranında video yalnızca park halinde kullanılmalıdır.").foregroundStyle(Theme.accent)
                }
                Section("Gizlilik") {
                    Text("Kaynak adları, adresler, favoriler ve izleme konumu cihazda saklanır. Geliştiriciye veri gönderen analitik veya reklam SDK'sı yoktur.")
                    Text("Video ve web sitesi açıldığında ilgili sağlayıcıya bağlanırsın. Sağlayıcı IP adresi ve oturum bilgilerini kendi politikası kapsamında işleyebilir.")
                    Text("Dışa aktardığın JSON dosyası özel video bağlantıları içerebilir. Yalnız güvendiğin kişilerle paylaş.")
                }
                Section("İçerik") {
                    Text("AutoPulse TV içerik veya TV kanalı sağlamaz. Yalnız kendi veya kullanım hakkına sahip olduğun kaynakları kullan. DRM korumalı ya da özel oturum isteyen her kaynak desteklenmeyebilir.")
                }
            }.navigationTitle("Bilgi")
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data = Data()
    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

private extension View {
    func urlInput() -> some View {
        textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
    }
}
