import SwiftUI

@main
struct ParkPlayApp: App {
    @StateObject private var library = AppServices.library
    @StateObject private var playback = AppServices.playback
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .environmentObject(playback)
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
enum AppServices {
    static let library = LibraryStore()
    static let playback = PlaybackController()
}
