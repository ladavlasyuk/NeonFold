import UIKit
import WebKit
import AVFoundation

final class ContentBrowserController: UIViewController {
    private static var liveInstanceCount = 0
    private static let sharedProcessPool = WKProcessPool()

    var destination: String = ""

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        ContentBrowserController.liveInstanceCount += 1
        print("[Browser] ContentBrowserController CREATED — live instances: \(ContentBrowserController.liveInstanceCount)")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        ContentBrowserController.liveInstanceCount += 1
        print("[Browser] ContentBrowserController CREATED (coder) — live instances: \(ContentBrowserController.liveInstanceCount)")
    }

    deinit {
        ContentBrowserController.liveInstanceCount -= 1
        print("[Browser] ContentBrowserController DEINIT — live instances: \(ContentBrowserController.liveInstanceCount)")
    }

    private var contentView: WKWebView!
    private var loadingOverlay: UIView!
    private var loadingIndicator: UIActivityIndicatorView!
    private var loadingBackgroundImageView: UIImageView!
    private var loadingIndicatorCenterY: NSLayoutConstraint?
    private var navigationCoordinator: ContentNavigationCoordinator!
    private var hasFinishedInitialLoad = false

    private var errorView: UIView?
    private var errorMessageLabel: UILabel?
    private var didAutoRetryAfterFailure = false
    private var hasLoadedMainContent = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationCoordinator = ContentNavigationCoordinator(controller: self)
        setupContentView()
        syncCookiesFromStorage()
        setupLoadingOverlay()
        loadDestination()
    }

    private func setupContentView() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.processPool = ContentBrowserController.sharedProcessPool
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsAirPlayForMediaPlayback = true

        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences

        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences

        let disableZoomSource = """
        var meta = document.querySelector('meta[name=viewport]');
        if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            (document.head || document.getElementsByTagName('head')[0]).appendChild(meta);
        }
        meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no');
        """
        let disableZoomScript = WKUserScript(source: disableZoomSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(disableZoomScript)

        contentView = WKWebView(frame: .zero, configuration: configuration)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.navigationDelegate = navigationCoordinator
        contentView.uiDelegate = navigationCoordinator
        contentView.scrollView.contentInsetAdjustmentBehavior = .never
        contentView.allowsBackForwardNavigationGestures = true
        contentView.backgroundColor = .black
        contentView.isOpaque = false
        contentView.scrollView.delegate = navigationCoordinator
        contentView.scrollView.bouncesZoom = false
        contentView.scrollView.pinchGestureRecognizer?.isEnabled = false

        view.backgroundColor = .black
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    private func setupLoadingOverlay() {
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
        loadingOverlay.addSubview(loadingIndicator)

        let centerY = loadingIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor)
        loadingIndicatorCenterY = centerY

        NSLayoutConstraint.activate([
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

        loadingIndicator.startAnimating()
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

    private func loadDestination() {
        guard let address = URL(string: destination) else {
            finishInitialLoading()
            return
        }
        hideErrorView()
        hasLoadedMainContent = false
        navigationCoordinator.lastNavigatedAddress = address
        var request = URLRequest(url: address)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        contentView.load(request)

        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            guard let self = self else { return }
            if !self.hasLoadedMainContent && self.contentView.url == nil {
                print("[Browser] Load timed out with no content — showing error screen")
                self.showErrorView(message: "Can't reach the server right now.\nPlease try again later.")
            } else {
                self.finishInitialLoading()
            }
        }
    }

    func markMainContentLoaded() {
        hasLoadedMainContent = true
        finishInitialLoading()
    }

    func reload(address: URL) {
        var request = URLRequest(url: address)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        contentView.load(request)
    }

    func handleMainFrameLoadFailure(_ error: NSError) {
        if !didAutoRetryAfterFailure {
            didAutoRetryAfterFailure = true
            print("[Browser] Main-frame load failed (\(error.code)) — auto-retrying once")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.reloadDestination()
            }
            return
        }
        print("[Browser] Main-frame load failed again (\(error.code)) — showing error screen")
        showErrorView(message: errorMessage(for: error))
    }

    private func reloadDestination() {
        guard let address = navigationCoordinator.lastNavigatedAddress ?? URL(string: destination) else {
            return
        }
        var request = URLRequest(url: address)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        contentView.load(request)
    }

    private func errorMessage(for error: NSError) -> String {
        if error.domain == NSURLErrorDomain {
            switch error.code {
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection.\nCheck your network and try again."
            case NSURLErrorTimedOut:
                return "The connection timed out.\nPlease try again."
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed:
                return "Can't reach the server right now.\nPlease try again later."
            default:
                break
            }
        }
        return "Couldn't load the page.\nPlease try again."
    }

    func finishInitialLoading() {
        guard !hasFinishedInitialLoad else { return }
        hasFinishedInitialLoad = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let overlay = self.loadingOverlay else { return }
            self.loadingIndicator.stopAnimating()
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0
            }, completion: { _ in
                overlay.isHidden = true
            })
        }
    }

    func requestCameraAccessIfNeeded() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                print("[Browser] Camera access granted: \(granted)")
            }
        }
        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                print("[Browser] Microphone access granted: \(granted)")
            }
        }
    }

    func syncCookiesFromStorage() {
        let store = WKWebsiteDataStore.default().httpCookieStore
        for cookie in HTTPCookieStorage.shared.cookies ?? [] {
            store.setCookie(cookie)
        }
    }

    private func showErrorView(message: String) {
        finishInitialLoading()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let existing = self.errorView {
                self.errorMessageLabel?.text = message
                existing.isHidden = false
                self.view.bringSubviewToFront(existing)
                return
            }

            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = .black

            let backgroundImageView = UIImageView()
            backgroundImageView.contentMode = .scaleAspectFill
            backgroundImageView.clipsToBounds = true
            backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
            backgroundImageView.image = UIImage(named: "LoadingBackground")
            container.addSubview(backgroundImageView)

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .white
            label.font = .systemFont(ofSize: 17, weight: .medium)
            label.text = message
            container.addSubview(label)

            let retryButton = UIButton(type: .system)
            retryButton.translatesAutoresizingMaskIntoConstraints = false
            retryButton.setTitle("Retry", for: .normal)
            retryButton.setTitleColor(.white, for: .normal)
            retryButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            retryButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            retryButton.layer.cornerRadius = 12
            retryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 28, bottom: 12, right: 28)
            retryButton.addTarget(self, action: #selector(self.retryButtonTapped), for: .touchUpInside)
            container.addSubview(retryButton)

            self.view.addSubview(container)
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: self.view.topAnchor),
                container.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                container.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),

                backgroundImageView.topAnchor.constraint(equalTo: container.topAnchor),
                backgroundImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                backgroundImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                backgroundImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),

                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32),
                label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32),

                retryButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                retryButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24)
            ])

            self.errorView = container
            self.errorMessageLabel = label
        }
    }

    private func hideErrorView() {
        errorView?.isHidden = true
    }

    @objc private func retryButtonTapped() {
        didAutoRetryAfterFailure = false
        hasFinishedInitialLoad = false
        hasLoadedMainContent = false
        loadingOverlay?.isHidden = false
        loadingOverlay?.alpha = 1
        loadingIndicator?.startAnimating()
        hideErrorView()
        loadDestination()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.unlockAllOrientations()
        setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OrientationController.shared.unlockAllOrientations()
        setNeedsUpdateOfSupportedInterfaceOrientations()
        UIViewController.attemptRotationToDeviceOrientation()
    }
}

