import UIKit

final class ResultsViewController: UIViewController {
    private var backgroundGradient: CAGradientLayer?
    private let result: GameResult
    private let levelTitle: String
    private let isNewBest: Bool

    init(result: GameResult, levelTitle: String, isNewBest: Bool) {
        self.result = result
        self.levelTitle = levelTitle
        self.isNewBest = isNewBest
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient = Theme.applyBackground(to: view)
        setupContent()
        animateEntrance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.lockToPortrait()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient?.frame = view.bounds
    }

    private func setupContent() {
        let statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = result.passed ? "SHEET SOLVED" : "SEQUENCE FAILED"
        statusLabel.font = UIFont.systemFont(ofSize: 30, weight: .black)
        statusLabel.textColor = result.passed ? Palette.success : Palette.danger
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)

        let levelLabel = UILabel()
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        levelLabel.text = levelTitle
        levelLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        levelLabel.textColor = Palette.textSecondary
        levelLabel.textAlignment = .center
        view.addSubview(levelLabel)

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.cardBorder.cgColor
        view.addSubview(card)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        stack.addArrangedSubview(makeRow(title: "Score", value: "\(result.score)"))
        stack.addArrangedSubview(makeRow(title: "Folds Used", value: "\(result.foldsUsed)"))
        stack.addArrangedSubview(makeRow(title: "Perfect", value: result.perfect ? "Yes" : "No"))
        if isNewBest {
            let badge = PaddedLabel()
            badge.text = "NEW BEST SCORE"
            badge.font = UIFont.systemFont(ofSize: 13, weight: .heavy)
            badge.textColor = Palette.backgroundDeep
            badge.backgroundColor = Palette.gold
            badge.layer.cornerRadius = 10
            badge.clipsToBounds = true
            badge.textAlignment = .center
            stack.addArrangedSubview(badge)
        }

        let againButton = Theme.gradientButton(title: result.passed ? "NEXT LEVEL" : "TRY AGAIN", height: 54, fontSize: 18)
        let menuButton = Theme.flatButton(title: "Back To Levels", height: 50, fontSize: 16)
        againButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(againButton)
        view.addSubview(menuButton)

        againButton.addTarget(self, action: #selector(againTapped), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)

        if result.passed, result.levelIndex + 1 >= GameLevels.all.count {
            againButton.setTitle("LEVEL SELECT", for: .normal)
        }

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            levelLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            levelLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            levelLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            card.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 36),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22),

            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            menuButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            menuButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            againButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            againButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            againButton.bottomAnchor.constraint(equalTo: menuButton.topAnchor, constant: -12)
        ])
    }

    private func makeRow(title: String, value: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = Palette.textSecondary

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
        valueLabel.textColor = .white

        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(valueLabel)
        return row
    }

    private func animateEntrance() {
        view.subviews.forEach { $0.alpha = 0; $0.transform = CGAffineTransform(translationX: 0, y: 16) }
        UIView.animate(withDuration: 0.55, delay: 0.05, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4) {
            self.view.subviews.forEach {
                $0.alpha = 1
                $0.transform = .identity
            }
        }
    }

    @objc private func againTapped() {
        HapticsManager.shared.mediumImpact()
        SoundManager.shared.playTap()
        guard let navigation = navigationController else { return }
        if result.passed {
            let next = result.levelIndex + 1
            if next < GameLevels.all.count {
                var stack = navigation.viewControllers.filter { !($0 is GameViewController) && !($0 is ResultsViewController) }
                stack.append(GameViewController(levelIndex: next))
                navigation.setViewControllers(stack, animated: true)
                return
            }
        }
        var stack = navigation.viewControllers.filter { !($0 is GameViewController) && !($0 is ResultsViewController) }
        stack.append(GameViewController(levelIndex: result.levelIndex))
        navigation.setViewControllers(stack, animated: true)
    }

    @objc private func menuTapped() {
        HapticsManager.shared.lightImpact()
        SoundManager.shared.playTap()
        guard let navigation = navigationController else { return }
        if let select = navigation.viewControllers.first(where: { $0 is LevelSelectViewController }) {
            navigation.popToViewController(select, animated: true)
        } else {
            navigation.popToRootViewController(animated: true)
        }
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
