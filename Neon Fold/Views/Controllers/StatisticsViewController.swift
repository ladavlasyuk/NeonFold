import UIKit

final class StatisticsViewController: UIViewController {
    private var backgroundGradient: CAGradientLayer?
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient = Theme.applyBackground(to: view)
        setupHeader()
        setupStack()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.lockToPortrait()
        refreshStats()
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
        titleLabel.text = "STATISTICS"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .black)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        let resetButton = Theme.flatButton(title: "Reset", height: 36, fontSize: 14)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        view.addSubview(resetButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            resetButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupStack() {
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 110),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func refreshStats() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let stats = DataManager.shared.loadCareerStats()
        let highest = stats.highestLevelCompleted >= 0 ? "\(stats.highestLevelCompleted + 1)" : "—"

        let rows: [(String, String)] = [
            ("Puzzles Played", "\(stats.puzzlesPlayed)"),
            ("Puzzles Solved", "\(stats.puzzlesSolved)"),
            ("Total Folds", "\(stats.totalFolds)"),
            ("Best Score", "\(stats.bestScore)"),
            ("Highest Level", highest)
        ]

        for row in rows {
            contentStack.addArrangedSubview(makeStatCard(title: row.0, value: row.1))
        }
    }

    private func makeStatCard(title: String, value: String) -> UIView {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.cardBorder.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = Palette.textSecondary

        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 26, weight: .black)
        valueLabel.textColor = Palette.primary

        card.addSubview(titleLabel)
        card.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

            valueLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            valueLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    @objc private func resetTapped() {
        HapticsManager.shared.warning()
        let alert = UIAlertController(title: "Reset Statistics?", message: "Career progress counters will be cleared.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            DataManager.shared.resetCareer()
            self?.refreshStats()
        })
        present(alert, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
