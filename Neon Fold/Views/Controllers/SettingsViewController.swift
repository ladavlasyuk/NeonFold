import UIKit

final class SettingsViewController: UIViewController {
    private var backgroundGradient: CAGradientLayer?
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private var hapticsSwitch: UISwitch!
    private var soundSwitch: UISwitch!
    private var hintsSwitch: UISwitch!
    private var animationsSwitch: UISwitch!
    private var glowSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient = Theme.applyBackground(to: view)
        setupHeader()
        setupScroll()
        buildRows()
        syncSwitchesFromSettings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.lockToPortrait()
        syncSwitchesFromSettings()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient?.frame = view.bounds
    }

    private func setupHeader() {
        let backButton = Theme.backButton(target: self, action: #selector(backTapped))
        view.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "SETTINGS"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .black)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.text = "Tune feedback, hints, and fold presentation."
        subtitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitle.textColor = Palette.textSecondary
        subtitle.numberOfLines = 0
        view.addSubview(subtitle)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])
    }

    private func buildRows() {
        let haptics = makeToggleRow(
            title: "Haptics",
            detail: "Vibration feedback for folds and results"
        )
        hapticsSwitch = haptics.control
        hapticsSwitch.addTarget(self, action: #selector(hapticsChanged), for: .valueChanged)
        contentStack.addArrangedSubview(haptics.card)

        let sound = makeToggleRow(
            title: "Sound Effects",
            detail: "Play short cues on folds and outcomes"
        )
        soundSwitch = sound.control
        soundSwitch.addTarget(self, action: #selector(soundChanged), for: .valueChanged)
        contentStack.addArrangedSubview(sound.card)

        let hints = makeToggleRow(
            title: "Fold Hints",
            detail: "Show how many folds the level needs"
        )
        hintsSwitch = hints.control
        hintsSwitch.addTarget(self, action: #selector(hintsChanged), for: .valueChanged)
        contentStack.addArrangedSubview(hints.card)

        let animations = makeToggleRow(
            title: "Fold Animations",
            detail: "Animate the sheet when a crease is made"
        )
        animationsSwitch = animations.control
        animationsSwitch.addTarget(self, action: #selector(animationsChanged), for: .valueChanged)
        contentStack.addArrangedSubview(animations.card)

        let glow = makeToggleRow(
            title: "Glyph Glow",
            detail: "Add neon glow around glowing glyphs"
        )
        glowSwitch = glow.control
        glowSwitch.addTarget(self, action: #selector(glowChanged), for: .valueChanged)
        contentStack.addArrangedSubview(glow.card)

        let note = UILabel()
        note.text = "Changes apply immediately in the next fold and on every game screen."
        note.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        note.textColor = Palette.textSecondary
        note.numberOfLines = 0
        contentStack.addArrangedSubview(note)
    }

    private func makeToggleRow(title: String, detail: String) -> (card: UIView, control: UISwitch) {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.cardBorder.cgColor

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
        titleLabel.textColor = .white

        let detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.text = detail
        detailLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        detailLabel.textColor = Palette.textSecondary
        detailLabel.numberOfLines = 0

        let control = UISwitch()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.onTintColor = Palette.primary
        control.thumbTintColor = .white

        card.addSubview(titleLabel)
        card.addSubview(detailLabel)
        card.addSubview(control)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: control.leadingAnchor, constant: -12),

            control.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            detailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            detailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            detailLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return (card, control)
    }

    private func syncSwitchesFromSettings() {
        let settings = SettingsManager.shared
        hapticsSwitch.setOn(settings.hapticsEnabled, animated: false)
        soundSwitch.setOn(settings.soundEnabled, animated: false)
        hintsSwitch.setOn(settings.hintsEnabled, animated: false)
        animationsSwitch.setOn(settings.foldAnimationsEnabled, animated: false)
        glowSwitch.setOn(settings.glyphGlowEnabled, animated: false)
    }

    @objc private func hapticsChanged() {
        SettingsManager.shared.hapticsEnabled = hapticsSwitch.isOn
        if hapticsSwitch.isOn {
            HapticsManager.shared.selection()
        }
        SoundManager.shared.playToggle()
    }

    @objc private func soundChanged() {
        SettingsManager.shared.soundEnabled = soundSwitch.isOn
        if soundSwitch.isOn {
            SoundManager.shared.playToggle()
        }
        HapticsManager.shared.selection()
    }

    @objc private func hintsChanged() {
        SettingsManager.shared.hintsEnabled = hintsSwitch.isOn
        HapticsManager.shared.selection()
        SoundManager.shared.playToggle()
    }

    @objc private func animationsChanged() {
        SettingsManager.shared.foldAnimationsEnabled = animationsSwitch.isOn
        HapticsManager.shared.selection()
        SoundManager.shared.playToggle()
    }

    @objc private func glowChanged() {
        SettingsManager.shared.glyphGlowEnabled = glowSwitch.isOn
        HapticsManager.shared.selection()
        SoundManager.shared.playToggle()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
