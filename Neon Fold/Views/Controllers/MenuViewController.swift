import UIKit

final class MenuViewController: UIViewController {
    private var backgroundGradient: CAGradientLayer?
    private let brandLabel = UILabel()
    private let taglineLabel = UILabel()
    private let bestScoreLabel = PaddedLabel()
    private let contentStack = UIStackView()
    private let glowOrb = UIView()
    private let accentOrb = UIView()
    private let profilePortraitView = UIImageView()
    private let profileInitialsLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient = Theme.applyBackground(to: view)
        setupAtmosphere()
        setupTopBar()
        setupBrand()
        setupButtons()
        animateEntrance()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileChange),
            name: .playerProfileDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.lockToPortrait()
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refreshProfileButton()
        refreshBestScore()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient?.frame = view.bounds
        glowOrb.layer.cornerRadius = glowOrb.bounds.width / 2
        accentOrb.layer.cornerRadius = accentOrb.bounds.width / 2
    }

    private func setupAtmosphere() {
        glowOrb.translatesAutoresizingMaskIntoConstraints = false
        glowOrb.backgroundColor = Palette.primary.withAlphaComponent(0.16)
        glowOrb.layer.shadowColor = Palette.primary.cgColor
        glowOrb.layer.shadowOpacity = 0.85
        glowOrb.layer.shadowRadius = 48
        glowOrb.layer.shadowOffset = .zero
        view.addSubview(glowOrb)

        accentOrb.translatesAutoresizingMaskIntoConstraints = false
        accentOrb.backgroundColor = Palette.accent.withAlphaComponent(0.14)
        accentOrb.layer.shadowColor = Palette.accent.cgColor
        accentOrb.layer.shadowOpacity = 0.7
        accentOrb.layer.shadowRadius = 36
        accentOrb.layer.shadowOffset = .zero
        view.addSubview(accentOrb)

        NSLayoutConstraint.activate([
            glowOrb.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -40),
            glowOrb.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            glowOrb.widthAnchor.constraint(equalToConstant: 210),
            glowOrb.heightAnchor.constraint(equalToConstant: 210),

            accentOrb.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 70),
            accentOrb.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
            accentOrb.widthAnchor.constraint(equalToConstant: 140),
            accentOrb.heightAnchor.constraint(equalToConstant: 140)
        ])
    }

    private func setupTopBar() {
        let settingsButton = Theme.iconButton(systemName: "gearshape.fill", target: self, action: #selector(settingsTapped))
        view.addSubview(settingsButton)

        profilePortraitView.translatesAutoresizingMaskIntoConstraints = false
        profilePortraitView.contentMode = .scaleAspectFill
        profilePortraitView.clipsToBounds = true
        profilePortraitView.layer.cornerRadius = 22
        profilePortraitView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        profilePortraitView.layer.borderWidth = 1.4
        profilePortraitView.layer.borderColor = Palette.gold.withAlphaComponent(0.7).cgColor
        view.addSubview(profilePortraitView)

        profileInitialsLabel.translatesAutoresizingMaskIntoConstraints = false
        profileInitialsLabel.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        profileInitialsLabel.textColor = Palette.gold
        profileInitialsLabel.textAlignment = .center
        view.addSubview(profileInitialsLabel)

        let profileButton = UIButton(type: .system)
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        view.addSubview(profileButton)

        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            profilePortraitView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            profilePortraitView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            profilePortraitView.widthAnchor.constraint(equalToConstant: 44),
            profilePortraitView.heightAnchor.constraint(equalToConstant: 44),

            profileInitialsLabel.centerXAnchor.constraint(equalTo: profilePortraitView.centerXAnchor),
            profileInitialsLabel.centerYAnchor.constraint(equalTo: profilePortraitView.centerYAnchor),

            profileButton.centerXAnchor.constraint(equalTo: profilePortraitView.centerXAnchor),
            profileButton.centerYAnchor.constraint(equalTo: profilePortraitView.centerYAnchor),
            profileButton.widthAnchor.constraint(equalToConstant: 56),
            profileButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func setupBrand() {
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        brandLabel.text = "NEON FOLD"
        brandLabel.font = UIFont.systemFont(ofSize: 46, weight: .black)
        brandLabel.textColor = .white
        brandLabel.textAlignment = .center
        brandLabel.layer.shadowColor = Palette.primary.cgColor
        brandLabel.layer.shadowOpacity = 0.75
        brandLabel.layer.shadowRadius = 14
        brandLabel.layer.shadowOffset = .zero
        view.addSubview(brandLabel)

        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel.text = "Fold the sheet. Match the glowing glyphs."
        taglineLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        taglineLabel.textColor = Palette.textSecondary
        taglineLabel.textAlignment = .center
        taglineLabel.numberOfLines = 0
        view.addSubview(taglineLabel)

        bestScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        bestScoreLabel.font = UIFont.systemFont(ofSize: 13, weight: .heavy)
        bestScoreLabel.textColor = Palette.backgroundDeep
        bestScoreLabel.backgroundColor = Palette.gold
        bestScoreLabel.layer.cornerRadius = 14
        bestScoreLabel.clipsToBounds = true
        bestScoreLabel.textAlignment = .center
        view.addSubview(bestScoreLabel)

        NSLayoutConstraint.activate([
            brandLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            brandLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 118),
            brandLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            brandLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            taglineLabel.topAnchor.constraint(equalTo: brandLabel.bottomAnchor, constant: 12),
            taglineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            taglineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),

            bestScoreLabel.topAnchor.constraint(equalTo: taglineLabel.bottomAnchor, constant: 16),
            bestScoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupButtons() {
        contentStack.axis = .vertical
        contentStack.spacing = 11
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        let playButton = Theme.gradientButton(title: "PLAY", colors: [Palette.primary, Palette.primaryDark], height: 58, fontSize: 22)
        let howButton = Theme.flatButton(title: "How To Play", height: 48, fontSize: 16)
        let scoresButton = Theme.flatButton(title: "High Scores", height: 48, fontSize: 16)
        let statsButton = Theme.flatButton(title: "Statistics", height: 48, fontSize: 16)
        let settingsButton = Theme.flatButton(title: "Settings", height: 48, fontSize: 16)
        let privacyButton = Theme.flatButton(title: "Privacy Policy", height: 48, fontSize: 16)

        [playButton, howButton, scoresButton, statsButton, settingsButton, privacyButton].forEach {
            contentStack.addArrangedSubview($0)
        }

        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        howButton.addTarget(self, action: #selector(howTapped), for: .touchUpInside)
        scoresButton.addTarget(self, action: #selector(scoresTapped), for: .touchUpInside)
        statsButton.addTarget(self, action: #selector(statsTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            contentStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: bestScoreLabel.bottomAnchor, constant: 24)
        ])
    }

    private func animateEntrance() {
        brandLabel.alpha = 0
        brandLabel.transform = CGAffineTransform(translationX: 0, y: 18)
        taglineLabel.alpha = 0
        bestScoreLabel.alpha = 0
        contentStack.alpha = 0
        contentStack.transform = CGAffineTransform(translationX: 0, y: 28)

        UIView.animate(withDuration: 0.7, delay: 0.1, options: [.curveEaseOut]) {
            self.brandLabel.alpha = 1
            self.brandLabel.transform = .identity
        }
        UIView.animate(withDuration: 0.6, delay: 0.22, options: [.curveEaseOut]) {
            self.taglineLabel.alpha = 1
            self.bestScoreLabel.alpha = 1
        }
        UIView.animate(withDuration: 0.7, delay: 0.32, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4) {
            self.contentStack.alpha = 1
            self.contentStack.transform = .identity
        }

        UIView.animate(withDuration: 2.6, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
            self.glowOrb.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            self.glowOrb.alpha = 0.75
        }
        UIView.animate(withDuration: 3.1, delay: 0.3, options: [.autoreverse, .repeat, .allowUserInteraction]) {
            self.accentOrb.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
            self.accentOrb.alpha = 0.7
        }
    }

    private func refreshBestScore() {
        let best = DataManager.shared.bestScore()
        let stats = DataManager.shared.loadCareerStats()
        let cleared = max(0, stats.highestLevelCompleted + 1)
        bestScoreLabel.text = best > 0
            ? "Best \(best)  ·  \(cleared)/\(GameLevels.all.count) cleared"
            : "\(GameLevels.all.count) crease challenges await"
    }

    private func refreshProfileButton() {
        if let portrait = ProfileManager.shared.portrait() {
            profilePortraitView.image = portrait
            profileInitialsLabel.isHidden = true
        } else {
            profilePortraitView.image = nil
            profileInitialsLabel.text = ProfileManager.shared.initials
            profileInitialsLabel.isHidden = false
        }
    }

    @objc private func handleProfileChange() {
        refreshProfileButton()
    }

    @objc private func playTapped() {
        HapticsManager.shared.mediumImpact()
        SoundManager.shared.playTap()
        navigationController?.pushViewController(LevelSelectViewController(), animated: true)
    }

    @objc private func howTapped() {
        HapticsManager.shared.lightImpact()
        SoundManager.shared.playTap()
        navigationController?.pushViewController(HowToPlayViewController(), animated: true)
    }

    @objc private func scoresTapped() {
        HapticsManager.shared.lightImpact()
        SoundManager.shared.playTap()
        navigationController?.pushViewController(HighScoresViewController(), animated: true)
    }

    @objc private func statsTapped() {
        HapticsManager.shared.lightImpact()
        SoundManager.shared.playTap()
        navigationController?.pushViewController(StatisticsViewController(), animated: true)
    }

    @objc private func settingsTapped() {
        HapticsManager.shared.lightImpact()
        SoundManager.shared.playTap()
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc private func profileTapped() {
        HapticsManager.shared.lightImpact()
        SoundManager.shared.playTap()
        navigationController?.pushViewController(ProfileViewController(), animated: true)
    }

    @objc private func privacyTapped() {
        HapticsManager.shared.lightImpact()
        SoundManager.shared.playTap()
        let privacy = PrivacyPolicyViewController(addressString: AppConstants.privacyPolicyAddress)
        let nav = UINavigationController(rootViewController: privacy)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
