import Foundation

/// Central ads entry point. No production ad unit IDs live here.
enum AdConfig {
    /// Flip to true when a real SDK is wired. MVP stays playable offline.
    static var adsEnabled = false
    static let testAppID = "ca-app-pub-3940256099942544~1458002511"
    static let testRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"
}

protocol AdServing {
    func showRewarded(reward: String) async -> Bool
}

struct AdManager: AdServing {
    var adsEnabled: Bool = AdConfig.adsEnabled
    /// Used by tests and the local stub. Real SDK would ignore this.
    var simulatedGrant: Bool = true
    var simulatedDelayNanoseconds: UInt64 = 700_000_000

    var hintCTA: String {
        adsEnabled ? "WATCH AD → GET HINT" : "GET HINT"
    }

    var continueCTA: String {
        adsEnabled ? "WATCH AD → CONTINUE" : "CONTINUE"
    }

    var hintAccessibility: String {
        adsEnabled ? "Watch ad to get hint" : "Get hint"
    }

    var offersRewardedContinue: Bool { adsEnabled }

    func showRewarded(reward: String) async -> Bool {
        _ = reward
        if !adsEnabled {
            return true
        }
        if simulatedDelayNanoseconds > 0 {
            do {
                try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
            } catch {
                return false
            }
        }
        return simulatedGrant
    }
}