final class ContentNavigationCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {
    weak var controller: ContentBrowserController?
    var lastNavigatedAddress: URL?

    init(controller: ContentBrowserController) {
        self.controller = controller
    }

    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        controller?.requestCameraAccessIfNeeded()
        decisionHandler(.grant)
    }

    func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale != 1.0 {
            scrollView.zoomScale = 1.0
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard isTargetFrameNil(for: navigationAction),
              let address = safeRequestURL(from: navigationAction) else {
            if isTargetFrameNil(for: navigationAction) {
                print("[Browser] createWebViewWith: targetFrame=nil but request address could not be resolved")
            }
            return nil
        }
        lastNavigatedAddress = address

        if webView.backForwardList.backList.isEmpty {
            replaceCurrentHistoryEntry(in: webView, with: address)
        } else {
            webView.load(noCacheRequest(for: address))
        }
        return nil
    }

    private func noCacheRequest(for address: URL) -> URLRequest {
        var request = URLRequest(url: address)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return request
    }

    private func replaceCurrentHistoryEntry(in webView: WKWebView, with address: URL) {
        guard let encoded = try? JSONEncoder().encode(address.absoluteString),
              let literal = String(data: encoded, encoding: .utf8) else {
            webView.load(noCacheRequest(for: address))
            return
        }
        webView.evaluateJavaScript("location.replace(\(literal));") { [weak self] _, error in
            if error != nil {
                self?.controller?.reload(address: address)
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.isForMainFrame,
           let httpResponse = navigationResponse.response as? HTTPURLResponse {
            let status = httpResponse.statusCode
            let url = httpResponse.url?.absoluteString ?? "?"
            if status >= 400 {
                print("[Browser] Main-frame HTTP \(status) for \(url) — server refused the request (not an app error)")
            } else {
                print("[Browser] Main-frame HTTP \(status) for \(url)")
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        controller?.markMainContentLoaded()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        print("[Browser] didFail navigation: \(nsError.localizedDescription) (\(nsError.domain) \(nsError.code))")
        if isCancellation(nsError) {
            controller?.finishInitialLoading()
            return
        }
        controller?.handleMainFrameLoadFailure(nsError)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        print("[Browser] didFailProvisionalNavigation: \(nsError.localizedDescription) (\(nsError.domain) \(nsError.code))")
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorHTTPTooManyRedirects {
            let failingAddress = (nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL) ?? lastNavigatedAddress
            if let address = failingAddress {
                webView.load(noCacheRequest(for: address))
                return
            }
        }
        if isCancellation(nsError) {
            controller?.finishInitialLoading()
            return
        }
        controller?.handleMainFrameLoadFailure(nsError)
    }

    private func isCancellation(_ error: NSError) -> Bool {
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            return true
        }
        if error.domain == "WebKitErrorDomain" && (error.code == 102 || error.code == 101) {
            return true
        }
        return false
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        controller?.finishInitialLoading()
        if let address = lastNavigatedAddress {
            webView.load(noCacheRequest(for: address))
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let address = safeRequestURL(from: navigationAction) else {
            decisionHandler(.allow)
            return
        }

        let scheme = address.scheme?.lowercased()

        let inAppSchemes: Set<String> = ["http", "https", "about", "blob", "data", "file"]
        let isInApp = scheme.map { inAppSchemes.contains($0) } ?? false

        if isInApp {
            lastNavigatedAddress = address
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
        openDeepLinkExternally(address)
    }

    private func safeRequestURL(from navigationAction: WKNavigationAction) -> URL? {
        if #available(iOS 18.0, *) {
            return navigationAction.request.url
        }

        let obj = navigationAction as NSObject

        if let request = obj.value(forKey: "request") as? NSURLRequest {
            return request.url
        }

        if let url = obj.value(forKeyPath: "request.URL") as? URL {
            return url
        }
        if let nsURL = obj.value(forKeyPath: "request.URL") as? NSURL {
            return nsURL as URL
        }
        if let absolute = obj.value(forKeyPath: "request.URL.absoluteString") as? String,
           let url = URL(string: absolute) {
            return url
        }
        if let mainDocURL = obj.value(forKeyPath: "request.mainDocumentURL") as? URL {
            return mainDocURL
        }
        if let mainDocNSURL = obj.value(forKeyPath: "request.mainDocumentURL") as? NSURL {
            return mainDocNSURL as URL
        }

        let selector = NSSelectorFromString("request")
        if obj.responds(to: selector),
           let unmanaged = obj.perform(selector),
           let request = unmanaged.takeUnretainedValue() as? NSURLRequest {
            return request.url
        }

        print("[Browser] Legacy safeRequestURL failed to resolve URL from WKNavigationAction")
        return nil
    }

    private func isTargetFrameNil(for navigationAction: WKNavigationAction) -> Bool {
        if #available(iOS 18.0, *) {
            return navigationAction.targetFrame == nil
        }

        let obj = navigationAction as NSObject
        let selector = NSSelectorFromString("targetFrame")
        guard obj.responds(to: selector) else {
            return false
        }
        return obj.perform(selector) == nil
    }

    private func openDeepLinkExternally(_ address: URL) {
        UIApplication.shared.open(address, options: [:]) { [weak self] success in
            if success { return }
            print("[Browser] Unable to open deep link externally: \(address.absoluteString)")

            guard let fallback = self?.strippedSafariSchemeAddress(from: address) else { return }
            print("[Browser] Retrying with stripped scheme: \(fallback.absoluteString)")
            UIApplication.shared.open(fallback, options: [:]) { fallbackSuccess in
                if !fallbackSuccess {
                    print("[Browser] Fallback open also failed: \(fallback.absoluteString)")
                }
            }
        }
    }

    /// Some SDKs (e.g. attribution redirects) prefix links with "x-safari-https"/"x-safari-http"
    /// to force opening in Safari specifically. That private scheme is undocumented and does not
    /// resolve on every iOS version (notably iOS 16), which makes `UIApplication.open` fail
    /// outright. As a fallback, strip the "x-safari-" prefix and open the plain http(s) URL so the
    /// link still opens in the user's default browser instead of silently doing nothing.
    private func strippedSafariSchemeAddress(from address: URL) -> URL? {
        guard let scheme = address.scheme?.lowercased(), scheme.hasPrefix("x-safari-") else {
            return nil
        }
        let strippedScheme = String(scheme.dropFirst("x-safari-".count))
        guard strippedScheme == "http" || strippedScheme == "https" else { return nil }

        var components = URLComponents(url: address, resolvingAgainstBaseURL: false)
        components?.scheme = strippedScheme
        return components?.url
    }
}
