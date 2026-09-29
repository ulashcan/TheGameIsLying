import Foundation

enum ButtonHue: String, Codable, Equatable {
    case red
    case blue
    case white
    case black
    case gray
    case green
}

enum HiddenZone: Equatable {
    case levelTitle
    case instruction
}

struct LevelButton: Identifiable, Equatable {
    let id: String
    let title: String
    let hue: ButtonHue
}

enum TimeoutRule: Equatable {
    case win
    case lose
}

enum WinRule: Equatable {
    case wait
    case tap(String)
    case hidden
    case tapWhenLastColor(is: String, then: String, otherwise: String)
    case tapOppositeOfLastColor(fallback: String)
    case confirmPressed(id: String, yes: String, no: String)
    case tapByTrust(ifTrustedMajority: String, ifSkeptical: String)
    case tapIfTrustedLast(then: String, otherwise: String)
}

enum LiteralIntent: Equatable {
    case wait
    case tap(String)
    case avoid(String)
    case tapLastColor
}

enum PlayerAction: Equatable {
    case tapButton(id: String)
    case tapBackground
    case tapHidden
    case timeout
}

enum LevelOutcome: Equatable {
    case stillPlaying
    case win
    case lose
}

struct Level: Identifiable, Equatable {
    let id: Int
    let instruction: String
    let delayedInstruction: String?
    let instructionDelay: TimeInterval
    let buttons: [LevelButton]
    let waitDuration: TimeInterval
    let timeoutRule: TimeoutRule
    let earlyTapFailsUntil: TimeInterval
    let win: WinRule
    let literal: LiteralIntent
    let successMessage: String
    let failureMessage: String
    let hint: String
    var hiddenZone: HiddenZone = .levelTitle

    var displayTitle: String {
        String(format: "LEVEL %02d", id)
    }
}

struct PlayerState: Codable, Equatable {
    var currentLevelID: Int
    var completedIDs: [Int]
    var failCountByLevel: [String: Int]
    var lastButtonID: String?
    var lastColorID: String?
    var pressedIDs: [String]
    var trustedCount: Int
    var ignoredCount: Int
    var trustedLast: Bool
    var retryCount: Int
    var skippedIDs: [Int]
    var campaignWon: Bool

    static let fresh = PlayerState(
        currentLevelID: 1,
        completedIDs: [],
        failCountByLevel: [:],
        lastButtonID: nil,
        lastColorID: nil,
        pressedIDs: [],
        trustedCount: 0,
        ignoredCount: 0,
        trustedLast: false,
        retryCount: 0,
        skippedIDs: [],
        campaignWon: false
    )

    func didPress(_ id: String) -> Bool {
        pressedIDs.contains(id)
    }

    var trustsMoreThanDoubts: Bool {
        trustedCount >= ignoredCount
    }
}

enum ScreenFlash: Equatable {
    case success
    case fail
}

enum AppRoute: Equatable {
    case home
    case play
    case result(won: Bool)
    case finished
}
