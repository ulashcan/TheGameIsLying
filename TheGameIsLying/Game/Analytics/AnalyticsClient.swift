import Foundation
import os

enum AnalyticsEvent: Equatable {
    case sessionStarted
    case sessionFinished
    case levelStarted(Int)
    case levelCompleted(Int)
    case levelFailed(Int)
    case retryClicked(Int)
    case hintClicked(Int)
    case rewardedAdCompleted(reward: String)
    case dailyChallengeStarted(Int)
    case dailyChallengeCompleted(Int)

    var name: String {
        switch self {
        case .sessionStarted: return "session_started"
        case .sessionFinished: return "session_finished"
        case .levelStarted: return "level_started"
        case .levelCompleted: return "level_completed"
        case .levelFailed: return "level_failed"
        case .retryClicked: return "retry_clicked"
        case .hintClicked: return "hint_clicked"
        case .rewardedAdCompleted: return "rewarded_ad_completed"
        case .dailyChallengeStarted: return "daily_challenge_started"
        case .dailyChallengeCompleted: return "daily_challenge_completed"
        }
    }

    var parameters: [String: String] {
        switch self {
        case .sessionStarted, .sessionFinished:
            return [:]
        case .levelStarted(let id),
             .levelCompleted(let id),
             .levelFailed(let id),
             .retryClicked(let id),
             .hintClicked(let id),
             .dailyChallengeStarted(let id),
             .dailyChallengeCompleted(let id):
            return ["level_id": String(id)]
        case .rewardedAdCompleted(let reward):
            return ["reward": reward]
        }
    }
}

protocol AnalyticsProvider {
    func track(_ event: AnalyticsEvent)
}

struct PrintAnalyticsProvider: AnalyticsProvider {
    func track(_ event: AnalyticsEvent) {
        print("[analytics] \(event.name) \(event.parameters)")
    }
}

struct OSLogAnalyticsProvider: AnalyticsProvider {
    private let logger = Logger(subsystem: "com.thegameislying.mvp", category: "analytics")

    func track(_ event: AnalyticsEvent) {
        logger.info("\(event.name, privacy: .public) \(event.parameters.description, privacy: .public)")
    }
}

struct AnalyticsClient {
    var providers: [AnalyticsProvider]

    init(providers: [AnalyticsProvider] = [PrintAnalyticsProvider(), OSLogAnalyticsProvider()]) {
        self.providers = providers
    }

    func track(_ event: AnalyticsEvent) {
        for provider in providers {
            provider.track(event)
        }
    }
}
