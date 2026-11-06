import SwiftUI
import PhotosUI
import AVFoundation

struct MediaLibraryScreen: View {
    var favoritesOnly = false
    @EnvironmentObject private var library: LibraryStore
    @State private var query = ""
    @State private var kind = "Tümü"
    @State private var group = "Tüm gruplar"
    @State private var add = false
    @State private var selected: MediaSource?
    @State private var selectedPhoto: MediaSource?
    @State private var editing: MediaSource?
    private var groups: [String] { ["Tüm gruplar"] + Set(library.sources.map(\.group)).sorted() }
    private var sources: [MediaSource] {
        library.sources.filter {
            (!favoritesOnly || $0.isFavorite) &&
            (kind == "Tümü" || (kind == "Fotoğraf" ? $0.mediaKind == .photo : $0.mediaKind == .video)) &&
            (group == "Tüm gruplar" || $0.group == group) &&
            (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.group.localizedCaseInsensitiveContains(query))
        }.sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !favoritesOnly { hero }
                    Picker("Medya türü", selection: $kind) {
                        ForEach(["Tümü", "Video", "Fotoğraf"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("mediaFilter")
                    HStack {
                        Text(favoritesOnly ? "Sevdiklerin bir arada" : "Medya koleksiyonun").font(.title3.bold())
                        Spacer()
                        Menu {
                            Picker("Grup", selection: $group) {
                                ForEach(groups, id: \.self) { Text($0) }
                            }
                        } label: { Label(group, systemImage: "line.3.horizontal.decrease") }.font(.caption)
                    }
                    if sources.isEmpty {
                        ContentUnavailableView(favoritesOnly ? "Favorilerini seç" : "Kütüphanen hazır",
                            systemImage: favoritesOnly ? "heart" : "play.rectangle.on.rectangle",
                            description: Text(favoritesOnly ? "Bir medyaya uzun basıp favorilerine ekle." : "Videolarını, fotoğraflarını veya M3U listeni ekleyerek başla."))
                        if !favoritesOnly {
                            Button("Kaynak ekle", systemImage: "plus") { add = true }
                                .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                        }
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 14)], spacing: 18) {
                            ForEach(sources) { source in
                                Button {
                                    if source.mediaKind == .photo { selectedPhoto = source }
                                    else { selected = source }
                                } label: { MediaCard(source: source) }
                                    .buttonStyle(.plain).accessibilityIdentifier("media-\(source.title)")
                                    .contextMenu {
                                        Button(source.isFavorite ? "Favoriden çıkar" : "Favorile", systemImage: "heart") { library.favorite(source) }
                                        Button("Adı ve grubu düzenle", systemImage: "pencil") { editing = source }
                                        Button("Sil", systemImage: "trash", role: .destructive) { library.remove(source) }
                                    }
                            }
                        }
                    }
                    Label("Kendi içeriklerin, kendi alanın.", systemImage: "lock.shield")
                        .font(.footnote).foregroundStyle(.secondary).padding(.top, 8)
                }.padding(20)
            }.background(Theme.background)
                .navigationTitle(favoritesOnly ? "Favoriler" : "AutoPulse TV")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $query, prompt: "Kaynak veya grup ara")
                .toolbar {
                    Button { add = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                        .accessibilityLabel("Kaynak ekle").accessibilityIdentifier("addSource")
                }
                .sheet(isPresented: $add) { ImportHub() }
                .sheet(item: $editing) { EditMediaScreen(source: $0) }
                .sheet(item: $selected) { PlayerScreen(source: $0) }
                .fullScreenCover(item: $selectedPhoto) { PhotoScreen(source: $0) }
                .alert("Kütüphane", isPresented: Binding(get: { library.message != nil }, set: { if !$0 { library.message = nil } })) {
                    Button("Tamam") { library.message = nil }
                } message: { Text(library.message ?? "") }
        }
    }
    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("SANA AİT BİR KOLEKSİYON", systemImage: "sparkles").font(.caption.bold()).foregroundStyle(.mint)
            Text("Molanın oynatma listesi.").font(.system(size: 28, weight: .bold, design: .rounded))
            Text("Videoların ve fotoğrafların. Hepsi aynı yerde.").font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Label("\(library.sources.filter { $0.mediaKind == .video }.count) video", systemImage: "play.rectangle")
                Label("\(library.sources.filter { $0.mediaKind == .photo }.count) fotoğraf", systemImage: "photo")
                Spacer()
            }.font(.caption).foregroundStyle(.mint).padding(.top, 5)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
            .background(LinearGradient(colors: [Color(red: 0.06, green: 0.22, blue: 0.23), Theme.panel], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
    }
}

struct MediaCard: View {
    let source: MediaSource
    @State private var thumbnail: UIImage?
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 18).fill(Theme.panel)
                if let thumbnail { Image(uiImage: thumbnail).resizable().scaledToFill() }
                else { Image(systemName: source.mediaKind == .photo ? "photo" : "play.rectangle.fill")
                    .font(.system(size: 36)).foregroundStyle(.mint).frame(maxWidth: .infinity, maxHeight: .infinity) }
                HStack {
                    Label(source.mediaKind == .photo ? "FOTOĞRAF" : (source.isLocal ? "ÇEVRİMDIŞI" : "VİDEO"), systemImage: source.mediaKind == .photo ? "photo" : "play.fill")
                    Spacer()
                    if source.isFavorite { Image(systemName: "heart.fill").foregroundStyle(.mint) }
                }.font(.system(size: 9, weight: .bold)).padding(9).background(.black.opacity(0.6))
            }.frame(height: 105).clipShape(RoundedRectangle(cornerRadius: 18))
            Text(source.title).font(.subheadline.bold()).lineLimit(2).foregroundStyle(.white)
            Text(source.group).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            if source.resumeTime > 5 && source.mediaKind == .video {
                Label("\(Int(source.resumeTime / 60)) dk · devam et", systemImage: "clock").font(.caption2).foregroundStyle(.mint)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .task(id: source.id) {
                guard source.isLocal else { return }
                thumbnail = await Task.detached(priority: .utility) {
                    if source.mediaKind == .photo { return MediaImporter.thumbnail(source.resolvedURL, maximum: 480) }
                    let generator = AVAssetImageGenerator(asset: AVURLAsset(url: source.resolvedURL))
                    generator.appliesPreferredTrackTransform = true
                    generator.maximumSize = CGSize(width: 480, height: 270)
                    guard let result = try? await generator.image(at: .zero) else { return nil as UIImage? }
                    return UIImage(cgImage: result.image)
                }.value
            }
    }
}

