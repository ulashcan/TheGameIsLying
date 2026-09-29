import SwiftUI

struct HomeView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            GlitchTitle(text: "THE GAME IS LYING")
                .padding(.horizontal, 20)
                .accessibilityLabel("The Game Is Lying")
                .accessibilityAddTraits(.isHeader)
            PrimaryButton(title: "PLAY") {
                session.audio.play(.tap)
                session.playCampaign()
            }
            .accessibilityIdentifier("home.play")
            .padding(.top, 36)
            Spacer()
            Text("Can you trust it?")
                .font(.system(size: 14, weight: .medium, design: .default))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
                .accessibilityLabel("Can you trust it?")
            if session.dailyUnlocked {
                Button {
                    session.audio.play(.tap)
                    session.playDaily()
                } label: {
                    Text("TODAY'S LIE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.muted.opacity(0.9))
                        .frame(minWidth: 160, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("home.daily")
                .accessibilityLabel("Today's lie")
                .padding(.top, 14)
            }
            Spacer().frame(height: 36)
        }
        .padding(.horizontal, 28)
        .safeAreaPadding(.vertical)
    }
}

struct GlitchTitle: View {
    let text: String

    var body: some View {
        ZStack {
            Text(text)
                .foregroundStyle(Theme.red.opacity(0.55))
                .offset(x: -2, y: 1)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(Theme.blue.opacity(0.45))
                .offset(x: 2, y: -1)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(.white)
        }
        .font(.system(size: 34, weight: .black))
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.7)
        .lineLimit(2)
    }
}

struct PrimaryButton: View {
    let title: String
    var color: Color = Theme.red
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            pressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { pressed = false }
            action()
        }) {
            Text(title)
                .font(.system(size: 22, weight: .black))
                .tracking(1.4)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .frame(height: 64)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .scaleEffect(pressed ? 0.96 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: pressed)
        .buttonStyle(.plain)
    }
}
