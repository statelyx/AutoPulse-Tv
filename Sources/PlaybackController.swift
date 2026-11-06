import AVKit
import Combine
import SwiftUI

@MainActor
final class PlaybackController: ObservableObject {
    let player = AVPlayer()
    @Published private(set) var source: MediaSource?
    @Published private(set) var failure: String?
    @Published private(set) var loading = false
    private var statusObserver: NSKeyValueObservation?
    func open(_ source: MediaSource) {
        stop()
        self.source = source
        failure = nil
        loading = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { failure = "Ses oturumu başlatılamadı: \(error.localizedDescription)" }
        let item = AVPlayerItem(url: source.url)
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        player.replaceCurrentItem(with: item)
        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            let status = item.status
            Task { @MainActor [weak self] in
                guard let self, self.player.currentItem === item else { return }
                self.loading = status == .unknown
                if status == .failed {
                    self.failure = "Video açılamadı. Adres, ağ bağlantısı, erişim izni veya medya biçimini kontrol et."
                }
            }
        }
        if source.resumeTime > 0 { player.seek(to: CMTime(seconds: source.resumeTime, preferredTimescale: 600)) }
        player.play()
    }
    var position: Double {
        let value = player.currentTime().seconds
        return value.isFinite ? max(value, 0) : 0
    }
    func stop() {
        statusObserver = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        source = nil
        loading = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

struct PlayerScreen: View {
    let source: MediaSource
    @EnvironmentObject private var playback: PlaybackController
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var fullScreen = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VideoPlayer(player: playback.player)
                        .aspectRatio(16.0 / 9.0, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 20))
                    if playback.loading { ProgressView("Kaynak açılıyor…") }
                    if let failure = playback.failure {
                        Label(failure, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                        Button("Yeniden dene") { playback.open(source) }.buttonStyle(.bordered)
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(source.title).font(.title2.bold())
                            Text(source.group).foregroundStyle(.secondary)
                        }
                        Spacer()
                        RoutePicker().frame(width: 48, height: 48).accessibilityLabel("AirPlay hedefini seç")
                    }
                    Button("Tam ekran", systemImage: "arrow.up.left.and.arrow.down.right") { fullScreen = true }
                        .buttonStyle(.borderedProminent).tint(.mint)
                    Label("AirPlay ile büyük ekrana", systemImage: "airplayvideo").font(.headline)
                    Text("Hedef seçicisinde yalnızca desteklenen alıcılar görünür. Araçta video kullanımı resmi Video in the Car desteğine ve park koşuluna bağlıdır.")
                        .foregroundStyle(.secondary)
                }.padding()
            }
            .background(Theme.background)
            .navigationTitle("Şimdi oynatılıyor").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Bitti") { dismiss() } }
            .onAppear {
                if playback.source?.id != source.id { playback.open(source) }
            }
            .onDisappear {
                guard !fullScreen else { return }
                library.recordPlayback(source.id, seconds: playback.position)
                playback.stop()
            }
            .fullScreenCover(isPresented: $fullScreen) {
                ZStack(alignment: .topTrailing) {
                    NativePlayer(player: playback.player).ignoresSafeArea()
                    Button("Kapat") { fullScreen = false }.buttonStyle(.borderedProminent).padding()
                }.background(.black)
            }
        }
    }
}

struct NativePlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        return controller
    }
    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
    }
}

struct RoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = true
        view.tintColor = .systemMint
        return view
    }
    func updateUIView(_ view: AVRoutePickerView, context: Context) {}
}
