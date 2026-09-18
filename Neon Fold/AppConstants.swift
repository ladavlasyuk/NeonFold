import Foundation

enum AppConstants {
    static let appsFlyerDevKey = "7tBWQ5RqN6RMhUaZzw3eTc"
    static let appsFlyerAppleAppID = "6803721044"

    static var bundleID: String {
        Bundle.main.bundleIdentifier ?? "com.NeonFoldSpatialPuzzle"
    }
    static var storeID: String {
        "id\(appsFlyerAppleAppID)"
    }

    static let configEndpoint = "https://neonfoldspatialpuzzle.online/config.php"

    static let privacyPolicyAddress = "https://neonfoldspatialpuzzle.online/privacy-policy.html"

    static let osName = "IOS"
    static let pushTokenPlaceholder = "00000000000000000000"
    static let firebaseProjectID = "732675778161"

    static let gcdRetryDelay: TimeInterval = 1.0
    static let mergeWaitInterval: TimeInterval = 3.0
    static let launchLoaderDuration: TimeInterval = 15.0

    static let pushPermissionRetryDelay: TimeInterval = 60 * 60 * 24 * 3

    static let pushDataAddressKey = "url"
}
