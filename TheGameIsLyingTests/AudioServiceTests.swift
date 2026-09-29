import XCTest
@testable import TheGameIsLying

final class AudioServiceTests: XCTestCase {
    func testDisabledAudioDoesNotCrashOnRapidPlay() {
        let audio = AudioService()
        audio.enabled = false
        for _ in 0..<20 {
            audio.play(.tap)
            audio.play(.success)
            audio.play(.fail)
            audio.play(.suspense)
        }
    }

    func testEnabledAudioRapidPlayDoesNotCrash() {
        let audio = AudioService()
        audio.enabled = true
        for _ in 0..<12 {
            audio.play(.tap)
        }
        audio.play(.success)
        audio.play(.fail)
        audio.play(.suspense)
    }
}
