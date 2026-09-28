import UIKit
import WebKit

final class PrivacyPolicyViewController: UIViewController {
    private let addressString: String

    private var contentView: WKWebView!
    private var loadingIndicator: UIActivityIndicatorView!
    private var loadingOverlay: UIView!
    private var loadingBackgroundImageView: UIImageView!
    private var loadingIndicatorCenterY: NSLayoutConstraint?

    init(addressString: String) {
        self.addressString = addressString
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadContent()
    }

    private func setupUI() {
        title = "Privacy Policy"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .done,
            target: self,
            action: #selector(closeTapped)
        )

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        contentView = WKWebView(frame: .zero, configuration: configuration)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.allowsBackForwardNavigationGestures = true
        contentView.scrollView.contentInsetAdjustmentBehavior = .never
        contentView.navigationDelegate = self
        view.addSubview(contentView)

        loadingOverlay = UIView()
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.backgroundColor = .black
        view.addSubview(loadingOverlay)

        loadingBackgroundImageView = UIImageView()
        loadingBackgroundImageView.contentMode = .scaleAspectFill
        loadingBackgroundImageView.clipsToBounds = true
        loadingBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(loadingBackgroundImageView)

        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .white
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingOverlay.addSubview(loadingIndicator)

        let centerY = loadingIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor)
        loadingIndicatorCenterY = centerY

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            loadingBackgroundImageView.topAnchor.constraint(equalTo: loadingOverlay.topAnchor),
            loadingBackgroundImageView.bottomAnchor.constraint(equalTo: loadingOverlay.bottomAnchor),
            loadingBackgroundImageView.leadingAnchor.constraint(equalTo: loadingOverlay.leadingAnchor),
            loadingBackgroundImageView.trailingAnchor.constraint(equalTo: loadingOverlay.trailingAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            centerY
        ])

        updateLoadingLayout(for: view.bounds.size)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateLoadingLayout(for: size)
    }

    private func updateLoadingLayout(for size: CGSize) {
        let isLandscape = size.width > size.height
        loadingBackgroundImageView?.image = UIImage(named: isLandscape ? "LoadingBackgroundLandscape" : "LoadingBackground")
        loadingIndicatorCenterY?.constant = isLandscape ? 70 : 0
    }

    private func hideLoadingOverlay() {
        loadingIndicator.stopAnimating()
        guard let overlay = loadingOverlay, !overlay.isHidden else { return }
        UIView.animate(withDuration: 0.2, animations: {
            overlay.alpha = 0
        }, completion: { _ in
            overlay.isHidden = true
        })
    }

    private func loadContent() {
        guard let address = URL(string: addressString) else { return }
        var request = URLRequest(url: address)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        loadingIndicator.startAnimating()
        contentView.load(request)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension PrivacyPolicyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideLoadingOverlay()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideLoadingOverlay()
    }
}
