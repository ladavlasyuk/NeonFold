import UIKit

final class GameViewController: UIViewController {
    private var backgroundGradient: CAGradientLayer?
    private let levelIndex: Int
    private let level: FoldLevel

    private var currentGlyphs: [[Int?]] = []
    private var foldHistory: [FoldDirection] = []
    private var glyphSnapshots: [[[Int?]]] = []
    private var isAnimating = false

    private let titleLabel = UILabel()
    private let hintLabel = PaddedLabel()
    private let progressLabel = UILabel()
    private let sequenceLabel = UILabel()
    private let paperContainer = UIView()
    private let paperSheet = UIView()
    private let creaseOverlay = UIView()
    private var paperSheenLayer: CAGradientLayer?
    private var cellViews: [[UIView]] = []
    private let controlsStack = UIStackView()
    private var foldButtons: [UIButton] = []
    private var foldStatusDots: [UIView] = []
    private let previewHost = UIView()
    private let previewMoving = UIView()
    private let previewTarget = UIView()
    private let previewCrease = UIView()
    private let previewArrow = UILabel()
    private let previewCaption = PaddedLabel()
    private var previewDirection: FoldDirection?
    private let undoButton = Theme.flatButton(title: "Undo", height: 46, fontSize: 15)
    private let resetButton = Theme.flatButton(title: "Reset", height: 46, fontSize: 15)

