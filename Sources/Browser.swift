import SwiftUI
import WebKit
import Combine

@MainActor
final class BrowserModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    let webView: WKWebView
    @Published var address = ""
    @Published var title = "Tarayıcı"
    @Published var error: String?
    @Published var progress = 0.0
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var loading = false
    private var observers: [NSKeyValueObservation] = []

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        // No injected scripts, media extraction or playback-obscuring user agents.
        observers = [
            webView.observe(\.url, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.address = view.url?.absoluteString ?? "" }
            },
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.progress = view.estimatedProgress }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.loading = view.isLoading }
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.canGoBack = view.canGoBack }
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.canGoForward = view.canGoForward }
            }
        ]
    }

    func navigate(_ text: String) {
        do {
            let url = try SourceValidation.secureURL(text)
            error = nil
            webView.load(URLRequest(url: url))
        } catch { self.error = error.localizedDescription }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        // Allow standard secure web navigation; never silently execute custom schemes.
        if (try? SourceValidation.secureURL(url.absoluteString)) != nil || url.absoluteString == "about:blank" {
            decisionHandler(.allow)
        } else {
            if navigationAction.targetFrame?.isMainFrame != false {
                error = "Bu bağlantı güvenli web gezintisi için desteklenmiyor."
            }
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title ?? "Tarayıcı"
        error = nil
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        show(error)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { show(error) }
    private func show(_ error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { self.error = error.localizedDescription }
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        error = "Web sayfası durdu. Yenile düğmesiyle tekrar açabilirsin."
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil,
           let url = navigationAction.request.url,
           (try? SourceValidation.secureURL(url.absoluteString)) != nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

struct BrowserScreen: View {
    let url: URL
    @StateObject private var model = BrowserModel()
    @State private var address = ""
    @State private var external: WebDestination?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "lock.shield").foregroundStyle(.mint)
                    TextField("HTTPS adresi", text: $address)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                        .submitLabel(.go).onSubmit { model.navigate(address) }
                        .accessibilityIdentifier("browserAddress")
                    Button { model.navigate(address) } label: { Image(systemName: "arrow.right.circle.fill") }
                        .accessibilityLabel("Adrese git")
                }.padding(12).background(Theme.panel)
                if model.loading { ProgressView(value: model.progress).tint(.mint) }
                if let error = model.error {
                    Text(error).font(.footnote).foregroundStyle(.orange).padding(8)
                }
                WebSurface(model: model)
                HStack(spacing: 24) {
                    Button { model.webView.goBack() } label: { Image(systemName: "chevron.left") }
                        .disabled(!model.canGoBack).accessibilityLabel("Geri")
                    Button { model.webView.goForward() } label: { Image(systemName: "chevron.right") }
                        .disabled(!model.canGoForward).accessibilityLabel("İleri")
                    Button {
                        if model.loading { model.webView.stopLoading() } else { model.webView.reload() }
                    } label: {
                        Image(systemName: model.loading ? "xmark" : "arrow.clockwise")
                    }.accessibilityLabel(model.loading ? "Durdur" : "Yenile")
                    Spacer()
                    Button("Safari") {
                        if let current = model.webView.url { external = WebDestination(url: current) }
                    }.accessibilityLabel("Safari görünümünde aç")
                }.padding().background(Theme.panel)
            }
            .navigationTitle(model.title).navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Bitti") {
                model.webView.stopLoading()
                model.webView.loadHTMLString("", baseURL: nil)
                dismiss()
            } }
            .onAppear {
                if model.webView.url == nil { address = url.absoluteString; model.navigate(address) }
            }
            .onChange(of: model.address) { _, value in address = value }
            .sheet(item: $external) { SafariScreen(url: $0.url).ignoresSafeArea() }
        }.tint(.mint)
    }
}

struct WebSurface: UIViewRepresentable {
    @ObservedObject var model: BrowserModel
    func makeUIView(context: Context) -> WKWebView { model.webView }
    func updateUIView(_ view: WKWebView, context: Context) {}
}
