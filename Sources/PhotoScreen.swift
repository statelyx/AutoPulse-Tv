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

struct ZoomPhoto: View {
    let image: UIImage
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    @State private var offset = CGSize.zero
    @State private var settledOffset = CGSize.zero
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image).resizable().scaledToFit()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(scale).offset(offset)
                .gesture(MagnificationGesture()
                    .onChanged { scale = min(5, max(1, settledScale * $0)) }
                    .onEnded { _ in
                        settledScale = scale
                        if scale == 1 { offset = .zero; settledOffset = .zero }
                    })
                .simultaneousGesture(DragGesture()
                    .onChanged { value in
                        guard scale > 1 else { return }
                        let limitX = geometry.size.width * (scale - 1) / 2
                        let limitY = geometry.size.height * (scale - 1) / 2
                        offset = CGSize(
                            width: min(limitX, max(-limitX, settledOffset.width + value.translation.width)),
                            height: min(limitY, max(-limitY, settledOffset.height + value.translation.height)))
                    }
                    .onEnded { _ in settledOffset = offset })
                .accessibilityLabel("Fotoğraf")
        }.clipped()
            .onChange(of: image) { _, _ in
                scale = 1; settledScale = 1; offset = .zero; settledOffset = .zero
            }
    }
}
