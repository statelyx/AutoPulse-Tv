import AVKit
import Combine
import SwiftUI

@MainActor
final class PlaybackController: ObservableObject {
    let player = AVQueuePlayer()
    private var photoLooper: AVPlayerLooper?
    @Published private(set) var source: MediaSource?
    @Published private(set) var failure: String?
    @Published private(set) var loading = false
    @Published var pictureInPictureActive = false
    private var statusObserver: NSKeyValueObservation?
    private var waitingObserver: NSKeyValueObservation?
    private var pendingResume: Double = 0
    func open(_ source: MediaSource) {
        stop()
        self.source = source
        if let providerID = source.providerID, AccountVault.read(providerID) == nil {
            failure = "Bu hesabı Kaynak ekle > Xtream hesabı bölümünden yeniden bağla."
            return
        }
        pendingResume = source.mediaKind == .photo ? 0 : source.resumeTime
        failure = nil
        loading = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { failure = "Ses oturumu başlatılamadı: \(error.localizedDescription)" }
        let item = AVPlayerItem(url: source.playbackURL)
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        player.automaticallyWaitsToMinimizeStalling = true
        if source.mediaKind == .photo {
            photoLooper = AVPlayerLooper(player: player, templateItem: item)
            loading = false
        } else { player.replaceCurrentItem(with: item) }
        let observedItem = player.currentItem ?? item
        statusObserver = observedItem.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            let status = item.status
            Task { @MainActor [weak self] in
                guard let self, self.player.currentItem === item else { return }
                self.loading = status == .unknown
                if status == .readyToPlay, self.pendingResume > 0 {
                    let duration = item.duration.seconds
                    // Live/indefinite streams should start at the live edge, not an old timestamp.
                    if let position = PlaybackPositionPolicy.resumeTarget(saved: self.pendingResume, duration: duration) {
                        self.player.seek(to: CMTime(seconds: position, preferredTimescale: 600))
                    }
                    self.pendingResume = 0
                }
                if status == .failed {
                    self.failure = "Video açılamadı. Adres, ağ bağlantısı, erişim izni veya medya biçimini kontrol et."
                }
            }
        }
        waitingObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.loading = self.player.currentItem?.status == .unknown || self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            }
        }
        player.play()
    }
    var position: Double {
        guard source?.mediaKind != .photo else { return 0 }
        let value = player.currentTime().seconds
        return PlaybackPositionPolicy.savedPosition(current: value, duration: player.currentItem?.duration.seconds ?? .nan)
    }
    func stop() {
        photoLooper?.disableLooping()
        photoLooper = nil
        statusObserver = nil
        waitingObserver = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        source = nil
        loading = false
        pictureInPictureActive = false
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
                    NativePlayer(player: playback.player, onPiPChange: { playback.pictureInPictureActive = $0 })
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
                    Text(source.mediaKind == .photo ? "Bu sessiz sunum döngüsü yalnız seçtiğin fotoğrafı gösterir. AirPlay hedefinden desteklenen alıcıyı seç. Araç desteği sisteme bağlıdır." : "Hedef seçicisinde yalnızca desteklenen alıcılar görünür. Desteklenen videoda Resim İçinde Resim’i açıp Bitti ile kütüphaneye dönebilirsin.")
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
                guard !fullScreen, !playback.pictureInPictureActive else { return }
                library.recordPlayback(source.id, seconds: playback.position)
                playback.stop()
            }
            .fullScreenCover(isPresented: $fullScreen) {
                ZStack(alignment: .topTrailing) {
                    NativePlayer(player: playback.player, onPiPChange: { playback.pictureInPictureActive = $0 }).ignoresSafeArea()
                    Button("Kapat") { fullScreen = false }.buttonStyle(.borderedProminent).padding()
                }.background(.black)
            }
        }
    }
}

struct NativePlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    var onPiPChange: (Bool) -> Void = { _ in }
    func makeCoordinator() -> Coordinator { Coordinator(onPiPChange: onPiPChange) }
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
    }
    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        let onPiPChange: (Bool) -> Void
        init(onPiPChange: @escaping (Bool) -> Void) { self.onPiPChange = onPiPChange }
        func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) { onPiPChange(true) }
        func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) { onPiPChange(false) }
        func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) { completionHandler(false) }
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
