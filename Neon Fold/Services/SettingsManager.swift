import Foundation

extension Notification.Name {
    static let appSettingsDidChange = Notification.Name("appSettingsDidChange")
}

final class SettingsManager {
    static let shared = SettingsManager()

    private enum Keys {
        static let haptics = "settings_haptics_enabled"
        static let sound = "settings_sound_enabled"
        static let hints = "settings_hints_enabled"
        static let animations = "settings_fold_animations_enabled"
        static let glyphGlow = "settings_glyph_glow_enabled"
    }

    private init() {}

    var hapticsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.haptics) == nil,
               let legacy = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool {
                return legacy
            }
            return bool(for: Keys.haptics, default: true)
        }
        set { setBool(newValue, for: Keys.haptics) }
    }

    var soundEnabled: Bool {
        get { bool(for: Keys.sound, default: true) }
        set { setBool(newValue, for: Keys.sound) }
    }

    var hintsEnabled: Bool {
        get { bool(for: Keys.hints, default: true) }
        set { setBool(newValue, for: Keys.hints) }
    }

    var foldAnimationsEnabled: Bool {
        get { bool(for: Keys.animations, default: true) }
        set { setBool(newValue, for: Keys.animations) }
    }

    var glyphGlowEnabled: Bool {
        get { bool(for: Keys.glyphGlow, default: true) }
        set { setBool(newValue, for: Keys.glyphGlow) }
    }

    private func bool(for key: String, default defaultValue: Bool) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }

    private func setBool(_ value: Bool, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
        NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
    }
}
