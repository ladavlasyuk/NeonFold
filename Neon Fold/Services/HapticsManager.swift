import UIKit

final class HapticsManager {
    static let shared = HapticsManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        prepareGenerators()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange),
            name: .appSettingsDidChange,
            object: nil
        )
    }

    private var isEnabled: Bool {
        SettingsManager.shared.hapticsEnabled
    }

    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    @objc private func handleSettingsChange() {
        if isEnabled {
            prepareGenerators()
        }
    }

    func lightImpact() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
    }

    func mediumImpact() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
    }

    func heavyImpact() {
        guard isEnabled else { return }
        heavyGenerator.impactOccurred()
    }

    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    func warning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }

    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }

    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }

    func setEnabled(_ enabled: Bool) {
        SettingsManager.shared.hapticsEnabled = enabled
        if enabled {
            prepareGenerators()
            lightImpact()
        }
    }
}
