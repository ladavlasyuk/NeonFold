import AudioToolbox
import UIKit

final class SoundManager {
    static let shared = SoundManager()

    private init() {}

    func playFold() {
        guard SettingsManager.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    func playSuccess() {
        guard SettingsManager.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }

    func playFail() {
        guard SettingsManager.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1053)
    }

    func playTap() {
        guard SettingsManager.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1103)
    }

    func playToggle() {
        guard SettingsManager.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1105)
    }
}
