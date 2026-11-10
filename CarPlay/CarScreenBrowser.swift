import UIKit
import WebKit

/// Araç ekranını kendi penceremizle kaplar.
/// CPWindow yalnız navigasyon yetkisiyle gelir; ses uygulamaları bu yolu kullanır.
@MainActor
final class CarScreenOverlay {
    private var window: UIWindow?
    private var surface: CarBrowserSurface?
    private var observers: [NSObjectProtocol] = []

    private var carScreen: UIScreen? {
        UIScreen.screens.first { $0.traitCollection.userInterfaceIdiom == .carPlay }
    }

    var isAttached: Bool { window != nil }

    func start() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIScreen.didConnectNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.attach() }
        })
        observers.append(center.addObserver(forName: UIScreen.didDisconnectNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.carScreen == nil else { return }
                self.detach()
            }
        })
        attach()
    }

    func stop() {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        detach()
    }

    private func attach() {
        guard window == nil, let screen = carScreen else { return }
        let surface = CarBrowserSurface()
        surface.onClose = { [weak self] in self?.detach() }
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.windowLevel = .normal + 1
        window.backgroundColor = .black
        window.rootViewController = surface
        window.isHidden = false
        window.makeKeyAndVisible()
        self.window = window
        self.surface = surface
        surface.load(CarBrowserLink.shared.address?.absoluteString ?? WebShortcut.defaults.first?.address ?? "https://m.youtube.com")
        CarBrowserLink.shared.connected = true
    }

    private func detach() {
        guard window != nil else { return }
        CarBrowserLink.shared.connected = false
        CarBrowserLink.shared.address = nil
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        surface = nil
    }

    func open(_ address: String) {
        if window == nil { attach() }
        surface?.load(address)
    }
}

@MainActor
final class CarBrowserSurface: UIViewController, WKNavigationDelegate {
    private let webView: WKWebView
    private let progress = UIProgressView(progressViewStyle: .bar)
    private let hostLabel = UILabel()
    private var observations: [NSKeyValueObservation] = []
    var onClose: (() -> Void)?

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsAirPlayForMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"
        webView.isInspectable = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let bar = UIStackView()
        bar.axis = .horizontal
        bar.spacing = 12
        bar.alignment = .center
        bar.isLayoutMarginsRelativeArrangement = true
        bar.layoutMargins = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        bar.translatesAutoresizingMaskIntoConstraints = false

        bar.addArrangedSubview(button("chevron.left") { [weak self] in self?.back() })
        bar.addArrangedSubview(button("arrow.clockwise") { [weak self] in self?.webView.reload() })
        bar.addArrangedSubview(button("house") { [weak self] in self?.goHome() })

        hostLabel.font = .preferredFont(forTextStyle: .footnote)
        hostLabel.textColor = .secondaryLabel
        hostLabel.lineBreakMode = .byTruncatingMiddle
        hostLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        bar.addArrangedSubview(hostLabel)

        bar.addArrangedSubview(button("xmark") { [weak self] in self?.onClose?() })

        progress.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        view.addSubview(progress)
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 44),
            progress.topAnchor.constraint(equalTo: bar.bottomAnchor),
            progress.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: progress.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        observations.append(webView.observe(\.estimatedProgress) { [weak self] webView, _ in
            Task { @MainActor in
                self?.progress.progress = Float(webView.estimatedProgress)
                self?.progress.isHidden = webView.estimatedProgress >= 1
            }
        })
        observations.append(webView.observe(\.url) { [weak self] webView, _ in
            Task { @MainActor in self?.hostLabel.text = webView.url?.host ?? webView.url?.absoluteString }
        })
    }

    private func button(_ symbol: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system, primaryAction: UIAction { _ in action() })
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.accessibilityLabel = ["chevron.left": "Geri", "arrow.clockwise": "Yenile", "house": "Ana sayfa", "xmark": "Kapat"][symbol]
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.tintColor = .label
        return button
    }

    func load(_ address: String) {
        guard let url = URL(string: address) else { return }
        loadViewIfNeeded()
        CarBrowserLink.shared.address = url
        webView.load(URLRequest(url: url))
    }

    func back() {
        if webView.canGoBack { webView.goBack() }
    }

    private func goHome() {
        if let address = CarBrowserLink.shared.address { load(address.absoluteString) }
        else if let first = WebShortcut.defaults.first { load(first.address) }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progress.isHidden = true
    }
}
