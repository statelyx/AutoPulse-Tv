import CarPlay
import Combine
import AVFoundation

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPSessionConfigurationDelegate {
    private var controller: CPInterfaceController?
    private var configuration: CPSessionConfiguration?
    private var subscriptions = Set<AnyCancellable>()
    private let library = CPListTemplate(title: "Kütüphane", sections: [])
    private let favorites = CPListTemplate(title: "Favoriler", sections: [])
    private let discover = CPListTemplate(title: "Keşfet", sections: [])
    private let browserGate = CarBrowserParkGate.shared
    private let browserLink = CarBrowserLink.shared
    private let groups = CPListTemplate(title: "Gruplar", sections: [])
    private let playback = CPListTemplate(title: "Oynatıcı", sections: [])
    private var openGroup: (name: String, template: CPListTemplate)?

    func templateApplicationScene(_ scene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        controller = interfaceController
        configuration = CPSessionConfiguration(delegate: self)
        for (template, title, symbol) in [(library, "Kütüphane", "square.grid.2x2"),
                                          (favorites, "Favoriler", "heart.fill"),
                                          (discover, "Keşfet", "globe"),
                                          (playback, "Oynatıcı", "play.circle")] {
            template.tabTitle = title
            template.tabImage = UIImage(systemName: symbol)
        }
        library.trailingNavigationBarButtons = [CPBarButton(title: "Gruplar") { [weak self] _ in
            guard let self else { return }
            self.controller?.pushTemplate(self.groups, animated: true, completion: nil)
        }]
        browserGate.start()
        browserGate.objectWillChange.sink { [weak self] _ in self?.scheduleRefresh() }.store(in: &subscriptions)
        browserLink.objectWillChange.sink { [weak self] _ in self?.scheduleRefresh() }.store(in: &subscriptions)
        refresh()
        interfaceController.setRootTemplate(CPTabBarTemplate(templates: [library, favorites, discover, playback]), animated: false) { _, error in
            if let error { AppServices.library.message = error.localizedDescription }
        }
        AppServices.library.$sources.sink { [weak self] _ in self?.scheduleRefresh() }.store(in: &subscriptions)
        AppServices.playback.$source.sink { [weak self] _ in self?.scheduleRefresh() }.store(in: &subscriptions)
        AppServices.playback.$failure.sink { [weak self] _ in self?.scheduleRefresh() }.store(in: &subscriptions)
        AppServices.playback.$loading.sink { [weak self] _ in self?.scheduleRefresh() }.store(in: &subscriptions)
    }

    func templateApplicationScene(_ scene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        savePosition()
        if !browserLink.connected { browserGate.stop() }
        subscriptions.removeAll()
        openGroup = nil
        configuration = nil
        controller = nil
        // Playback can continue on iPhone after the receiver disconnects.
    }

    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
        refresh()
    }

    private func scheduleRefresh() {
        // Published values are delivered before their stored properties change.
        Task { @MainActor [weak self] in self?.refresh() }
    }

    private var videoSupported: Bool {
        if #available(iOS 26.4, *) { return configuration?.supportsVideoPlayback == true }
        return false
    }

    private func refresh() {
        guard controller != nil else { return }
        let sources = AppServices.library.sources.sorted {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
            return $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
        update(library, sources: sources, empty: "Henüz kaynak yok", detail: "iPhone'da Kütüphane > + ile video, fotoğraf veya liste ekle.")
        update(favorites, sources: sources.filter(\.isFavorite), empty: "Henüz favori yok", detail: "iPhone kütüphanesinden bir kaynağı favorilere ekle.")
        let names = Set(sources.map(\.group)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        let groupItems = names.prefix(CPListTemplate.maximumItemCount).map { name -> CPListItem in
            let count = sources.filter { $0.group == name }.count
            let item = CPListItem(text: name, detailText: "\(count) kaynak", image: UIImage(systemName: "folder.fill"))
            item.handler = { [weak self] _, completion in
                guard let self, let controller = self.controller else { completion(); return }
                let template = CPListTemplate(title: name, sections: [])
                self.openGroup = (name, template)
                self.update(template, sources: AppServices.library.sources.filter { $0.group == name }, empty: "Grup boş", detail: nil)
                controller.pushTemplate(template, animated: true) { _, error in
                    if let error { AppServices.library.message = error.localizedDescription }
                }
                completion()
            }
            return item
        }
        groups.updateSections([CPListSection(items: groupItems.isEmpty ? [message("Henüz grup yok", "İçe aktardığın kaynakların grupları burada görünür.")] : groupItems)])
        if let openGroup {
            update(openGroup.template, sources: sources.filter { $0.group == openGroup.name }, empty: "Grup boş", detail: nil)
        }
        refreshPlayback()
        refreshDiscover()
    }

    private func update(_ template: CPListTemplate, sources: [MediaSource], empty: String, detail: String?) {
        let items = sources.prefix(CPListTemplate.maximumItemCount).map { source -> CPListItem in
            let item = CPListItem(text: source.title, detailText: source.group,
                                  image: UIImage(systemName: source.mediaKind == .photo ? "photo" : "play.rectangle"))
            item.isPlaying = AppServices.playback.source?.id == source.id && AppServices.playback.player.rate > 0
            if #available(iOS 26.4, *) {
                item.playbackConfiguration = CPPlaybackConfiguration(preferredPresentation: videoSupported ? .video : .audio,
                    playbackAction: .play, elapsedTime: CMTime(seconds: source.resumeTime, preferredTimescale: 600), duration: .zero)
            }
            item.handler = { [weak self] _, completion in
                self?.savePosition()
                AppServices.playback.open(source)
                self?.scheduleRefresh()
                completion()
            }
            return item
        }
        template.updateSections([CPListSection(items: items.isEmpty ? [message(empty, detail)] : items)])
    }

    private func refreshPlayback() {
        let service = AppServices.playback
        var items: [CPListItem] = []
        if let source = service.source {
            items.append(message(source.title, service.loading ? "Kaynak açılıyor…" : "Seçili kaynak"))
            items.append(action("Oynat", "play.fill") { service.player.play() })
            items.append(action("Duraklat", "pause.fill") { service.player.pause() })
            items.append(action("Durdur", "stop.fill") { [weak self] in self?.savePosition(); service.stop() })
            if let failure = service.failure { items.append(message("Kaynak açılamadı", failure)) }
        } else {
            items.append(message("Bir kaynak seç", "Kütüphane veya Favoriler sekmesinden oynatmayı başlat."))
        }
        items.append(message(videoSupported ? "Video destekli oturum" : "Ses oturumu",
                             videoSupported ? "Video kullanılabilirliğini iOS ve araç belirler." : "Bu bağlantıda video desteği bildirilmedi."))
        items.append(message("Web tarayıcısı", "Keşfet sekmesinden tarayıcı durumunu ve site kısayollarını görebilirsin."))
        playback.updateSections([CPListSection(items: items)])
    }

    private func refreshDiscover() {
        let status = browserLink.connected
            ? browserGate.status
            : "Araç tarayıcı ekranı bağlanmadı. Bu iOS / araç / imzalama profili tarayıcı penceresini açmamış olabilir."
        let browser = CPListItem(text: "AutoPulse TV · Tarayıcı",
                                 detailText: browserGate.browserEnabled && browserLink.connected ? "Enabled · Park onaylandı" : "Disabled · " + status,
                                 image: UIImage(systemName: "globe"))
        browser.handler = { [weak self] _, completion in
            self?.showBrowserStatus()
            completion()
        }
        let shortcuts = WebShortcut.defaults.map { shortcut -> CPListItem in
            let item = CPListItem(text: shortcut.title, detailText: "Park hâlinde araç tarayıcısında aç",
                                  image: UIImage(systemName: shortcut.symbol))
            item.handler = { [weak self] _, completion in
                guard let self else { completion(); return }
                // Keep entries visible; enforce the lock at the navigation boundary.
                guard true, self.browserGate.browserEnabled, self.browserLink.connected else {
                    self.showBrowserStatus()
                    completion()
                    return
                }
                self.browserLink.address = URL(string: shortcut.address)
                completion()
            }
            return item
        }
        discover.updateSections([CPListSection(items: [browser]), CPListSection(items: shortcuts, header: "Hızlı erişim", sectionIndexTitle: nil)])
    }

    private func showBrowserStatus() {
        let canConfirm = browserLink.connected && browserGate.stationary && !browserGate.confirmed
        var actions = [CPAlertAction(title: "Tamam", style: .cancel) { [weak self] _ in
            self?.controller?.dismissTemplate(animated: true, completion: nil)
        }]
        if canConfirm {
            actions.insert(CPAlertAction(title: "Park ettim", style: .default) { [weak self] _ in
                guard let self else { return }
                if self.browserGate.stationary && self.browserLink.connected { self.browserGate.confirmed = true }
                self.controller?.dismissTemplate(animated: true, completion: nil)
            }, at: 0)
        }
        let detail = browserLink.connected ? browserGate.status
            : "iOS araç tarayıcı penceresini bağlamadı. Park onayı tek başına bu pencereyi açamaz."
        controller?.presentTemplate(CPAlertTemplate(titleVariants: ["Tarayıcı", detail], actions: actions), animated: true, completion: nil)
    }

    private func message(_ title: String, _ detail: String?) -> CPListItem {
        let item = CPListItem(text: title, detailText: detail)
        item.isEnabled = false
        return item
    }

    private func action(_ title: String, _ symbol: String, perform: @escaping () -> Void) -> CPListItem {
        let item = CPListItem(text: title, detailText: nil, image: UIImage(systemName: symbol))
        item.handler = { [weak self] _, completion in
            perform()
            self?.scheduleRefresh()
            completion()
        }
        return item
    }

    private func savePosition() {
        if let source = AppServices.playback.source {
            AppServices.library.recordPlayback(source.id, seconds: AppServices.playback.position)
        }
    }
}
