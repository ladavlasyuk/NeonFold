import UIKit

final class HowToPlayViewController: UIViewController {
    private var backgroundGradient: CAGradientLayer?
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient = Theme.applyBackground(to: view)
        setupHeader()
        setupContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.lockToPortrait()
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
        titleLabel.text = "HOW TO PLAY"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .black)
        titleLabel.textColor = .white
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let steps: [(String, String)] = [
            ("1. Read the sheet", "Each level places glowing glyphs on a paper grid. Empty cells stay blank."),
            ("2. Fold in sequence", "Use Left, Right, Up, or Down to fold one half of the sheet onto the other."),
            ("3. Match the solution", "Your fold order must match the hidden solution sequence exactly."),
            ("4. Watch the hint", "The fold counter shows how many folds the level needs. You can hide hints in Settings."),
            ("5. Undo or Reset", "Undo removes the last fold. Reset restores the original sheet."),
            ("6. Tune feedback", "Open Settings to toggle haptics, sound, fold animations, and glyph glow.")
        ]

        for step in steps {
            contentStack.addArrangedSubview(makeCard(title: step.0, body: step.1))
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
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

    private func makeCard(title: String, body: String) -> UIView {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.cardBorder.cgColor

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        titleLabel.textColor = Palette.primary

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.text = body
        bodyLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        bodyLabel.textColor = Palette.textSecondary
        bodyLabel.numberOfLines = 0

        card.addSubview(titleLabel)
        card.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            bodyLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
