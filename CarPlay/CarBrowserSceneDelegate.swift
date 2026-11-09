import SwiftUI
import UIKit
import CoreLocation
import Combine
import OSLog

// This raw role is used by existing CarPlay browsers, but is not a public
// UISceneSession.Role member. Availability depends on iOS and the signed profile.
enum CarBrowserScene {
    static let role = UISceneSession.Role(rawValue: "UIWindowSceneSessionRoleCarPlay")
}

@MainActor
final class CarBrowserLink: ObservableObject {
    static let shared = CarBrowserLink()
    @Published var connected = false
    @Published var address: URL?
}

// Ham rol build 5'te devre dışı, A/B testi için geri açılacak.
final class AutoPulseAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: session.role)
        if session.role == CarBrowserScene.role {
            configuration.sceneClass = UIWindowScene.self
            configuration.delegateClass = CarBrowserSceneDelegate.self
        }
        return configuration
    }
}

@MainActor
final class CarBrowserSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let gate = CarBrowserParkGate.shared

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard session.role == CarBrowserScene.role, let scene = scene as? UIWindowScene else { return }
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "AutoPulseTV", category: "CarBrowser")
            .info("Car browser window connected")
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: CarBrowserScreen(gate: gate))
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidBecomeActive(_ scene: UIScene) { gate.start() }
    func sceneWillResignActive(_ scene: UIScene) { gate.stop() }
    func sceneDidDisconnect(_ scene: UIScene) {
        gate.stop()
        CarBrowserLink.shared.address = nil
        window = nil
    }
}

@MainActor
final class CarBrowserParkGate: NSObject, ObservableObject {
    static let shared = CarBrowserParkGate()
    var browserEnabled: Bool { true }
    @Published private(set) var stationary = true
    @Published var confirmed = true
    @Published private(set) var status = "Park kontrolü için konum izni ve güncel hız bilgisi gerekiyor."
    private let manager = CLLocationManager()
    private var timer: Timer?
    private var lastFix: Date?
    private var stationarySince: Date?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start() {
        guard timer == nil else { return }
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        manager.startUpdatingLocation()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.lastFix.map({ Date().timeIntervalSince($0) > 5 }) ?? true {
                    self.lock("Güncel hız bilgisi bekleniyor. Tarayıcı kilitli.")
                }
            }
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        manager.stopUpdatingLocation()
        lastFix = nil
        lock("Tarayıcıyı açmak için araç durmalı ve park onayı verilmelidir.")
    }

    private func lock(_ reason: String) {
        stationary = false
        confirmed = false
        stationarySince = nil
        status = reason
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let fix = locations.last, abs(fix.timestamp.timeIntervalSinceNow) < 5,
              fix.horizontalAccuracy >= 0, fix.horizontalAccuracy <= 30,
              fix.speedAccuracy >= 0, fix.speedAccuracy <= 1, fix.speed >= 0 else {
            lock("Hız doğrulanamıyor. Tarayıcı kilitli."); return
        }
        lastFix = fix.timestamp
        guard fix.speed < 0.3 else { lock("Araç hareket ediyor. Tarayıcı kilitli."); return }
        if stationarySince == nil { stationarySince = fix.timestamp }
        stationary = fix.timestamp.timeIntervalSince(stationarySince ?? fix.timestamp) >= 10
        status = stationary ? "Araç duruyor. Yalnız park hâlindeysen devam et." : "Aracın durduğu doğrulanıyor…"
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lock("Konum alınamadı. Tarayıcı kilitli.")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            lock("iPhone Ayarlar bölümünden konum izni ver. Tarayıcı kilitli.")
        }
    }
}
extension CarBrowserParkGate: @preconcurrency CLLocationManagerDelegate {}

/*

private struct CarBrowserScreen: View {
    @ObservedObject var gate: CarBrowserParkGate

    var body: some View {
        Group {
            if gate.browserEnabled {
                ParkedBrowserContent()
                    .overlay(alignment: .topTrailing) {
                        Button("Kilitle", systemImage: "lock.fill") { gate.confirmed = false }
                            .buttonStyle(.borderedProminent).padding(8)
                    }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "parkingsign.circle.fill").font(.system(size: 48))
                    Text("Park hâlinde tarayıcı").font(.title2.bold())
                    Text(gate.status).multilineTextAlignment(.center)
                    Button("Park ettim, tarayıcıyı aç") { gate.confirmed = true }
                        .buttonStyle(.borderedProminent).disabled(!gate.stationary)
                    Text("Hız kontrolü vitesin P konumunu tespit etmez.").font(.footnote)
                }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black).foregroundStyle(.white)
            }
        }.preferredColorScheme(.dark).tint(.mint)
    }
}
*/

struct CarBrowserScreen: View {
    @ObservedObject var gate: CarBrowserParkGate

    var body: some View {
        ParkedBrowserContent()
            .preferredColorScheme(.dark)
            .tint(.mint)
    }
}


private struct ParkedBrowserContent: View {
    @ObservedObject private var link = CarBrowserLink.shared
    @State private var destination: WebDestination?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Telefondan adres gönder veya aşağıdan seç")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                shortcut("YouTube", symbol: "play.rectangle.fill", address: "https://www.youtube.com")
                shortcut("Google", symbol: "magnifyingglass", address: "https://www.google.com")
                shortcut("Abonelikler", symbol: "rectangle.stack.fill", address: "https://www.youtube.com/feed/subscriptions")
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.035, green: 0.055, blue: 0.10))
        .foregroundStyle(.white)
        .onReceive(link.$address) { url in
            destination = url.map { WebDestination(url: $0) }
        }
        .fullScreenCover(item: $destination) { BrowserScreen(url: $0.url) }
    }

    private func shortcut(_ title: String, symbol: String, address: String) -> some View {
        Button {
            CarBrowserLink.shared.address = URL(string: address)
        } label: {
            Label(title, systemImage: symbol)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, minHeight: 64)
        }
        .buttonStyle(.borderedProminent)
        .tint(.mint)
        .foregroundStyle(.black)
    }
}
