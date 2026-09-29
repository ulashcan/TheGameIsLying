import Foundation

struct PersistenceService {
    private let defaults: UserDefaults
    private let key = "player_state_v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PlayerState {
        guard let data = defaults.data(forKey: key) else { return .fresh }
        guard var state = try? JSONDecoder().decode(PlayerState.self, from: data) else {
            return .fresh
        }
        if LevelCatalog.level(id: state.currentLevelID) == nil || state.currentLevelID < 1 {
            state.currentLevelID = 1
            state.campaignWon = false
        }
        return state
    }

    func save(_ state: PlayerState) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: key)
        }
    }

    func reset() {
        save(.fresh)
    }
}
