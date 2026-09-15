import UIKit

final class HighScoresViewController: UIViewController {
    private var backgroundGradient: CAGradientLayer?
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var scores: [HighScoreEntry] = []
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient = Theme.applyBackground(to: view)
        setupHeader()
        setupTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.lockToPortrait()
        reloadScores()
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
        titleLabel.text = "HIGH SCORES"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .black)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        let clearButton = Theme.flatButton(title: "Clear", height: 36, fontSize: 14)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        view.addSubview(clearButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            clearButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ScoreCell.self, forCellReuseIdentifier: ScoreCell.reuseID)
        view.addSubview(tableView)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "No scores yet. Solve a sheet to climb the board."
        emptyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        emptyLabel.textColor = Palette.textSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func reloadScores() {
        scores = DataManager.shared.loadHighScores()
        emptyLabel.isHidden = !scores.isEmpty
        tableView.reloadData()
    }

    @objc private func clearTapped() {
        HapticsManager.shared.warning()
        let alert = UIAlertController(title: "Clear Scores?", message: "This removes all high score entries.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            DataManager.shared.resetHighScores()
            self?.reloadScores()
        })
        present(alert, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}

extension HighScoresViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        scores.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ScoreCell.reuseID, for: indexPath) as! ScoreCell
        cell.configure(rank: indexPath.row + 1, entry: scores[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        78
    }
}

private final class ScoreCell: UITableViewCell {
    static let reuseID = "ScoreCell"

    private let card = UIView()
    private let rankLabel = UILabel()
    private let scoreLabel = UILabel()
    private let metaLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 14
        card.layer.cornerCurve = .continuous
        contentView.addSubview(card)

        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        rankLabel.font = UIFont.systemFont(ofSize: 22, weight: .black)
        rankLabel.textColor = Palette.gold

        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        scoreLabel.textColor = .white

        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        metaLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        metaLabel.textColor = Palette.textSecondary

        card.addSubview(rankLabel)
        card.addSubview(scoreLabel)
        card.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            rankLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            rankLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 36),

            scoreLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 8),
            scoreLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            metaLabel.leadingAnchor.constraint(equalTo: scoreLabel.leadingAnchor),
            metaLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 4),
            metaLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(rank: Int, entry: HighScoreEntry) {
        rankLabel.text = "#\(rank)"
        scoreLabel.text = "\(entry.score)"
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        metaLabel.text = "Level \(entry.levelIndex + 1) · \(entry.foldsUsed) folds · \(formatter.string(from: entry.date))"
    }
}
