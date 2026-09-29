import AVFoundation
import AudioToolbox
import Foundation

enum SoundFX: String {
    case tap
    case success
    case fail
    case suspense
}

final class AudioService {
    var enabled = true
    private var players: [AVAudioPlayer] = []
    private var didConfigureSession = false
    private let maxPlayers = 6

    func play(_ fx: SoundFX) {
        guard enabled else { return }
        configureSessionIfNeeded()
        players.removeAll { !$0.isPlaying }
        if players.count >= maxPlayers {
            players.removeFirst(players.count - maxPlayers + 1)
        }
        guard let url = Bundle.main.url(forResource: fx.rawValue, withExtension: "wav") else {
            breakToSystemSound(fx)
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players.append(player)
            player.play()
        } catch {
            breakToSystemSound(fx)
        }
    }

    private func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        didConfigureSession = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            didConfigureSession = false
        }
    }

    private func breakToSystemSound(_ fx: SoundFX) {
        let id: SystemSoundID
        switch fx {
        case .tap: id = 1104
        case .success: id = 1111
        case .fail: id = 1053
        case .suspense: id = 1113
        }
        AudioServicesPlaySystemSound(id)
    }
}
