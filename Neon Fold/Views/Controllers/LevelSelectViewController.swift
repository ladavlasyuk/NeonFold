import UIKit

final class LevelSelectViewController: UIViewController {
    private var backgroundGradient: CAGradientLayer?
    private let scrollView = UIScrollView()
    private let gridStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient = Theme.applyBackground(to: view)
        setupHeader()
        setupGrid()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.lockToPortrait()
        rebuildGrid()
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
        titleLabel.text = "SELECT LEVEL"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .black)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.text = "Unlock the next sheet by solving the previous one."
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

    private func setupGrid() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        gridStack.axis = .vertical
        gridStack.spacing = 12
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            gridStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            gridStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            gridStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            gridStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])
    }

    private func rebuildGrid() {
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let stats = DataManager.shared.loadCareerStats()
        let levels = GameLevels.all

        var row: UIStackView?
        for (index, level) in levels.enumerated() {
            if index % 2 == 0 {
                row = UIStackView()
                row?.axis = .horizontal
                row?.spacing = 12
                row?.distribution = .fillEqually
                gridStack.addArrangedSubview(row!)
            }
            let unlocked = GameLevels.isUnlocked(index: index, highestCompleted: stats.highestLevelCompleted)
            let card = makeLevelCard(level: level, index: index, unlocked: unlocked, best: stats.levelBestScores[index])
            row?.addArrangedSubview(card)
        }
        if let lastRow = row, lastRow.arrangedSubviews.count == 1 {
            let spacer = UIView()
            lastRow.addArrangedSubview(spacer)
        }
    }

    private func makeLevelCard(level: FoldLevel, index: Int, unlocked: Bool, best: Int?) -> UIView {
        let card = UIButton(type: .system)
        card.tag = index
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = unlocked ? Palette.primary.withAlphaComponent(0.45).cgColor : Palette.cardBorder.cgColor
        card.isEnabled = unlocked
        card.alpha = unlocked ? 1 : 0.45
        card.addTarget(self, action: #selector(levelTapped(_:)), for: .touchUpInside)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 118).isActive = true

        let numberLabel = UILabel()
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.text = String(format: "%02d", level.id)
        numberLabel.font = UIFont.systemFont(ofSize: 28, weight: .black)
        numberLabel.textColor = unlocked ? Palette.primary : Palette.textSecondary

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = level.title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        let previewLabel = UILabel()
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        previewLabel.textColor = unlocked ? Palette.accent : Palette.textSecondary
        let unique = Set(level.glyphs.flatMap { $0 }.compactMap { $0 }).sorted()
        previewLabel.text = unique.prefix(4).map { GlyphStyle.mark(for: $0) }.joined(separator: " ")

        let metaLabel = UILabel()
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        metaLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        metaLabel.textColor = Palette.gold
        if unlocked {
            let bestText = best.map { "Best \($0)" } ?? "\(level.foldsAllowed) folds · \(level.gridSize)×\(level.gridSize)"
            metaLabel.text = bestText
        } else {
            metaLabel.text = "Locked"
        }

        card.addSubview(numberLabel)
        card.addSubview(titleLabel)
        card.addSubview(previewLabel)
        card.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            numberLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),

            previewLabel.centerYAnchor.constraint(equalTo: numberLabel.centerYAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            titleLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            metaLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            metaLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    @objc private func levelTapped(_ sender: UIButton) {
        HapticsManager.shared.selection()
        let game = GameViewController(levelIndex: sender.tag)
        navigationController?.pushViewController(game, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
