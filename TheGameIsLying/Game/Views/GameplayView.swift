import SwiftUI

struct GameplayView: View {
    @Environment(GameSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .title) private var instructionSize: CGFloat = 34
    @State private var startedAt = Date()
    @State private var pressedID: String?
    @State private var frozenElapsed: TimeInterval = 0
    @State private var isFrozen = false

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 720
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { tapBackground() }
                    .accessibilityHidden(true)

                VStack(spacing: compact ? 18 : 28) {
                    Button(action: tapLevelTitle) {
                        Text(session.level.displayTitle)
                            .font(.system(size: session.level.id == 7 || session.level.id == 30 ? 22 : 16, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(Theme.muted)
                            .padding(.top, 12)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("game.levelTitle")
                    .accessibilityLabel(session.level.displayTitle)

                    Spacer(minLength: 8)

                    Text(session.visibleInstruction)
                        .font(.system(size: compact ? max(24, instructionSize * 0.82) : instructionSize, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.65)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture { tapInstruction() }
                        .accessibilityIdentifier("game.instruction")
                        .accessibilityLabel(session.visibleInstruction)

                    buttonStack(compact: compact)

                    Spacer(minLength: 8)

                    if session.hintVisible, let hint = session.grantedHint {
                        Text(hint)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .transition(.opacity)
                    }

                    Button {
                        Task { await session.requestHint() }
                    } label: {
                        Text(session.adsBusy ? "LOADING..." : session.ads.hintCTA)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.muted)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                    }
                    .padding(.bottom, 24)
                    .disabled(session.adsBusy || session.hintVisible)
                    .accessibilityIdentifier("game.hint")
                    .accessibilityLabel(session.ads.hintAccessibility)
                }
                .padding(.horizontal, 24)
                .safeAreaPadding(.top)
                .safeAreaPadding(.bottom)
                .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .modifier(ShakeEffect(shakes: session.shakeToken))
        .animation(.linear(duration: 0.28), value: session.shakeToken)
        .overlay(flashOverlay)
        .sensoryFeedback(.impact(weight: .heavy), trigger: session.shakeToken)
        .task(id: session.attemptID) {
            startedAt = Date()
            isFrozen = false
            frozenElapsed = 0
            while !Task.isCancelled {
                if !isFrozen {
                    let elapsed = Date().timeIntervalSince(startedAt)
                    session.updateInstructionIfNeeded(elapsed: elapsed)
                    if elapsed >= session.level.waitDuration {
                        session.submit(.timeout, elapsed: elapsed)
                        break
                    }
                }
                do {
                    try await Task.sleep(nanoseconds: 50_000_000)
                } catch {
                    break
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            session.setSceneActive(phase == .active)
            if phase == .background {
                frozenElapsed = max(0, Date().timeIntervalSince(startedAt))
                isFrozen = true
            } else if phase == .active, isFrozen {
                startedAt = Date().addingTimeInterval(-frozenElapsed)
                isFrozen = false
            }
        }
    }

    @ViewBuilder
    private func buttonStack(compact: Bool) -> some View {
        let buttons = session.level.buttons
        if buttons.isEmpty {
            Color.clear.frame(height: compact ? 80 : 120)
        } else if buttons.count == 1, let button = buttons.first {
            GameButton(button: button, compact: compact, pressed: pressedID == button.id) {
                tapButton(button.id)
            }
        } else if buttons.count >= 3 {
            VStack(spacing: 12) {
                ForEach(buttons) { button in
                    GameButton(button: button, compact: true, pressed: pressedID == button.id) {
                        tapButton(button.id)
                    }
                }
            }
        } else {
            HStack(spacing: 16) {
                ForEach(buttons) { button in
                    GameButton(button: button, compact: compact, pressed: pressedID == button.id) {
                        tapButton(button.id)
                    }
                }
            }
        }
    }

    private var flashOverlay: some View {
        Group {
            if session.flash == .success {
                Color.white.opacity(0.18)
            } else if session.flash == .fail {
                Theme.red.opacity(0.22)
            } else {
                Color.clear
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.18), value: session.flash)
    }

    private func tapButton(_ id: String) {
        pressedID = id
        session.audio.play(.tap)
        session.submit(.tapButton(id: id), elapsed: session.currentElapsed())
    }

    private func tapLevelTitle() {
        session.audio.play(.tap)
        session.submit(.tapHidden, elapsed: session.currentElapsed())
    }

    private func tapInstruction() {
        if session.level.hiddenZone == .instruction, case .hidden = session.level.win {
            session.audio.play(.tap)
            session.submit(.tapHidden, elapsed: session.currentElapsed())
        } else {
            session.submit(.tapBackground, elapsed: session.currentElapsed())
        }
    }

    private func tapBackground() {
        session.submit(.tapBackground, elapsed: session.currentElapsed())
    }
}

struct GameButton: View {
    let button: LevelButton
    var compact: Bool
    var pressed: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(button.title)
                .font(.system(size: button.hue == .red || button.hue == .blue ? 20 : 16, weight: .black))
                .foregroundStyle(Theme.foreground(for: button.hue))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .frame(height: compact ? 92 : 118)
                .background(Theme.fill(for: button.hue))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(button.hue == .black ? 0.35 : 0), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Theme.fill(for: button.hue).opacity(0.35), radius: pressed ? 2 : 12, y: pressed ? 2 : 8)
        }
        .scaleEffect(pressed ? 0.94 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: pressed)
        .buttonStyle(.plain)
        .accessibilityIdentifier("game.button.\(button.id)")
        .accessibilityLabel(button.title)
        .accessibilityAddTraits(.isButton)
    }
}

struct ShakeEffect: ViewModifier {
    var shakes: Int

    func body(content: Content) -> some View {
        content
            .offset(x: shakes == 0 ? 0 : 0)
            .modifier(ShakeAnim(animatableData: CGFloat(shakes)))
    }
}

private struct ShakeAnim: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * 2) * 8
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
