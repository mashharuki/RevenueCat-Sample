import Foundation
import RevenueCat

/// RevenueCat entitlement identifiers. Must match the RevenueCat dashboard
/// (project `UNCHAIN`) exactly — these are case sensitive.
enum RevenueCatEntitlements {
    static let premium = "premium"
    static let weeklyChallenge = "weekly_challenge"
}

/// RevenueCat package identifiers inside the `default` offering.
enum RevenueCatPackages {
    static let unlockAll = "$rc_custom_unlock_all"
    static let continueToken = "$rc_custom_continue_token"
    static let weeklyChallenge = "$rc_weekly"
}

/// Public (client-safe) API key for the RevenueCat "Test Store" app used
/// during development. Test Store keys are safe to embed in client code.
/// Swap this for the real App Store `appl_...` key once the app is
/// registered in App Store Connect (see docs/ios-setup.md).
private let revenueCatAPIKey = "test_sddznTcTAozgeMzKYctdrgEfZZq"

enum PurchaseOutcome {
    case purchased
    case cancelled
    case failed(Error)
}

enum PurchaseService {
    static func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: revenueCatAPIKey)
    }

    /// `Purchases.getOfferings` only ships a completion-handler overload in
    /// this SDK version (no bare `async throws` equivalent, unlike
    /// `purchase`/`restorePurchases`), so it is bridged manually here.
    static func fetchCurrentPackages() async -> [Package] {
        await withCheckedContinuation { continuation in
            Purchases.shared.getOfferings { offerings, error in
                if let error {
                    print("RevenueCat getOfferings failed: \(error)")
                }
                continuation.resume(returning: offerings?.current?.availablePackages ?? [])
            }
        }
    }

    /// Purchases `package`. Does not unlock any content itself — entitlement
    /// state flows through `GameViewModel.observeEntitlements()` so the
    /// purchase path and the restore path share one source of truth. Callers
    /// that need to react to a specific *consumable* purchase (which has no
    /// entitlement) should do so based on the returned `.purchased` case.
    static func purchase(_ package: Package) async -> PurchaseOutcome {
        do {
            let params = PurchaseParams.Builder(package: package).build()
            let result = try await Purchases.shared.purchase(params)
            if result.userCancelled {
                return .cancelled
            }
            return .purchased
        } catch {
            let nsError = error as NSError
            if nsError.code == ErrorCode.purchaseCancelledError.rawValue {
                return .cancelled
            }
            return .failed(error)
        }
    }

    static func restore() async -> Result<CustomerInfo, Error> {
        do {
            let info = try await Purchases.shared.restorePurchases()
            return .success(info)
        } catch {
            return .failure(error)
        }
    }
}
