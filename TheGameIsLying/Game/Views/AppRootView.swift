import SwiftUI

struct AppRootView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch session.route {
            case .home:
                HomeView()
            case .play:
                GameplayView()
            case .result(let won):
                ResultView(won: won)
            case .finished:
                FinishedView()
            }
        }
        .animation(
            ProcessInfo.processInfo.arguments.contains("-ui-testing") ? nil : .easeInOut(duration: 0.2),
            value: routeKey
        )
        .preferredColorScheme(.dark)
    }

    private var routeKey: String {
        switch session.route {
        case .home: return "home"
        case .play: return "play"
        case .result(let won): return won ? "win" : "lose"
        case .finished: return "finished"
        }
    }
}

struct FinishedView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("YOU SURVIVED.")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Text("Don't get comfortable.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.muted)
            Spacer()
            PrimaryButton(title: "PLAY AGAIN") {
                session.playAgain()
            }
            .accessibilityIdentifier("finished.again")
            Button("HOME") { session.goHome() }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.muted)
                .frame(minHeight: 44)
                .padding(.bottom, 36)
                .accessibilityIdentifier("finished.home")
                .accessibilityLabel("Home")
        }
        .padding(.horizontal, 28)
        .safeAreaPadding(.vertical)
    }
}