struct EditMediaScreen: View {
    let source: MediaSource
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var group = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("Ad", text: $title)
                TextField("Grup", text: $group)
            }.navigationTitle("Medyayı düzenle").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        var copy = source
                        copy.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        copy.group = group.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Kütüphanem" : group
                        library.update(copy); dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }.onAppear { title = source.title; group = source.group }
        }
    }
}

struct ImportHub: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var photos: [PhotosPickerItem] = []
    @State private var files = false
    @State private var link = false
    @State private var xtream = false
    @State private var busy = false
    @State private var status: String?
    @State private var failure: String?
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "plus.rectangle.on.folder.fill").font(.largeTitle).foregroundStyle(.mint)
                        Text("Koleksiyonunu oluştur.").font(.title2.bold())
                        Text("Cihazındaki medyaları ekle veya kendi yayın kaynaklarını bağla.").foregroundStyle(.secondary)
                    }.padding(.vertical, 12)
                }.listRowBackground(Theme.panel)
                Section("Cihazından ekle") {
                    Button { files = true } label: { importRow("Dosyalar’dan ekle", "Video ve fotoğrafların çevrimdışı saklanır.", "folder.fill") }
                        .accessibilityIdentifier("importFiles")
                    PhotosPicker(selection: $photos, maxSelectionCount: 20, matching: .any(of: [.images, .videos]), preferredItemEncoding: .current) {
                        importRow("Fotoğraflar’dan seç", "Yalnızca seçtiğin fotoğraf ve videolar alınır.", "photo.on.rectangle.angled")
                    }.accessibilityIdentifier("importPhotos")
                }.listRowBackground(Theme.panel).disabled(busy)
                Section("Kaynaklarını bağla") {
                    Button { link = true } label: { importRow("Video bağlantısı veya M3U", "HTTPS adresi, M3U listesi veya JSON yedeği.", "link") }
                        .accessibilityIdentifier("importLink")
                    Button { xtream = true } label: { importRow("Xtream hesabı", "Kendi sağlayıcının HTTPS / HLS kaynakları.", "person.crop.rectangle") }
                }.listRowBackground(Theme.panel).disabled(busy)
                if busy { Section { ProgressView(status ?? "İçe aktarılıyor…") } }
                if let status, !busy { Section { Label(status, systemImage: "checkmark.circle").foregroundStyle(.mint) } }
                if let failure { Section { Text(failure).foregroundStyle(.orange) } }
                Section { Text("Dosya başına 500 MB. Yerel dosyalar uygulamaya kopyalanır; orijinalleri değişmez. Hazır kanal veya içerik sağlanmaz.").font(.footnote).foregroundStyle(.secondary) }
            }.scrollContentBackground(.hidden).background(Theme.background)
                .navigationTitle("Kaynak ekle").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Bitti") { dismiss() }.disabled(busy) }
                .interactiveDismissDisabled(busy)
                .sheet(isPresented: $link) { AddSourceScreen() }
                .sheet(isPresented: $xtream) { XtreamScreen() }
                .fileImporter(isPresented: $files, allowedContentTypes: [.movie, .image], allowsMultipleSelection: true) { result in
                    switch result {
                    case .success(let urls): Task { await importFiles(urls) }
                    case .failure(let error): failure = error.localizedDescription
                    }
                }
                .task(id: photos) {
                    guard !photos.isEmpty else { return }
                    busy = true; failure = nil
                    var count = 0
                    for (index, item) in photos.enumerated() {
                        status = "\(index + 1) / \(photos.count) hazırlanıyor…"
                        do {
                            guard let file = try await item.loadTransferable(type: PickedMedia.self) else { throw MediaError.unsupportedFile }
                            defer { try? FileManager.default.removeItem(at: file.url) }
                            let photo = item.supportedContentTypes.contains { $0.conforms(to: .image) }
                            try await library.importMedia(file.url, title: "\(photo ? "Fotoğraf" : "Video") \(library.sources.count + 1)")
                            count += 1
                        } catch { failure = error.localizedDescription }
                    }
                    status = "\(count) medya kütüphanene eklendi."; busy = false
                }
        }.tint(.mint)
    }
    private func importRow(_ title: String, _ subtitle: String, _ symbol: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.mint).frame(width: 36)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }.padding(.vertical, 9)
        }
    }
    @MainActor private func importFiles(_ urls: [URL]) async {
        busy = true; failure = nil
        var count = 0
        for (index, url) in urls.enumerated() {
            status = "\(index + 1) / \(urls.count) kopyalanıyor…"
            do { try await library.importMedia(url); count += 1 }
            catch { failure = error.localizedDescription }
        }
        status = "\(count) medya kütüphanene eklendi."; busy = false
    }
}
