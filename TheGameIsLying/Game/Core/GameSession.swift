import Foundation
import Observation

@Observable
@MainActor
final class GameSession {
    var route: AppRoute = .home
    var player: PlayerState
    var level: Level
    var visibleInstruction: String
    var hintVisible = false
    var grantedHint: String?
    var flash: ScreenFlash?
    var shakeToken = 0
    var attemptID = UUID()
    var resultMessage = ""
    var isDaily = false
    var adsBusy = false

    var dailyUnlocked: Bool {
        player.currentLevelID > 3 || player.campaignWon
    }

    let ads: AdManager
    let analytics: AnalyticsClient
    let audio: AudioService
    let premium = PremiumFlags()

    private let engine = GameEngine()
    private let store: PersistenceService
    private var resultConsumed = false
    private var ignoreChromeTapsUntil = Date.distantPast
    private var waitTask: Task<Void, Never>?
    private var waitStartedAt = Date()
    private var waitFrozenElapsed: TimeInterval = 0
    private var waitPaused = false

    static func makeForLaunch() -> GameSession {
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            let suite = "ui-testing.thegameislying"
            let defaults = UserDefaults(suiteName: suite) ?? .standard
            defaults.removePersistentDomain(forName: suite)
            return GameSession(
                store: PersistenceService(defaults: defaults),
                ads: AdManager(adsEnabled: false)
            )
        }
        return GameSession()
    }

    init(
        store: PersistenceService = PersistenceService(),
        ads: AdManager = AdManager(),
        analytics: AnalyticsClient = AnalyticsClient(),
        audio: AudioService = AudioService()
    ) {
        self.store = store
        self.ads = ads
        self.analytics = analytics
        self.audio = audio
        let loaded = store.load()
        self.player = loaded
        let start = LevelCatalog.level(id: loaded.currentLevelID) ?? LevelCatalog.all[0]
        self.level = start
        self.visibleInstruction = start.instruction
        analytics.track(.sessionStarted)
    }

    func playCampaign() {
        isDaily = false
        if player.campaignWon {
            route = .finished
            return
        }
        level = LevelCatalog.level(id: player.currentLevelID) ?? LevelCatalog.all[0]
        route = .play
        startAttempt()
    }

    func playDaily() {
        guard dailyUnlocked else { return }
        isDaily = true
        let id = DailyChallengeService.levelID(for: Date())
        level = LevelCatalog.level(id: id) ?? LevelCatalog.all[0]
        route = .play
        startAttempt()
        analytics.track(.dailyChallengeStarted(level.id))
    }

    func submit(_ action: PlayerAction, elapsed: TimeInterval) {
        guard route == .play else { return }
        if Date() < ignoreChromeTapsUntil, action == .tapBackground {
            return
        }
        let evalState = isDaily ? PlayerState.fresh : player
        let result = engine.outcome(for: action, level: level, state: evalState, elapsed: elapsed)
        guard result != .stillPlaying else { return }
        waitTask?.cancel()
        waitTask = nil

        if !isDaily {
            player = engine.apply(outcome: result, action: action, level: level, state: player)
            store.save(player)
        }

        resultConsumed = false
        resultMessage = result == .win ? level.successMessage : level.failureMessage
        flash = result == .win ? .success : .fail
        if result == .lose { shakeToken += 1 }
        audio.play(result == .win ? .success : .fail)

        if result == .win {
            analytics.track(.levelCompleted(level.id))
            if isDaily {
                analytics.track(.dailyChallengeCompleted(level.id))
            }
        } else {
            analytics.track(.levelFailed(level.id))
        }

        route = .result(won: result == .win)
    }

    func retry() {
        analytics.track(.retryClicked(level.id))
        if !isDaily {
            player.retryCount += 1
            store.save(player)
        }
        route = .play
        startAttempt()
    }

    func nextLevel() {
        guard !resultConsumed else { return }
        guard case .result = route else { return }
        resultConsumed = true
        if isDaily {
            route = .home
            return
        }
        if player.campaignWon {
            route = .finished
            return
        }
        level = LevelCatalog.level(id: player.currentLevelID) ?? level
        route = .play
        startAttempt()
    }

    func requestHint() async {
        guard !adsBusy else { return }
        adsBusy = true
        let levelID = level.id
        analytics.track(.hintClicked(levelID))
        let granted = await ads.showRewarded(reward: "hint")
        adsBusy = false
        guard granted else { return }
        if ads.adsEnabled {
            analytics.track(.rewardedAdCompleted(reward: "hint"))
        }
        guard level.id == levelID else { return }
        grantedHint = level.hint
        if route == .play {
            hintVisible = true
        }
    }

    func continueAfterFail() async {
        guard ads.adsEnabled else { return }
        guard !adsBusy else { return }
        adsBusy = true
        let levelID = level.id
        let granted = await ads.showRewarded(reward: "continue")
        adsBusy = false
        guard granted else { return }
        guard case .result(won: false) = route, level.id == levelID else { return }
        analytics.track(.rewardedAdCompleted(reward: "continue"))
        if !isDaily {
            player = engine.skip(level: level, state: player)
            store.save(player)
        }
        resultConsumed = false
        nextLevel()
    }

    func goHome() {
        waitTask?.cancel()
        waitTask = nil
        resultConsumed = true
        adsBusy = false
        route = .home
    }

    func playAgain() {
        store.reset()
        player = .fresh
        isDaily = false
        playCampaign()
    }

    func updateInstructionIfNeeded(elapsed: TimeInterval) {
        if let delayed = level.delayedInstruction, elapsed >= level.instructionDelay {
            visibleInstruction = delayed
        }
    }

    func currentElapsed() -> TimeInterval {
        if waitPaused { return waitFrozenElapsed }
        return waitFrozenElapsed + Date().timeIntervalSince(waitStartedAt)
    }

    func setSceneActive(_ active: Bool) {
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") { return }
        if !active, !waitPaused {
            waitFrozenElapsed = currentElapsed()
            waitPaused = true
        } else if active, waitPaused {
            waitStartedAt = Date()
            waitPaused = false
        }
    }

    func endSession() {
        waitTask?.cancel()
        waitTask = nil
        analytics.track(.sessionFinished)
    }

    private func startAttempt() {
        visibleInstruction = level.instruction
        hintVisible = false
        grantedHint = nil
        flash = nil
        resultConsumed = false
        attemptID = UUID()
        ignoreChromeTapsUntil = Date().addingTimeInterval(0.55)
        waitPaused = false
        waitFrozenElapsed = 0
        waitStartedAt = Date()
        analytics.track(.levelStarted(level.id))
        audio.play(.suspense)
        startWaitClock()
    }

    private func startWaitClock() {
        waitTask?.cancel()
        let attempt = attemptID
        let duration = level.waitDuration
        waitTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.attemptID == attempt, self.route == .play else { return }
                if !self.waitPaused {
                    let elapsed = self.currentElapsed()
                    self.updateInstructionIfNeeded(elapsed: elapsed)
                    if elapsed >= duration {
                        self.submit(.timeout, elapsed: elapsed)
                        return
                    }
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
}
