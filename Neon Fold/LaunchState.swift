import Foundation
import Combine

final class LaunchState: ObservableObject {
    static let shared = LaunchState()

    static let didChangeNotification = NSNotification.Name("LaunchStateDidChange")
    static let pushOpenRequestedNotification = NSNotification.Name("LaunchStatePushOpenRequested")

    @Published var browserDestination: String? {
        didSet { notifyChange() }
    }
    @Published var isPrePermissionVisible: Bool = false {
        didSet { notifyChange() }
    }
    @Published var noInternetMessage: String? {
        didSet { notifyChange() }
    }

    private func notifyChange() {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: LaunchState.didChangeNotification, object: nil)
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: LaunchState.didChangeNotification, object: nil)
            }
        }
    }

    private let destinationKey = "saved_browser_destination"
    private let expiresKey = "saved_browser_destination_expires"
    private let payloadKey = "saved_config_payload"
    private let permanentNativeKey = "permanent_native_flow"
    private let pushDestinationKey = "saved_push_destination"
    private let installMarkerKey = "app_install_initialized"
    private let firstServerDecisionRecordedKey = "first_server_decision_recorded"
    private let firstServerDecisionHasLinkKey = "first_server_decision_has_link"

    private(set) var pendingDestination: String?
    private(set) var didOpenPushDestination = false
    private(set) var activePushAddress: String?
    private(set) var didCommitLaunchDestination = false
    private var shouldForceBrowserReload = false

    private init() {}

    func resetPersistentStateOnFreshInstallIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: installMarkerKey) else { return }

        defaults.set(true, forKey: installMarkerKey)

        defaults.removeObject(forKey: destinationKey)
        defaults.removeObject(forKey: expiresKey)
        defaults.removeObject(forKey: payloadKey)
        defaults.removeObject(forKey: permanentNativeKey)
        defaults.removeObject(forKey: pushDestinationKey)
        defaults.removeObject(forKey: firstServerDecisionRecordedKey)
        defaults.removeObject(forKey: firstServerDecisionHasLinkKey)
        defaults.removeObject(forKey: "push_permission_last_decline")
        defaults.removeObject(forKey: "stored_fcm_token")
        defaults.removeObject(forKey: "last_sent_push_token_in_config")
        defaults.removeObject(forKey: "push_permission_granted")

        pendingDestination = nil
        browserDestination = nil
        isPrePermissionVisible = false
        noInternetMessage = nil
        didOpenPushDestination = false
        activePushAddress = nil
        didCommitLaunchDestination = false
        shouldForceBrowserReload = false
    }

    func discardPersistedPushDestination() {
        UserDefaults.standard.removeObject(forKey: pushDestinationKey)
    }

    func markDidOpenPushDestination() {
        didOpenPushDestination = true
    }

    func isPushSessionBlockingConfigPresentation() -> Bool {
        didOpenPushDestination || activePushAddress != nil
    }

    func requestForceBrowserReload() {
        shouldForceBrowserReload = true
    }

    func consumeForceBrowserReload() -> Bool {
        let value = shouldForceBrowserReload
        shouldForceBrowserReload = false
        return value
    }

    @discardableResult
    func acceptPushAddress(_ address: String) -> Bool {
        guard !isPermanentNativeFlow() else { return false }
        guard !address.isEmpty else { return false }

        activePushAddress = address
        markDidOpenPushDestination()
        didCommitLaunchDestination = true
        requestForceBrowserReload()

        browserDestination = address
        NotificationCenter.default.post(
            name: LaunchState.pushOpenRequestedNotification,
            object: nil,
            userInfo: ["address": address]
        )

        NotificationHandler.shared.shouldShowPrePermission { [weak self] shouldShow in
            guard let self else { return }
            if shouldShow {
                self.pendingDestination = address
                self.browserDestination = nil
                self.isPrePermissionVisible = true
            }
        }
        return true
    }

    func isStoredDestinationExpired(now: TimeInterval = Date().timeIntervalSince1970) -> Bool {
        guard let destination = UserDefaults.standard.string(forKey: destinationKey), !destination.isEmpty else {
            return true
        }
        return UserDefaults.standard.double(forKey: expiresKey) <= now
    }

    @discardableResult
    func openUnexpiredStoredDestination() -> Bool {
        guard !isPermanentNativeFlow(), !isPushSessionBlockingConfigPresentation(), !didCommitLaunchDestination else {
            return false
        }
        guard !isStoredDestinationExpired(),
              let destination = UserDefaults.standard.string(forKey: destinationKey),
              !destination.isEmpty else {
            return false
        }
        didCommitLaunchDestination = true
        prepareToOpenBrowser(destination, forceReload: false)
        return true
    }

    @discardableResult
    func openLastSuccessfulDestination() -> Bool {
        guard !isPermanentNativeFlow(), !isPushSessionBlockingConfigPresentation() else { return false }
        guard let destination = UserDefaults.standard.string(forKey: destinationKey), !destination.isEmpty else {
            return false
        }
        didCommitLaunchDestination = true
        requestForceBrowserReload()
        let previous = browserDestination
        browserDestination = destination
        if previous == destination {
            NotificationCenter.default.post(
                name: LaunchState.pushOpenRequestedNotification,
                object: nil,
                userInfo: ["address": destination]
            )
        }
        return true
    }

    func saveDestination(_ destination: String, expires: TimeInterval) {
        guard !isPermanentNativeFlow() else { return }
        UserDefaults.standard.set(destination, forKey: destinationKey)
        UserDefaults.standard.set(expires, forKey: expiresKey)
        if isPushSessionBlockingConfigPresentation() || didCommitLaunchDestination {
            return
        }
        didCommitLaunchDestination = true
        prepareToOpenBrowser(destination, forceReload: false)
    }

    func persistDestinationWithoutOpening(_ destination: String, expires: TimeInterval) {
        guard !isPermanentNativeFlow() else { return }
        UserDefaults.standard.set(destination, forKey: destinationKey)
        UserDefaults.standard.set(expires, forKey: expiresKey)
    }

    func hasStoredDestination() -> Bool {
        guard !isPermanentNativeFlow() else { return false }
        guard let destination = UserDefaults.standard.string(forKey: destinationKey) else {
            return false
        }
        return !destination.isEmpty
    }

    func hasOpenableDestination() -> Bool {
        hasStoredDestination()
    }

    func clearStoredDestination() {
        UserDefaults.standard.removeObject(forKey: destinationKey)
        UserDefaults.standard.removeObject(forKey: expiresKey)
    }

    func saveConfigPayload(_ payload: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        UserDefaults.standard.set(data, forKey: payloadKey)
    }

    func storedConfigPayload() -> [String: Any]? {
        guard let data = UserDefaults.standard.data(forKey: payloadKey),
              let json = try? JSONSerialization.jsonObject(with: data),
              let payload = json as? [String: Any] else { return nil }
        return payload
    }

    func isPermanentNativeFlow() -> Bool {
        UserDefaults.standard.bool(forKey: permanentNativeKey)
    }

    func lockPermanentNativeFlow() {
        UserDefaults.standard.set(true, forKey: permanentNativeKey)
        clearStoredDestination()
        browserDestination = nil
    }

    func recordFirstServerDecision(hasValidLink: Bool) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: firstServerDecisionRecordedKey) else { return }

        defaults.set(true, forKey: firstServerDecisionRecordedKey)
        defaults.set(hasValidLink, forKey: firstServerDecisionHasLinkKey)

        if !hasValidLink {
            lockPermanentNativeFlow()
        }
    }

    func showNoInternetMessage() {
        if browserDestination != nil || isPushSessionBlockingConfigPresentation() || didCommitLaunchDestination {
            return
        }
        noInternetMessage = "No internet connection. Please turn on the internet and open the app again."
    }

    func prepareToOpenBrowser(_ destination: String, forceReload: Bool = false) {
        if forceReload {
            requestForceBrowserReload()
        }
        NotificationHandler.shared.shouldShowPrePermission { [weak self] shouldShow in
            guard let self = self else { return }
            if shouldShow {
                self.pendingDestination = destination
                self.browserDestination = nil
                self.isPrePermissionVisible = true
            } else {
                self.pendingDestination = nil
                self.isPrePermissionVisible = false
                self.browserDestination = destination
            }
        }
    }

    func confirmPrePermissionAndOpen() {
        let target = pendingDestination
        pendingDestination = nil
        isPrePermissionVisible = false
        if let target = target {
            browserDestination = target
        }
    }
}
