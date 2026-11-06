import SwiftUI
import UniformTypeIdentifiers

struct SettingsScreen: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var backup = BackupDocument()
    @State private var exporting = false
    @State private var restoring = false
    @State private var message: String?
    @State private var removeAccounts = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "play.rectangle.fill").font(.largeTitle).foregroundStyle(.mint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AutoPulse TV").font(.title2.bold())
                            Text("Kişisel medya alanın · 1.1").foregroundStyle(.secondary).font(.caption)
                        }
                    }.padding(.vertical, 12)
                }.listRowBackground(Theme.panel)
                Section("Kütüphane") {
                    LabeledContent("Toplam medya", value: "\(library.sources.count)")
                    LabeledContent("Çevrimdışı dosya", value: "\(library.sources.filter(\.isLocal).count)")
                    LabeledContent("Favoriler", value: "\(library.sources.filter(\.isFavorite).count)")
                    Button("Bağlantıları yedekle", systemImage: "square.and.arrow.up") {
                        do { backup = BackupDocument(data: try library.exportData()); exporting = true }
                        catch { message = error.localizedDescription }
                    }
                    Button("M3U / JSON içe aktar", systemImage: "square.and.arrow.down") { restoring = true }
                    Text("JSON yedeği yalnız bağımsız internet kaynaklarını içerir. Yerel dosyalar ve Xtream hesapları yedeğe dahil edilmez.").font(.caption).foregroundStyle(.secondary)
                    if library.sources.contains(where: { $0.providerID != nil }) {
                        Button("Xtream hesaplarını ve kaynaklarını kaldır", role: .destructive) { removeAccounts = true }
                    }
                }.listRowBackground(Theme.panel)
                Section("Büyük ekranda") {
                    Label("Video ve fotoğraf sunumu", systemImage: "airplayvideo")
                    Text("Fotoğraf ekranından AirPlay sunumunu açıp desteklenen alıcıyı seç. Yalnız fotoğrafı içeren sessiz video döngüsü gönderilir.").font(.subheadline).foregroundStyle(.secondary)
                    Text("Araçta kullanım Video in the Car desteğine ve sistemin izin verdiği park koşullarına bağlıdır. Her CarPlay ekranı bu özelliği desteklemez.").font(.caption).foregroundStyle(.secondary)
                }.listRowBackground(Theme.panel)
                Section("Uygulama") {
                    NavigationLink { InformationScreen() } label: { Label("Gizlilik ve uyumluluk", systemImage: "lock.shield") }
                    Link(destination: URL(string: "https://github.com/statelyx/AutoPulse-Tv/blob/main/store/privacy-draft-tr.md")!) { Label("Gizlilik politikası", systemImage: "hand.raised") }
                }.listRowBackground(Theme.panel)
            }.scrollContentBackground(.hidden).background(Theme.background).navigationTitle("Ayarlar")
                .fileExporter(isPresented: $exporting, document: backup, contentType: .json, defaultFilename: "AutoPulseTV-kaynaklar") { result in
                    if case .failure(let error) = result { message = error.localizedDescription }
                }
                .fileImporter(isPresented: $restoring, allowedContentTypes: [.data, .text, .json]) { result in
                    do { message = "\(try library.importFile(result.get())) kaynak eklendi." }
                    catch { message = error.localizedDescription }
                }
                .alert("Kütüphane", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                    Button("Tamam") { message = nil }
                } message: { Text(message ?? "") }
                .confirmationDialog("Xtream hesap bilgileri Anahtar Zinciri’nden ve bu hesapların kaynakları kütüphaneden kaldırılacak.", isPresented: $removeAccounts, titleVisibility: .visible) {
                    Button("Hesapları kaldır", role: .destructive) {
                        do { try library.removeXtreamAccounts() }
                        catch { message = error.localizedDescription }
                    }
                }
        }
    }
}
