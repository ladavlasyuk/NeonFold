import UIKit

enum Palette {
    static let background = UIColor(red: 0.04, green: 0.06, blue: 0.14, alpha: 1.0)
    static let backgroundDeep = UIColor(red: 0.02, green: 0.03, blue: 0.09, alpha: 1.0)
    static let primary = UIColor(red: 0.10, green: 0.92, blue: 0.95, alpha: 1.0)
    static let primaryDark = UIColor(red: 0.05, green: 0.55, blue: 0.72, alpha: 1.0)
    static let accent = UIColor(red: 0.95, green: 0.18, blue: 0.55, alpha: 1.0)
    static let accentSoft = UIColor(red: 0.78, green: 0.12, blue: 0.48, alpha: 1.0)
    static let gold = UIColor(red: 0.98, green: 0.82, blue: 0.28, alpha: 1.0)
    static let card = UIColor.white.withAlphaComponent(0.08)
    static let cardBorder = UIColor.white.withAlphaComponent(0.14)
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor.white.withAlphaComponent(0.65)
    static let danger = UIColor(red: 1.0, green: 0.32, blue: 0.38, alpha: 1.0)
    static let success = UIColor(red: 0.25, green: 0.92, blue: 0.55, alpha: 1.0)
    static let paper = UIColor(red: 0.10, green: 0.14, blue: 0.26, alpha: 1.0)
    static let paperEdge = UIColor(red: 0.18, green: 0.28, blue: 0.48, alpha: 1.0)
}

enum GlyphStyle {
    static let marks = ["✦", "◆", "▲", "✶", "＋", "◯"]

    static let colors: [UIColor] = [
        UIColor(red: 0.10, green: 0.92, blue: 0.95, alpha: 1.0),
        UIColor(red: 0.95, green: 0.18, blue: 0.55, alpha: 1.0),
        UIColor(red: 0.98, green: 0.82, blue: 0.28, alpha: 1.0),
        UIColor(red: 0.25, green: 0.92, blue: 0.55, alpha: 1.0),
        UIColor(red: 0.45, green: 0.70, blue: 1.0, alpha: 1.0),
        UIColor(red: 1.0, green: 0.45, blue: 0.28, alpha: 1.0)
    ]

    static func mark(for value: Int) -> String {
        guard value >= 1, value <= marks.count else { return "?" }
        return marks[value - 1]
    }

    static func color(for value: Int) -> UIColor {
        guard value >= 1, value <= colors.count else { return .white }
        return colors[value - 1]
    }
}

enum Theme {
    @discardableResult
    static func applyBackground(to view: UIView) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [
            Palette.backgroundDeep.cgColor,
            Palette.background.cgColor,
            UIColor(red: 0.07, green: 0.05, blue: 0.18, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        gradient.startPoint = CGPoint(x: 0.1, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.9, y: 1.0)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        return gradient
    }

    static func gradientButton(
        title: String,
        colors: [UIColor] = [Palette.primary, Palette.primaryDark],
        height: CGFloat = 54,
        fontSize: CGFloat = 18
    ) -> ThemeGradientButton {
        let button = ThemeGradientButton(colors: colors)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .heavy)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.setTitleColor(Palette.backgroundDeep, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        return button
    }

    static func flatButton(
        title: String,
        height: CGFloat = 50,
        fontSize: CGFloat = 16
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Palette.card
        button.layer.cornerRadius = 14
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = Palette.cardBorder.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        return button
    }

    static func backButton(target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = Palette.primary
        button.backgroundColor = Palette.card
        button.layer.cornerRadius = 18
        button.layer.cornerCurve = .continuous
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 36).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    static func iconButton(systemName: String, target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = Palette.primary
        button.backgroundColor = Palette.card
        button.layer.cornerRadius = 22
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = Palette.primary.withAlphaComponent(0.35).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}

final class ThemeGradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()

    init(colors: [UIColor]) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.86 : 1.0 }
    }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1.0 : 0.45 }
    }
}

final class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}
