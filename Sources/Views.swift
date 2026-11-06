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
                Section("AutoPulse TV 1.1") {
                    Label("Molan için tasarlandı", systemImage: "parkingsign.circle").font(.headline)
                    Text("Kendi video kaynaklarını kaydet, listelerini düzenle ve desteklenen alıcılarda AirPlay kullan.")
                }
                Section("Araç uyumluluğu") {
                    Text("Tek derleme iPhone/iPad, AirPlay ve CarPlay kütüphanesini içerir. CarPlay için Apple tarafından onaylı audio/video yetkileri ve uygun imzalama profili gerekir. Video desteklenmediğinde liste ses modunda kalır.")
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
