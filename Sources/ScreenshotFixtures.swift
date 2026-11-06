#if DEBUG
import SwiftUI
import UIKit

enum ScreenshotFixtures {
    static var page: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-store-page"), args.indices.contains(index + 1) else { return nil }
        return args[index + 1]
    }
    @MainActor static func seed(_ library: LibraryStore) async throws {
        guard library.sources.isEmpty else { return }
        for (index, title) in ["Göl kenarında", "Gün batımı"].enumerated() {
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("autopulse-demo-\(index).jpg")
            try artwork(warm: index == 1).jpegData(compressionQuality: 0.95)!.write(to: file)
            defer { try? FileManager.default.removeItem(at: file) }
            try await library.importMedia(file, title: title)
        }
        let photos = library.sources
        for (index, photo) in photos.enumerated() {
            var video = photo
            video.id = UUID()
            video.title = index == 0 ? "Doğa molası" : "Akşamın renkleri"
            video.kind = .video
            video.localFileName = photo.photoMovieFileName
            video.photoMovieFileName = nil
            video.url = video.resolvedURL
            video.group = "Kısa filmler"
            try library.addPreviewSource(video)
        }
        if let first = library.sources.first { library.favorite(first) }
        if let last = library.sources.last { library.favorite(last) }
    }
    @MainActor private static func artwork(warm: Bool) -> UIImage {
        let size = CGSize(width: 1200, height: 800)
        return UIGraphicsImageRenderer(size: size).image { renderer in
            let ctx = renderer.cgContext
            let top = warm ? UIColor(red: 0.40, green: 0.22, blue: 0.36, alpha: 1) : UIColor(red: 0.06, green: 0.26, blue: 0.33, alpha: 1)
            let bottom = warm ? UIColor(red: 0.98, green: 0.63, blue: 0.40, alpha: 1) : UIColor(red: 0.56, green: 0.82, blue: 0.78, alpha: 1)
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [top.cgColor, bottom.cgColor] as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 600), options: [])
            UIColor(red: 1, green: 0.86, blue: 0.62, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: warm ? 770 : 210, y: 155, width: 125, height: 125)).fill()
            for layer in 0..<3 {
                let baseline = CGFloat(420 + layer * 80)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0, y: baseline))
                for index in 0...8 {
                    path.addLine(to: CGPoint(x: CGFloat(index * 170 - 70), y: baseline - CGFloat(index % 2 == 0 ? 70 : 210) + CGFloat(layer * 30)))
                }
                path.addLine(to: CGPoint(x: 1200, y: 800)); path.addLine(to: CGPoint(x: 0, y: 800)); path.close()
                UIColor(red: 0.04 + Double(layer) * 0.015, green: 0.19 - Double(layer) * 0.03, blue: 0.23 - Double(layer) * 0.02, alpha: 1).setFill()
                path.fill()
            }
            UIColor(red: 0.10, green: 0.37, blue: 0.40, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 600, width: 1200, height: 200)).fill()
            for index in 0..<12 {
                UIColor.white.withAlphaComponent(CGFloat(0.16 - Double(index) * 0.01)).setFill()
                UIBezierPath(roundedRect: CGRect(x: CGFloat(420 - index * 12), y: CGFloat(620 + index * 14), width: CGFloat(360 + index * 24), height: 2), cornerRadius: 1).fill()
            }
        }
    }
}

struct StoreScreenshotFrame: View {
    let page: String
    @EnvironmentObject private var library: LibraryStore
    private var copy: (String, String) {
        switch page {
        case "import": return ("Koleksiyonun,\nsenin seçimin.", "Dosyalar, Fotoğraflar, M3U ve Xtream.")
        case "discover": return ("Sevdiğin web,\nelinin altında.", "Hızlı kısayollar ve uygulama içi tarayıcı.")
        case "photo": return ("Fotoğraflarına\nyer aç.", "Tam ekran, yakınlaştırma ve AirPlay sunumu.")
        default: return ("Tüm medyan.\nTek bir yerde.", "Videolar, fotoğraflar ve favorilerin.")
        }
    }
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("AutoPulse TV").font(.system(size: 15, weight: .semibold)).foregroundStyle(.mint)
                    Text(copy.0).font(.system(size: geometry.size.width * 0.085, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center).lineSpacing(0).fixedSize(horizontal: false, vertical: true)
                    Text(copy.1).font(.system(size: geometry.size.width * 0.033)).foregroundStyle(.white.opacity(0.7)).multilineTextAlignment(.center)
                }.frame(height: geometry.size.height * 0.22).padding(.horizontal, 12)
                Group {
                    switch page {
                    case "import": ImportHub()
                    case "discover": DiscoverScreen()
                    case "photo":
                        if let photo = library.sources.first(where: { $0.mediaKind == .photo }) { PhotoScreen(source: photo) }
                    default: RootView()
                    }
                }.frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.74)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.20), lineWidth: 2))
                    .shadow(color: .mint.opacity(0.12), radius: 22)
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient(colors: [Color(red: 0.03, green: 0.17, blue: 0.20), Theme.background, Theme.background], startPoint: .topLeading, endPoint: .bottomTrailing))
                .accessibilityIdentifier("storeScreenshotReady")
        }.ignoresSafeArea().statusBarHidden()
    }
}
#endif
