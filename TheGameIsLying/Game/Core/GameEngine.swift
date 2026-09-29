import Foundation

struct GameEngine {
    func outcome(
        for action: PlayerAction,
        level: Level,
        state: PlayerState,
        elapsed: TimeInterval
    ) -> LevelOutcome {
        if elapsed < level.earlyTapFailsUntil && action.isTap {
            return .lose
        }

        switch action {
        case .timeout:
            return level.timeoutRule == .win ? .win : .lose
        case .tapHidden:
            if level.win == .hidden { return .win }
            if case .wait = level.win { return .lose }
            return .stillPlaying
        case .tapBackground:
            if case .wait = level.win { return .lose }
            if case .hidden = level.win { return .lose }
            return .stillPlaying
        case .tapButton(let id):
            switch level.win {
            case .wait, .hidden:
                return .lose
            default:
                return expectedButtonID(level: level, state: state) == id ? .win : .lose
            }
        }
    }

    func followedLiteralInstruction(
        action: PlayerAction,
        level: Level,
        state: PlayerState
    ) -> Bool {
        switch (level.literal, action) {
        case (.wait, .timeout):
            return true
        case (.wait, _):
            return false
        case (.avoid(let id), .tapButton(let tapped)):
            return tapped != id
        case (.avoid, .timeout):
            return true
        case (.avoid, .tapBackground), (.avoid, .tapHidden):
            return true
        case (.tap(let id), .tapButton(let tapped)):
            return tapped == id
        case (.tapLastColor, .tapButton(let tapped)):
            return tapped == (state.lastColorID ?? "red")
        case (.tap, _), (.tapLastColor, _):
            return false
        }
    }

    func apply(
        outcome: LevelOutcome,
        action: PlayerAction,
        level: Level,
        state: PlayerState
    ) -> PlayerState {
        var next = state

        if case .tapButton(let id) = action {
            next.lastButtonID = id
            next.pressedIDs.append(id)
            if id == "red" || id == "blue" {
                next.lastColorID = id
            }
        }

        guard outcome != .stillPlaying else { return next }

        if followedLiteralInstruction(action: action, level: level, state: state) {
            next.trustedCount += 1
            next.trustedLast = true
        } else {
            next.ignoredCount += 1
            next.trustedLast = false
        }

        if outcome == .win {
            if !next.completedIDs.contains(level.id) {
                next.completedIDs.append(level.id)
            }
            advance(from: level, state: &next)
        } else {
            let key = String(level.id)
            next.failCountByLevel[key, default: 0] += 1
        }

        return next
    }

    func skip(level: Level, state: PlayerState) -> PlayerState {
        var next = state
        if !next.completedIDs.contains(level.id) {
            next.completedIDs.append(level.id)
        }
        if !next.skippedIDs.contains(level.id) {
            next.skippedIDs.append(level.id)
        }
        advance(from: level, state: &next)
        return next
    }

    private func advance(from level: Level, state: inout PlayerState) {
        if level.id >= LevelCatalog.count {
            state.campaignWon = true
            state.currentLevelID = LevelCatalog.count
            return
        }
        state.currentLevelID = max(state.currentLevelID, level.id + 1)
    }

    private func expectedButtonID(level: Level, state: PlayerState) -> String? {
        switch level.win {
        case .wait, .hidden:
            return nil
        case .tap(let id):
            return id
        case .tapWhenLastColor(let color, let thenID, let otherwise):
            if state.lastColorID == nil || state.lastColorID == color {
                return thenID
            }
            return otherwise
        case .tapOppositeOfLastColor(let fallback):
            switch state.lastColorID {
            case "red": return "blue"
            case "blue": return "red"
            default: return fallback
            }
        case .confirmPressed(let id, let yes, let no):
            return state.pressedIDs.contains(id) ? yes : no
        case .tapByTrust(let trusted, let skeptical):
            return state.trustsMoreThanDoubts ? trusted : skeptical
        case .tapIfTrustedLast(let thenID, let otherwise):
            return state.trustedLast ? thenID : otherwise
        }
    }
}

private extension PlayerAction {
    var isTap: Bool {
        switch self {
        case .tapButton, .tapBackground, .tapHidden:
            return true
        case .timeout:
            return false
        }
    }
}
