import SwiftUI

struct ResultView: View {
    @Environment(GameSession.self) private var session
    let won: Bool

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Text(won ? successTitle : "GAME OVER")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(won ? "result.success" : "result.fail")
            Text(session.resultMessage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .accessibilityIdentifier("result.message")
            Spacer()
            if won {
                PrimaryButton(title: "NEXT LEVEL") {
                    session.audio.play(.tap)
                    session.nextLevel()
                }
                .accessibilityIdentifier("result.next")
            } else {
                PrimaryButton(title: "TRY AGAIN") {
                    session.audio.play(.tap)
                    session.retry()
                }
                .accessibilityIdentifier("result.retry")
                if session.ads.offersRewardedContinue {
                    Button {
                        Task { await session.continueAfterFail() }
                    } label: {
                        Text(session.adsBusy ? "LOADING..." : session.ads.continueCTA)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.muted)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .padding(.top, 8)
                    .accessibilityIdentifier("result.continue")
                    .accessibilityLabel("Watch ad to continue")
                }
            }
            Button {
                session.goHome()
            } label: {
                Text("HOME")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.muted)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .padding(.bottom, 28)
            .accessibilityIdentifier("result.home")
            .accessibilityLabel("Home")
        }
        .padding(.horizontal, 28)
        .safeAreaPadding(.vertical)
        .sensoryFeedback(won ? .success : .error, trigger: won)
        .task(id: won) {
            guard won else { return }
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") { return }
            do {
                try await Task.sleep(nanoseconds: 800_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            session.nextLevel()
        }
    }

    private var successTitle: String {
        session.level.id == 30 || session.resultMessage.contains("FINALLY") || session.resultMessage.contains("YOU STAYED") ? "YOU GOT ME." : session.level.id % 2 == 0 ? "YOU GOT ME." : "NICE."
    }
}
