import CarPlay
import Combine
import AVFoundation

/// Included by project.yml. Requires Apple's approved CarPlay entitlements.
/// No phone framebuffer capture, ReplayKit, hidden web view or navigation-category workaround.
@available(iOS 27.0, *)
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPSessionConfigurationDelegate {
    private var controller: CPInterfaceController?
    private var configuration: CPSessionConfiguration?
    private var subscription: AnyCancellable?

    func templateApplicationScene(_ scene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        controller = interfaceController
        configuration = CPSessionConfiguration(delegate: self)
        subscription = AppServices.library.$sources.receive(on: RunLoop.main).sink { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        refresh()
    }

    func templateApplicationScene(_ scene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        if let source = AppServices.playback.source {
            AppServices.library.recordPlayback(source.id, seconds: AppServices.playback.position)
        }
        AppServices.playback.stop()
        subscription = nil
        configuration = nil
        controller = nil
    }

    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
        refresh()
    }

    private func refresh() {
        guard let controller, let configuration else { return }
        // Capability is not a motion/park signal. iOS/vehicle retain video-availability control.
        let videoOK = configuration.supportsVideoPlayback
        let sources = AppServices.library.sources.sorted { $0.isFavorite && !$1.isFavorite }
        let items = sources.prefix(CPListTemplate.maximumItemCount).map { source -> CPListItem in
            let detail = videoOK ? source.group : [source.group, "Ses"].filter { !$0.isEmpty }.joined(separator: " · ")
            let row = CPListItem(text: source.title, detailText: detail, image: UIImage(systemName: source.mediaKind == .photo ? "photo" : "play.rectangle"))
            row.playbackConfiguration = CPPlaybackConfiguration(preferredPresentation: videoOK ? .video : .audio, playbackAction: .play,
                elapsedTime: CMTime(seconds: source.resumeTime, preferredTimescale: 600), duration: .zero)
            row.handler = { _, completion in
                if let previous = AppServices.playback.source {
                    AppServices.library.recordPlayback(previous.id, seconds: AppServices.playback.position)
                }
                AppServices.playback.open(source)
                completion()
            }
            return row
        }
        let empty = CPListItem(text: "Kütüphanen boş. Park halindeyken iPhone'dan kaynak ekle.", detailText: nil)
        empty.isEnabled = false
        let section = CPListSection(items: items.isEmpty ? [empty] : items)
        let template = CPListTemplate(title: videoOK ? "AutoPulse TV" : "AutoPulse TV — Ses", sections: [section])
        let pause = CPBarButton(title: "Duraklat") { _ in AppServices.playback.player.pause() }
        let resume = CPBarButton(title: "Oynat") { _ in AppServices.playback.player.play() }
        template.trailingNavigationBarButtons = [pause, resume]
        controller.setRootTemplate(template, animated: false) { _, error in
            if let error { AppServices.library.message = error.localizedDescription }
        }
    }
}
