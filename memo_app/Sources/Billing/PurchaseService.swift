import Foundation
import RevenueCat

/// RevenueCat entitlement identifier for Memo App. Must match the RevenueCat
/// dashboard exactly (project `UNCHAIN`) — case sensitive. Distinct from
/// BreakoutGame's `premium` entitlement, which already exists on the shared
/// Test Store app (see .kiro/specs/memo-app/tasks.md Implementation Notes 1.1).
enum RevenueCatEntitlements {
  static let premium = "memo_premium"
}

/// Memo App's dedicated (non-current) offering identifier. BreakoutGame
/// already owns the `default`/`is_current: true` offering on the shared Test
/// Store app, so Memo App must fetch by explicit identifier rather than
/// `Offerings.current` (see tasks.md Implementation Notes 1.1).
private let offeringIdentifier = "memo_app"

/// Public (client-safe) API key for the RevenueCat "Test Store" app used
/// during development. Shared with BreakoutGame — the UNCHAIN project has a
/// single Test Store app used by all its member apps (tasks.md
/// Implementation Notes 1.1). Swap for the real App Store `appl_...` key
/// once the app is registered in App Store Connect.
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

  /// Ties RevenueCat's subscriber identity to the signed-in Firebase user, so
  /// the backend and RevenueCat agree on the same identifier for a given
  /// user (`research.md` Decision).
  static func logIn(uid: String) async throws {
    _ = try await Purchases.shared.logIn(uid)
  }

  /// `Purchases.getOfferings` only ships a completion-handler overload in
  /// this SDK version (no bare `async throws` equivalent, unlike
  /// `purchase`/`restorePurchases`), so it is bridged manually here (same
  /// pattern as `my_first_swift_project`'s `PurchaseService`).
  static func fetchCurrentPackages() async -> [Package] {
    await withCheckedContinuation { continuation in
      Purchases.shared.getOfferings { offerings, error in
        if let error {
          print("RevenueCat getOfferings failed: \(error)")
        }
        let offering = offerings?.offering(identifier: offeringIdentifier)
        continuation.resume(returning: offering?.availablePackages ?? [])
      }
    }
  }

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
