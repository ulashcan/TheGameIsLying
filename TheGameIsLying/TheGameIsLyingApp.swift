import AVFoundation
import SwiftUI

@main
struct TheGameIsLyingApp: App {
    @State private var session = GameSession.makeForLaunch()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(session)
                .onAppear {
                    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                    try? AVAudioSession.sharedInstance().setActive(true)
                }
        }
    }
}
