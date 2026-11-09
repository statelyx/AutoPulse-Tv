import SwiftUI

@main
struct AutoPulseTVApp: App {
    @UIApplicationDelegateAdaptor(AutoPulseAppDelegate.self) private var appDelegate
    @StateObject private var library = AppServices.library
    @StateObject private var playback = AppServices.playback
    @State private var fixturesReady = false
    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if let page = ScreenshotFixtures.page {
                    if fixturesReady { StoreScreenshotFrame(page: page) }
                    else { ProgressView("Örnek medya hazırlanıyor…").task {
                        do {
                            try await ScreenshotFixtures.seed(library)
                            fixturesReady = true
                        }
                        catch { library.message = error.localizedDescription }
                    } }
                } else { RootView() }
                #else
                RootView()
                #endif
            }
                .environmentObject(library)
                .environmentObject(playback)
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
enum AppServices {
    static let library: LibraryStore = {
        #if DEBUG
        if ScreenshotFixtures.page != nil {
            return LibraryStore(fileURL: URL.applicationSupportDirectory.appendingPathComponent("AutoPulseScreenshots/library.json"))
        }
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            return LibraryStore(fileURL: URL.applicationSupportDirectory.appendingPathComponent("AutoPulseUITesting/library.json"))
        }
        #endif
        return LibraryStore()
    }()
    static let playback = PlaybackController()
}