    init(levelIndex: Int) {
        self.levelIndex = levelIndex
        self.level = GameLevels.level(at: levelIndex) ?? GameLevels.all[0]
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.levelIndex = 0
        self.level = GameLevels.all[0]
        super.init(coder: coder)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient = Theme.applyBackground(to: view)
        currentGlyphs = level.glyphs
        glyphSnapshots = [currentGlyphs]
        setupHeader()
        setupPaper()
        setupPreviewOverlay()
        setupControls()
        setupFoldGestures()
        rebuildCells()
        refreshLabels()
        applySettingsPresentation()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange),
            name: .appSettingsDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.lockToPortrait()
        applySettingsPresentation()
        cellViews.forEach { $0.forEach { $0.isHidden = false } }
        paintCells()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient?.frame = view.bounds
        paperSheenLayer?.frame = paperSheet.bounds
        layoutCells()
        updateCreaseOverlay()
    }

    private func setupHeader() {
        let backButton = Theme.backButton(target: self, action: #selector(backTapped))
        view.addSubview(backButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = level.title.uppercased()
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .black)
        titleLabel.textColor = .white
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        view.addSubview(titleLabel)

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.font = UIFont.systemFont(ofSize: 13, weight: .heavy)
        hintLabel.textColor = Palette.backgroundDeep
        hintLabel.backgroundColor = Palette.gold
        hintLabel.layer.cornerRadius = 12
        hintLabel.clipsToBounds = true
        hintLabel.textAlignment = .center
        view.addSubview(hintLabel)

        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        progressLabel.textColor = Palette.textSecondary
        view.addSubview(progressLabel)

        sequenceLabel.translatesAutoresizingMaskIntoConstraints = false
        sequenceLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        sequenceLabel.textColor = Palette.primary
        sequenceLabel.numberOfLines = 1
        sequenceLabel.adjustsFontSizeToFitWidth = true
        sequenceLabel.minimumScaleFactor = 0.6
        view.addSubview(sequenceLabel)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            hintLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            progressLabel.centerYAnchor.constraint(equalTo: hintLabel.centerYAnchor),
            progressLabel.leadingAnchor.constraint(equalTo: hintLabel.trailingAnchor, constant: 12),
            progressLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            sequenceLabel.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 10),
            sequenceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sequenceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupPaper() {
        paperContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paperContainer)

        paperSheet.translatesAutoresizingMaskIntoConstraints = false
        paperSheet.backgroundColor = Palette.paper
        paperSheet.layer.cornerRadius = 20
        paperSheet.layer.cornerCurve = .continuous
        paperSheet.layer.borderWidth = 1.5
        paperSheet.layer.borderColor = Palette.primary.withAlphaComponent(0.5).cgColor
        paperSheet.layer.shadowColor = Palette.primary.cgColor
        paperSheet.layer.shadowOpacity = 0.4
        paperSheet.layer.shadowRadius = 22
        paperSheet.layer.shadowOffset = .zero
        paperSheet.clipsToBounds = true
        paperContainer.addSubview(paperSheet)

        let sheen = CAGradientLayer()
        sheen.colors = [
            UIColor.white.withAlphaComponent(0.10).cgColor,
            UIColor.clear.cgColor,
            Palette.accent.withAlphaComponent(0.08).cgColor
        ]
        sheen.startPoint = CGPoint(x: 0, y: 0)
        sheen.endPoint = CGPoint(x: 1, y: 1)
        paperSheet.layer.insertSublayer(sheen, at: 0)
        paperSheenLayer = sheen

        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 900.0
        paperContainer.layer.sublayerTransform = perspective

        creaseOverlay.translatesAutoresizingMaskIntoConstraints = false
        creaseOverlay.isUserInteractionEnabled = false
        creaseOverlay.backgroundColor = .clear
        paperSheet.addSubview(creaseOverlay)

        NSLayoutConstraint.activate([
            paperContainer.topAnchor.constraint(equalTo: sequenceLabel.bottomAnchor, constant: 18),
            paperContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            paperContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            paperContainer.heightAnchor.constraint(equalTo: paperContainer.widthAnchor),

            paperSheet.centerXAnchor.constraint(equalTo: paperContainer.centerXAnchor),
            paperSheet.centerYAnchor.constraint(equalTo: paperContainer.centerYAnchor),
            paperSheet.widthAnchor.constraint(equalTo: paperContainer.widthAnchor),
            paperSheet.heightAnchor.constraint(equalTo: paperContainer.heightAnchor),

            creaseOverlay.topAnchor.constraint(equalTo: paperSheet.topAnchor),
            creaseOverlay.leadingAnchor.constraint(equalTo: paperSheet.leadingAnchor),
            creaseOverlay.trailingAnchor.constraint(equalTo: paperSheet.trailingAnchor),
            creaseOverlay.bottomAnchor.constraint(equalTo: paperSheet.bottomAnchor)
        ])
    }

    private func setupPreviewOverlay() {
        previewHost.translatesAutoresizingMaskIntoConstraints = false
        previewHost.isUserInteractionEnabled = false
        previewHost.alpha = 0
        paperSheet.addSubview(previewHost)

        previewTarget.layer.cornerRadius = 14
        previewTarget.layer.cornerCurve = .continuous
        previewTarget.layer.borderWidth = 1.5
        previewHost.addSubview(previewTarget)

        previewMoving.layer.cornerRadius = 14
        previewMoving.layer.cornerCurve = .continuous
        previewMoving.layer.borderWidth = 1.5
        previewMoving.layer.borderColor = Palette.primary.withAlphaComponent(0.55).cgColor
        previewMoving.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        previewHost.addSubview(previewMoving)

        previewCrease.backgroundColor = Palette.primary
        previewCrease.layer.shadowColor = Palette.primary.cgColor
        previewCrease.layer.shadowOpacity = 0.9
        previewCrease.layer.shadowRadius = 6
        previewCrease.layer.shadowOffset = .zero
        previewHost.addSubview(previewCrease)

        previewArrow.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        previewArrow.textAlignment = .center
        previewHost.addSubview(previewArrow)

        previewCaption.translatesAutoresizingMaskIntoConstraints = false
        previewCaption.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        previewCaption.textColor = .white
        previewCaption.textAlignment = .center
        previewCaption.numberOfLines = 1
        previewCaption.adjustsFontSizeToFitWidth = true
        previewCaption.minimumScaleFactor = 0.6
        previewCaption.backgroundColor = Palette.backgroundDeep.withAlphaComponent(0.85)
        previewCaption.layer.cornerRadius = 11
        previewCaption.clipsToBounds = true
        previewHost.addSubview(previewCaption)

        NSLayoutConstraint.activate([
            previewHost.topAnchor.constraint(equalTo: paperSheet.topAnchor),
            previewHost.leadingAnchor.constraint(equalTo: paperSheet.leadingAnchor),
            previewHost.trailingAnchor.constraint(equalTo: paperSheet.trailingAnchor),
            previewHost.bottomAnchor.constraint(equalTo: paperSheet.bottomAnchor),

            previewCaption.centerXAnchor.constraint(equalTo: previewHost.centerXAnchor),
            previewCaption.bottomAnchor.constraint(equalTo: previewHost.bottomAnchor, constant: -10),
            previewCaption.leadingAnchor.constraint(greaterThanOrEqualTo: previewHost.leadingAnchor, constant: 10),
            previewCaption.trailingAnchor.constraint(lessThanOrEqualTo: previewHost.trailingAnchor, constant: -10)
        ])
    }

    private func setupFoldGestures() {
        let pairs: [(UISwipeGestureRecognizer.Direction, FoldDirection)] = [
            (.left, .left),
            (.right, .right),
            (.up, .up),
            (.down, .down)
        ]
        for (swipeDirection, foldDirection) in pairs {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleFoldSwipe(_:)))
            swipe.direction = swipeDirection
            swipe.name = foldDirection.rawValue
            paperContainer.addGestureRecognizer(swipe)
        }
    }

    private func setupControls() {
        controlsStack.axis = .vertical
        controlsStack.spacing = 10
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsStack)

        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.spacing = 10
        row1.distribution = .fillEqually

        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.spacing = 10
        row2.distribution = .fillEqually

        foldButtons.removeAll()
        foldStatusDots.removeAll()
        for direction in FoldDirection.allCases {
            let button = Theme.gradientButton(
                title: "\(direction.symbol) \(direction.title)",
                colors: direction == .left || direction == .right
                    ? [Palette.primary, Palette.primaryDark]
                    : [Palette.accent, Palette.accentSoft],
                height: 48,
                fontSize: 14
            )
            button.tag = FoldDirection.allCases.firstIndex(of: direction) ?? 0
            button.layer.borderWidth = 2
            button.addTarget(self, action: #selector(foldTapped(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(foldTouchStarted(_:)), for: [.touchDown, .touchDragEnter])
            button.addTarget(
                self,
                action: #selector(foldTouchEnded),
                for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
            )

            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 5
            dot.layer.borderWidth = 1
            dot.layer.borderColor = Palette.backgroundDeep.withAlphaComponent(0.6).cgColor
            button.addSubview(dot)
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 10),
                dot.heightAnchor.constraint(equalToConstant: 10),
                dot.topAnchor.constraint(equalTo: button.topAnchor, constant: 7),
                dot.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -8)
            ])
            foldStatusDots.append(dot)

            foldButtons.append(button)
            if direction == .up || direction == .down {
                row1.addArrangedSubview(button)
            } else {
                row2.addArrangedSubview(button)
            }
        }

        let utilityRow = UIStackView()
        utilityRow.axis = .horizontal
        utilityRow.spacing = 10
        utilityRow.distribution = .fillEqually
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        utilityRow.addArrangedSubview(undoButton)
        utilityRow.addArrangedSubview(resetButton)

        controlsStack.addArrangedSubview(row1)
        controlsStack.addArrangedSubview(row2)
        controlsStack.addArrangedSubview(utilityRow)

        NSLayoutConstraint.activate([
            controlsStack.topAnchor.constraint(greaterThanOrEqualTo: paperContainer.bottomAnchor, constant: 16),
            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            controlsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func rebuildCells() {
        for row in cellViews {
            for cell in row {
                cell.removeFromSuperview()
            }
        }
        cellViews = []
        let size = level.gridSize
        for _ in 0..<size {
            var rowViews: [UIView] = []
            for _ in 0..<size {
                let cell = UIView()
                cell.layer.cornerRadius = 12
                cell.layer.cornerCurve = .continuous
                cell.backgroundColor = UIColor.white.withAlphaComponent(0.05)
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

                let glyph = UIView()
                glyph.tag = 100
                glyph.layer.cornerRadius = 16
                glyph.isHidden = true
                cell.addSubview(glyph)

                let mark = UILabel()
                mark.tag = 101
                mark.font = UIFont.systemFont(ofSize: 16, weight: .black)
                mark.textAlignment = .center
                mark.textColor = Palette.backgroundDeep
                mark.translatesAutoresizingMaskIntoConstraints = false
                glyph.addSubview(mark)

                NSLayoutConstraint.activate([
                    mark.centerXAnchor.constraint(equalTo: glyph.centerXAnchor),
                    mark.centerYAnchor.constraint(equalTo: glyph.centerYAnchor)
                ])

                paperSheet.insertSubview(cell, belowSubview: creaseOverlay)
                rowViews.append(cell)
            }
            cellViews.append(rowViews)
        }
        paperSheet.bringSubviewToFront(creaseOverlay)
        paperSheet.bringSubviewToFront(previewHost)
        layoutCells()
        paintCells()
        updateCreaseOverlay()
    }

    private func layoutCells() {
        let size = level.gridSize
        guard cellViews.count == size else { return }
        let inset: CGFloat = 14
        let gap: CGFloat = 8
        let available = paperSheet.bounds.width - inset * 2 - gap * CGFloat(size - 1)
        guard available > 0 else { return }
        let side = available / CGFloat(size)

        for row in 0..<size {
            for col in 0..<size {
                let cell = cellViews[row][col]
                let x = inset + CGFloat(col) * (side + gap)
                let y = inset + CGFloat(row) * (side + gap)
                cell.frame = CGRect(x: x, y: y, width: side, height: side)
                if let glyph = cell.viewWithTag(100) {
                    let pad = side * 0.16
                    glyph.frame = CGRect(x: pad, y: pad, width: side - pad * 2, height: side - pad * 2)
                    glyph.layer.cornerRadius = glyph.bounds.width / 2
                    if let mark = glyph.viewWithTag(101) as? UILabel {
                        mark.font = UIFont.systemFont(ofSize: max(12, side * 0.22), weight: .black)
                    }
                }
            }
        }
    }

    private func paintCells() {
        let size = level.gridSize
        let glowOn = SettingsManager.shared.glyphGlowEnabled
        for row in 0..<size {
            for col in 0..<size {
                let cell = cellViews[row][col]
                guard let glyph = cell.viewWithTag(100),
                      let mark = glyph.viewWithTag(101) as? UILabel else { continue }
                if let value = currentGlyphs[row][col], value >= 1, value <= GlyphStyle.colors.count {
                    let color = GlyphStyle.color(for: value)
                    glyph.isHidden = false
                    glyph.backgroundColor = color
                    glyph.layer.shadowColor = color.cgColor
                    glyph.layer.shadowOpacity = glowOn ? 0.9 : 0
                    glyph.layer.shadowRadius = glowOn ? 10 : 0
                    glyph.layer.shadowOffset = .zero
                    mark.text = GlyphStyle.mark(for: value)
                    cell.layer.borderColor = color.withAlphaComponent(0.35).cgColor
                } else {
                    glyph.isHidden = true
                    mark.text = nil
                    cell.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
                }
            }
        }
    }

    private func updateCreaseOverlay() {
        creaseOverlay.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let bounds = paperSheet.bounds
        guard bounds.width > 0 else { return }

        var verticalOffsets: [CGFloat] = []
        var horizontalOffsets: [CGFloat] = []

        for direction in FoldDirection.allCases {
            let offset = creaseOffset(for: direction)
            switch direction {
            case .left, .right:
                if !verticalOffsets.contains(where: { abs($0 - offset) < 0.5 }) {
                    verticalOffsets.append(offset)
                }
            case .up, .down:
                if !horizontalOffsets.contains(where: { abs($0 - offset) < 0.5 }) {
                    horizontalOffsets.append(offset)
                }
            }
        }

        for offset in verticalOffsets {
            creaseOverlay.layer.addSublayer(
                creaseLine(
                    from: CGPoint(x: offset, y: 10),
                    to: CGPoint(x: offset, y: bounds.height - 10),
                    color: Palette.primary
                )
            )
        }

        for offset in horizontalOffsets {
            creaseOverlay.layer.addSublayer(
                creaseLine(
                    from: CGPoint(x: 10, y: offset),
                    to: CGPoint(x: bounds.width - 10, y: offset),
                    color: Palette.accent
                )
            )
        }
    }

    private func creaseLine(from start: CGPoint, to end: CGPoint, color: UIColor) -> CAShapeLayer {
        let line = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        line.path = path.cgPath
        line.strokeColor = color.withAlphaComponent(0.28).cgColor
        line.lineWidth = 1
        line.lineDashPattern = [5, 4]
        return line
    }

    private func refreshLabels() {
        hintLabel.text = "Needs \(level.foldsAllowed) fold\(level.foldsAllowed == 1 ? "" : "s")"
        progressLabel.text = "Used \(foldHistory.count)/\(level.foldsAllowed)"

        if foldHistory.isEmpty {
            sequenceLabel.text = "Sequence: —  ·  swipe the sheet or hold a button"
        } else {
            sequenceLabel.text = "Sequence: " + foldHistory.map(\.symbol).joined(separator: "  ")
        }

        undoButton.isEnabled = !foldHistory.isEmpty && !isAnimating
        undoButton.alpha = undoButton.isEnabled ? 1 : 0.45
        resetButton.isEnabled = !isAnimating
        let foldsLeft = foldHistory.count < level.foldsAllowed && !isAnimating
        foldButtons.forEach {
            $0.isEnabled = foldsLeft
        }
        refreshFoldStatuses()
    }

    private func refreshFoldStatuses() {
        let available = foldHistory.count < level.foldsAllowed
        for (index, button) in foldButtons.enumerated() {
            guard index < FoldDirection.allCases.count else { continue }
            let outcome = foldOutcome(for: FoldDirection.allCases[index])
            let tint = available ? outcome.tint : UIColor.white.withAlphaComponent(0.25)
            button.layer.borderColor = tint.withAlphaComponent(available ? 0.95 : 0.3).cgColor
            if index < foldStatusDots.count {
                foldStatusDots[index].backgroundColor = tint
            }
        }
    }

    private enum FoldOutcome {
        case merge
        case shift
        case overwrite
        case idle

        var tint: UIColor {
            switch self {
            case .merge: return Palette.success
            case .shift: return Palette.primary
            case .overwrite: return Palette.danger
            case .idle: return UIColor.white.withAlphaComponent(0.3)
            }
        }

        var caption: String {
            switch self {
            case .merge: return "aligns glyphs"
            case .shift: return "carries glyphs over"
            case .overwrite: return "covers a glyph"
            case .idle: return "nothing to fold"
            }
        }
    }

    private func foldPairs(for direction: FoldDirection) -> [(target: (Int, Int), source: (Int, Int))] {
        let size = level.gridSize
        let half = size / 2
        var pairs: [(target: (Int, Int), source: (Int, Int))] = []

        switch direction {
        case .left:
            for row in 0..<size {
                for col in 0..<half {
                    pairs.append((target: (row, col), source: (row, size - 1 - col)))
                }
            }
        case .right:
            for row in 0..<size {
                for col in 0..<half {
                    pairs.append((target: (row, size - 1 - col), source: (row, col)))
                }
            }
        case .up:
            for col in 0..<size {
                for row in 0..<half {
                    pairs.append((target: (row, col), source: (size - 1 - row, col)))
                }
            }
        case .down:
            for col in 0..<size {
                for row in 0..<half {
                    pairs.append((target: (size - 1 - row, col), source: (row, col)))
                }
            }
        }
        return pairs
    }

    private func foldOutcome(for direction: FoldDirection) -> FoldOutcome {
        let size = level.gridSize
        guard currentGlyphs.count == size else { return .idle }

        var hasMerge = false
        var hasShift = false
        var hasOverwrite = false

        for pair in foldPairs(for: direction) {
            guard let source = currentGlyphs[pair.source.0][pair.source.1] else { continue }
            if let target = currentGlyphs[pair.target.0][pair.target.1] {
                if target == source {
                    hasMerge = true
                } else {
                    hasOverwrite = true
                }
            } else {
                hasShift = true
            }
        }

        if hasOverwrite { return .overwrite }
        if hasMerge { return .merge }
        if hasShift { return .shift }
        return .idle
    }

    private func applySettingsPresentation() {
        let hintsOn = SettingsManager.shared.hintsEnabled
        hintLabel.isHidden = !hintsOn
        hintLabel.alpha = hintsOn ? 1 : 0
        paintCells()
    }

    @objc private func handleSettingsChange() {
        applySettingsPresentation()
        refreshLabels()
    }

    @objc private func foldTapped(_ sender: UIButton) {
        guard sender.tag < FoldDirection.allCases.count else { return }
        attemptFold(FoldDirection.allCases[sender.tag])
    }

    @objc private func foldTouchStarted(_ sender: UIButton) {
        guard !isAnimating, sender.tag < FoldDirection.allCases.count else { return }
        guard foldHistory.count < level.foldsAllowed else { return }
        showFoldPreview(FoldDirection.allCases[sender.tag])
    }

    @objc private func foldTouchEnded() {
        hideFoldPreview()
    }

    @objc private func handleFoldSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let name = gesture.name, let direction = FoldDirection(rawValue: name) else { return }
        attemptFold(direction)
    }

    private func attemptFold(_ direction: FoldDirection) {
        guard !isAnimating else { return }
        guard foldHistory.count < level.foldsAllowed else {
            HapticsManager.shared.error()
            SoundManager.shared.playFail()
            flashProgressError()
            return
        }
        hideFoldPreview()
        performFold(direction)
    }

    private func showFoldPreview(_ direction: FoldDirection) {
        let bounds = paperSheet.bounds
        guard bounds.width > 1 else { return }

        let crease = creaseOffset(for: direction)
        let moving = flapRect(for: direction, crease: crease, in: bounds)
        let landing = landingRect(for: direction, crease: crease, in: bounds)
        let outcome = foldOutcome(for: direction)
        let tint = outcome.tint

        previewMoving.frame = moving.insetBy(dx: 5, dy: 5)
        previewTarget.frame = landing.insetBy(dx: 5, dy: 5)
        previewTarget.layer.borderColor = tint.withAlphaComponent(0.7).cgColor
        previewTarget.backgroundColor = tint.withAlphaComponent(0.12)

        let thickness: CGFloat = 2.5
        switch direction {
        case .left, .right:
            previewCrease.frame = CGRect(
                x: crease - thickness / 2,
                y: 8,
                width: thickness,
                height: bounds.height - 16
            )
        case .up, .down:
            previewCrease.frame = CGRect(
                x: 8,
                y: crease - thickness / 2,
                width: bounds.width - 16,
                height: thickness
            )
        }
        previewCrease.layer.cornerRadius = thickness / 2

        previewArrow.text = direction.symbol
        previewArrow.textColor = tint
        previewArrow.frame = CGRect(x: landing.midX - 32, y: landing.midY - 24, width: 64, height: 48)

        previewCaption.text = "\(direction.title.uppercased()) · \(outcome.caption.uppercased())"
        previewCaption.textColor = tint

        previewDirection = direction
        previewHost.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.14) {
            self.previewHost.alpha = 1
        }
        animatePreviewArrow(direction)
    }

    private func animatePreviewArrow(_ direction: FoldDirection) {
        previewArrow.layer.removeAllAnimations()
        previewArrow.transform = .identity
        let shift: CGPoint
        switch direction {
        case .left: shift = CGPoint(x: -12, y: 0)
        case .right: shift = CGPoint(x: 12, y: 0)
        case .up: shift = CGPoint(x: 0, y: -12)
        case .down: shift = CGPoint(x: 0, y: 12)
        }
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: [.repeat, .autoreverse, .curveEaseInOut, .allowUserInteraction]
        ) {
            self.previewArrow.transform = CGAffineTransform(translationX: shift.x, y: shift.y)
        }
    }

    private func hideFoldPreview() {
        guard previewDirection != nil else { return }
        previewDirection = nil
        previewArrow.layer.removeAllAnimations()
        previewArrow.transform = .identity
        UIView.animate(withDuration: 0.16) {
            self.previewHost.alpha = 0
        }
    }

    private func performFold(_ direction: FoldDirection) {
        isAnimating = true
        refreshLabels()
        HapticsManager.shared.mediumImpact()
        SoundManager.shared.playFold()

        let applyState = { [weak self] in
            guard let self else { return }
            self.currentGlyphs = self.foldedGlyphs(from: self.currentGlyphs, direction: direction)
            self.foldHistory.append(direction)
            self.glyphSnapshots.append(self.currentGlyphs)
            self.paintCells()
            self.pulseMatchedGlyphs()
            self.isAnimating = false
            self.refreshLabels()
            self.evaluateProgress()
        }

        if SettingsManager.shared.foldAnimationsEnabled {
            animatePaperFold(direction, completion: applyState)
        } else {
            applyState()
        }
    }

    private func animatePaperFold(_ direction: FoldDirection, completion: @escaping () -> Void) {
        let bounds = paperSheet.bounds
        guard bounds.width > 1, bounds.height > 1 else {
            completion()
            return
        }

        let crease = creaseOffset(for: direction)
        let flapFrame = flapRect(for: direction, crease: crease, in: bounds)
        guard flapFrame.width > 1, flapFrame.height > 1 else {
            completion()
            return
        }

        let snapshot = sheetSnapshot()

        let landingShadow = UIView(frame: landingRect(for: direction, crease: crease, in: bounds))
        landingShadow.backgroundColor = Palette.backgroundDeep
        landingShadow.alpha = 0
        landingShadow.isUserInteractionEnabled = false
        paperSheet.addSubview(landingShadow)

        let creaseGlow = makeCreaseGlow(for: direction, crease: crease, in: bounds)
        paperContainer.addSubview(creaseGlow)

        let flap = UIView(frame: flapFrame)
        flap.clipsToBounds = true
        flap.isUserInteractionEnabled = false

        let flapContent = UIImageView(image: snapshot)
        flapContent.frame = CGRect(
            x: -flapFrame.minX,
            y: -flapFrame.minY,
            width: bounds.width,
            height: bounds.height
        )
        flap.addSubview(flapContent)

        let flapShade = UIView(frame: flap.bounds)
        flapShade.alpha = 0
        flapShade.isUserInteractionEnabled = false
        let shadeGradient = CAGradientLayer()
        shadeGradient.frame = flap.bounds
        shadeGradient.colors = [
            UIColor.black.withAlphaComponent(0.12).cgColor,
            UIColor.black.withAlphaComponent(0.62).cgColor
        ]
        let shadePoints = shadeGradientPoints(for: direction)
        shadeGradient.startPoint = shadePoints.start
        shadeGradient.endPoint = shadePoints.end
        flapShade.layer.addSublayer(shadeGradient)
        flap.addSubview(flapShade)

        paperContainer.addSubview(flap)
        flap.layer.anchorPoint = flapAnchor(for: direction)
        flap.frame = flapFrame

        setMovingCellsHidden(true, direction: direction)

        let duration: CFTimeInterval = 0.5
        let angle = flapAngle(for: direction)

        let rotation = CAKeyframeAnimation(keyPath: rotationKeyPath(for: direction))
        rotation.values = [0, angle * 0.5, angle]
        rotation.keyTimes = [0, 0.5, 1]
        rotation.timingFunctions = [
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .easeOut)
        ]
        rotation.duration = duration
        rotation.fillMode = .forwards
        rotation.isRemovedOnCompletion = false

        UIView.animateKeyframes(withDuration: duration, delay: 0, options: [.calculationModeCubic]) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                flapShade.alpha = 1
                creaseGlow.alpha = 1
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                flapShade.alpha = 0.72
                landingShadow.alpha = 0.24
                creaseGlow.alpha = 0.35
            }
        }

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            flap.removeFromSuperview()
            creaseGlow.removeFromSuperview()
            guard let self else {
                landingShadow.removeFromSuperview()
                completion()
                return
            }
            self.setMovingCellsHidden(false, direction: direction)
            completion()
            UIView.animate(withDuration: 0.24) {
                landingShadow.alpha = 0
            } completion: { _ in
                landingShadow.removeFromSuperview()
            }
        }
        flap.layer.add(rotation, forKey: "fold")
        CATransaction.commit()
    }

    private func sheetSnapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: paperSheet.bounds)
        return renderer.image { _ in
            paperSheet.drawHierarchy(in: paperSheet.bounds, afterScreenUpdates: false)
        }
    }

    private func movingIndices(for direction: FoldDirection) -> Range<Int> {
        let size = level.gridSize
        let half = size / 2
        switch direction {
        case .left, .up:
            return (size - half)..<size
        case .right, .down:
            return 0..<half
        }
    }

    private func creaseOffset(for direction: FoldDirection) -> CGFloat {
        let size = level.gridSize
        let half = size / 2
        let isVerticalCrease = direction == .left || direction == .right
        let fallback = isVerticalCrease ? paperSheet.bounds.midX : paperSheet.bounds.midY

        guard half >= 1, cellViews.count == size, cellViews.allSatisfy({ $0.count == size }) else {
            return fallback
        }

        switch direction {
        case .left:
            return (cellViews[0][size - half - 1].frame.maxX + cellViews[0][size - half].frame.minX) / 2
        case .right:
            return (cellViews[0][half - 1].frame.maxX + cellViews[0][half].frame.minX) / 2
        case .up:
            return (cellViews[size - half - 1][0].frame.maxY + cellViews[size - half][0].frame.minY) / 2
        case .down:
            return (cellViews[half - 1][0].frame.maxY + cellViews[half][0].frame.minY) / 2
        }
    }

    private func flapRect(for direction: FoldDirection, crease: CGFloat, in bounds: CGRect) -> CGRect {
        switch direction {
        case .left:
            return CGRect(x: crease, y: 0, width: bounds.width - crease, height: bounds.height)
        case .right:
            return CGRect(x: 0, y: 0, width: crease, height: bounds.height)
        case .up:
            return CGRect(x: 0, y: crease, width: bounds.width, height: bounds.height - crease)
        case .down:
            return CGRect(x: 0, y: 0, width: bounds.width, height: crease)
        }
    }

    private func landingRect(for direction: FoldDirection, crease: CGFloat, in bounds: CGRect) -> CGRect {
        switch direction {
        case .left:
            return CGRect(x: 0, y: 0, width: crease, height: bounds.height)
        case .right:
            return CGRect(x: crease, y: 0, width: bounds.width - crease, height: bounds.height)
        case .up:
            return CGRect(x: 0, y: 0, width: bounds.width, height: crease)
        case .down:
            return CGRect(x: 0, y: crease, width: bounds.width, height: bounds.height - crease)
        }
    }

    private func flapAnchor(for direction: FoldDirection) -> CGPoint {
        switch direction {
        case .left:
            return CGPoint(x: 0, y: 0.5)
        case .right:
            return CGPoint(x: 1, y: 0.5)
        case .up:
            return CGPoint(x: 0.5, y: 0)
        case .down:
            return CGPoint(x: 0.5, y: 1)
        }
    }

    private func flapAngle(for direction: FoldDirection) -> CGFloat {
        switch direction {
        case .left, .down:
            return -.pi
        case .right, .up:
            return .pi
        }
    }

    private func rotationKeyPath(for direction: FoldDirection) -> String {
        switch direction {
        case .left, .right:
            return "transform.rotation.y"
        case .up, .down:
            return "transform.rotation.x"
        }
    }

    private func shadeGradientPoints(for direction: FoldDirection) -> (start: CGPoint, end: CGPoint) {
        switch direction {
        case .left:
            return (CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5))
        case .right:
            return (CGPoint(x: 1, y: 0.5), CGPoint(x: 0, y: 0.5))
        case .up:
            return (CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1))
        case .down:
            return (CGPoint(x: 0.5, y: 1), CGPoint(x: 0.5, y: 0))
        }
    }

    private func makeCreaseGlow(for direction: FoldDirection, crease: CGFloat, in bounds: CGRect) -> UIView {
        let thickness: CGFloat = 2
        let frame: CGRect
        switch direction {
        case .left, .right:
            frame = CGRect(x: crease - thickness / 2, y: 10, width: thickness, height: bounds.height - 20)
        case .up, .down:
            frame = CGRect(x: 10, y: crease - thickness / 2, width: bounds.width - 20, height: thickness)
        }

        let line = UIView(frame: frame)
        line.backgroundColor = Palette.primary
        line.alpha = 0
        line.isUserInteractionEnabled = false
        line.layer.cornerRadius = thickness / 2
        line.layer.shadowColor = Palette.primary.cgColor
        line.layer.shadowOpacity = 0.9
        line.layer.shadowRadius = 7
        line.layer.shadowOffset = .zero
        return line
    }

    private func setMovingCellsHidden(_ hidden: Bool, direction: FoldDirection) {
        let size = level.gridSize
        guard cellViews.count == size else { return }
        let indices = movingIndices(for: direction)

        for row in 0..<size {
            guard cellViews[row].count == size else { continue }
            for col in 0..<size {
                let isMoving: Bool
                switch direction {
                case .left, .right:
                    isMoving = indices.contains(col)
                case .up, .down:
                    isMoving = indices.contains(row)
                }
                if isMoving {
                    cellViews[row][col].isHidden = hidden
                }
            }
        }
    }

    private func pulseMatchedGlyphs() {
        let size = level.gridSize
        for row in 0..<size {
            for col in 0..<size {
                guard currentGlyphs[row][col] != nil,
                      let glyph = cellViews[row][col].viewWithTag(100),
                      !glyph.isHidden else { continue }
                glyph.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
                UIView.animate(
                    withDuration: 0.35,
                    delay: 0,
                    usingSpringWithDamping: 0.55,
                    initialSpringVelocity: 0.6
                ) {
                    glyph.transform = .identity
                }
            }
        }
    }

    private func foldedGlyphs(from source: [[Int?]], direction: FoldDirection) -> [[Int?]] {
        let size = source.count
        var result = source
        let half = size / 2

        switch direction {
        case .left:
            for row in 0..<size {
                for col in 0..<half {
                    let fromCol = size - 1 - col
                    result[row][col] = mergeGlyph(result[row][col], source[row][fromCol])
                    result[row][fromCol] = nil
                }
            }
        case .right:
            for row in 0..<size {
                for col in 0..<half {
                    let toCol = size - 1 - col
                    result[row][toCol] = mergeGlyph(result[row][toCol], source[row][col])
                    result[row][col] = nil
                }
            }
        case .up:
            for col in 0..<size {
                for row in 0..<half {
                    let fromRow = size - 1 - row
                    result[row][col] = mergeGlyph(result[row][col], source[fromRow][col])
                    result[fromRow][col] = nil
                }
            }
        case .down:
            for col in 0..<size {
                for row in 0..<half {
                    let toRow = size - 1 - row
                    result[toRow][col] = mergeGlyph(result[toRow][col], source[row][col])
                    result[row][col] = nil
                }
            }
        }
        return result
    }

    private func mergeGlyph(_ a: Int?, _ b: Int?) -> Int? {
        if let a, let b {
            return a == b ? a : b
        }
        return a ?? b
    }

    private func evaluateProgress() {
        if foldHistory == level.solution {
            finish(passed: true)
            return
        }
        if foldHistory.count >= level.foldsAllowed {
            finish(passed: false)
        }
    }

    private func flashProgressError() {
        let original = progressLabel.textColor
        progressLabel.textColor = Palette.danger
        UIView.animate(withDuration: 0.35, delay: 0.15, options: []) {
            self.progressLabel.textColor = original
        }
    }

    private func finish(passed: Bool) {
        isAnimating = true
        let perfect = passed && foldHistory == level.solution
        let base = (levelIndex + 1) * 1000
        let foldBonus = max(0, (level.foldsAllowed - foldHistory.count) * 150)
        let score = passed ? base + foldBonus + (perfect ? 250 : 0) : max(50, base / 10)

        let result = GameResult(
            levelIndex: levelIndex,
            score: score,
            foldsUsed: foldHistory.count,
            perfect: perfect,
            passed: passed,
            date: Date()
        )
        let isNewBest = DataManager.shared.submitScore(result)
        if passed {
            HapticsManager.shared.success()
            SoundManager.shared.playSuccess()
            paperSheet.layer.borderColor = Palette.success.cgColor
        } else {
            HapticsManager.shared.error()
            SoundManager.shared.playFail()
            paperSheet.layer.borderColor = Palette.danger.cgColor
            UIView.animate(withDuration: 0.08, delay: 0, options: [.autoreverse]) {
                self.paperSheet.transform = CGAffineTransform(translationX: -8, y: 0)
            } completion: { _ in
                self.paperSheet.transform = .identity
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self else { return }
            let results = ResultsViewController(result: result, levelTitle: self.level.title, isNewBest: isNewBest)
            self.navigationController?.pushViewController(results, animated: true)
        }
    }

    @objc private func undoTapped() {
        guard !isAnimating, !foldHistory.isEmpty else { return }
        HapticsManager.shared.lightImpact()
        SoundManager.shared.playTap()
        foldHistory.removeLast()
        glyphSnapshots.removeLast()
        currentGlyphs = glyphSnapshots.last ?? level.glyphs
        paintCells()
        refreshLabels()
        paperSheet.layer.borderColor = Palette.primary.withAlphaComponent(0.5).cgColor
        UIView.animate(withDuration: 0.2) {
            self.paperSheet.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.paperSheet.transform = .identity
            }
        }
    }

    @objc private func resetTapped() {
        guard !isAnimating else { return }
        HapticsManager.shared.warning()
        SoundManager.shared.playTap()
        cellViews.forEach { $0.forEach { $0.isHidden = false } }
        foldHistory.removeAll()
        currentGlyphs = level.glyphs
        glyphSnapshots = [currentGlyphs]
        paintCells()
        refreshLabels()
        paperSheet.layer.borderColor = Palette.primary.withAlphaComponent(0.5).cgColor
        paperSheet.transform = CGAffineTransform(rotationAngle: -0.04)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.paperSheet.transform = .identity
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
