import SwiftUI
import UIKit

struct PhotoScreen: View {
    let source: MediaSource
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var current: MediaSource?
    @State private var image: UIImage?
    @State private var controls = true
    @State private var slideshow = false
    @State private var casting = false
    @State private var loadFailed = false
    private var selected: MediaSource { current ?? source }
    private var photos: [MediaSource] { library.sources.filter { $0.mediaKind == .photo } }
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let image {
                ZoomPhoto(image: image).ignoresSafeArea()
                    .accessibilityIdentifier("photoImageReady")
                    .onTapGesture { withAnimation { controls.toggle() } }
            } else if loadFailed {
                ContentUnavailableView("Fotoğraf bulunamadı", systemImage: "photo.badge.exclamationmark", description: Text("Dosyayı yeniden içe aktarabilirsin."))
            } else { ProgressView("Fotoğraf açılıyor…").tint(.mint) }
            if controls {
                VStack {
                    HStack {
                        Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title) }.accessibilityLabel("Kapat")
                        Spacer()
                        Text(selected.title).font(.headline).lineLimit(1)
                        Spacer()
                        Button { library.favorite(selected); current = library.sources.first { $0.id == selected.id } } label: {
                            Image(systemName: (library.sources.first { $0.id == selected.id }?.isFavorite ?? false) ? "heart.fill" : "heart")
                        }.accessibilityLabel("Favori durumunu değiştir")
                    }.padding().background(.black.opacity(0.65))
                    Spacer()
                    VStack(spacing: 18) {
                        HStack(spacing: 32) {
                            Button { advance(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Önceki fotoğraf")
                            Button { slideshow.toggle() } label: { Label(slideshow ? "Durdur" : "Slayt gösterisi", systemImage: slideshow ? "pause.fill" : "play.fill") }
                            Button { advance(1) } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Sonraki fotoğraf")
                        }.disabled(photos.count < 2)
                        HStack(spacing: 22) {
                            Button { slideshow = false; casting = true } label: { Label("AirPlay sunumu", systemImage: "airplayvideo") }
                                .accessibilityIdentifier("photoAirPlay")
                            ShareLink(item: selected.resolvedURL) { Image(systemName: "square.and.arrow.up") }.accessibilityLabel("Fotoğrafı paylaş")
                        }
                        Text("Büyütmek için iki parmağınla aç. Kontrolleri gizlemek için dokun.")
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.padding(20).frame(maxWidth: .infinity).background(.black.opacity(0.75))
                }
            }
        }.foregroundStyle(.white).tint(.mint)
            .task(id: selected.id) {
                image = nil
                loadFailed = false
                let url = selected.resolvedURL
                image = await Task.detached(priority: .userInitiated) { MediaImporter.thumbnail(url, maximum: 3000) }.value
                loadFailed = image == nil
            }
            .task(id: slideshow) {
                guard slideshow else { return }
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(5)) } catch { return }
                    if scenePhase == .active { advance(1) }
                }
            }
            .sheet(isPresented: $casting) { PlayerScreen(source: selected) }
            .onDisappear { slideshow = false }
    }
    private func advance(_ delta: Int) {
        guard !photos.isEmpty else { return }
        let index = photos.firstIndex { $0.id == selected.id } ?? 0
        current = photos[(index + delta + photos.count) % photos.count]
    }
}

struct ZoomPhoto: UIViewRepresentable {
    let image: UIImage
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.minimumZoomScale = 1; scroll.maximumZoomScale = 5
        scroll.delegate = context.coordinator
        scroll.showsVerticalScrollIndicator = false; scroll.showsHorizontalScrollIndicator = false
        let view = context.coordinator.imageView
        view.contentMode = .scaleAspectFit
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.addSubview(view)
        return scroll
    }
    func updateUIView(_ scroll: UIScrollView, context: Context) {
        let view = context.coordinator.imageView
        if view.image !== image { scroll.setZoomScale(1, animated: false); view.image = image }
        if scroll.zoomScale == 1 { view.frame = scroll.bounds }
    }
    final class Coordinator: NSObject, UIScrollViewDelegate {
        let imageView = UIImageView()
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    }
}
