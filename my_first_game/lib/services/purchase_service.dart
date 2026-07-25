import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement identifiers. Must match the RevenueCat dashboard
/// (project `UNCHAIN`) exactly — these are case sensitive.
class RevenueCatEntitlements {
  static const premium = 'premium';
  static const weeklyChallenge = 'weekly_challenge';
}

/// RevenueCat package identifiers inside the `default` offering.
class RevenueCatPackages {
  static const unlockAll = r'$rc_custom_unlock_all';
  static const continueToken = r'$rc_custom_continue_token';
  static const weeklyChallenge = r'$rc_weekly';
}

/// `purchases_flutter` only supports iOS and Android. Other targets (web,
/// macOS, etc.) stay usable for local Flutter development, they just skip
/// every purchase-related call.
bool get isPurchasesSupported =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid);

/// Public (client-safe) API key for the RevenueCat "Test Store" app used
/// during development. Test Store keys are safe to embed in client code.
/// Swap this for the real App Store `appl_...` key once the app is
/// registered in App Store Connect (see docs/ios-setup.md).
const String _revenueCatApiKey = 'test_sddznTcTAozgeMzKYctdrgEfZZq';

Future<void> configurePurchases() async {
  if (!isPurchasesSupported) return;
  await Purchases.setLogLevel(LogLevel.debug);
  await Purchases.configure(PurchasesConfiguration(_revenueCatApiKey));
}

sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

class Purchased extends PurchaseOutcome {
  const Purchased();
}

class Cancelled extends PurchaseOutcome {
  const Cancelled();
}

class PurchaseFailed extends PurchaseOutcome {
  final Object error;
  const PurchaseFailed(this.error);
}

Future<List<Package>> fetchCurrentPackages() async {
  if (!isPurchasesSupported) return const [];
  final offerings = await Purchases.getOfferings();
  return offerings.current?.availablePackages ?? const [];
}

/// Purchases [package]. Does not unlock any content itself — entitlement
/// state flows through [GameSession]'s `CustomerInfoUpdateListener so the
/// purchase path and the restore path share one source of truth. Callers
/// that need to react to a specific *consumable* purchase (which has no
/// entitlement) should do so based on the returned [Purchased] outcome.
Future<PurchaseOutcome> purchase(Package package) async {
  try {
    await Purchases.purchase(PurchaseParams.package(package));
    return const Purchased();
  } on PlatformException catch (e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    if (code == PurchasesErrorCode.purchaseCancelledError) {
      return const Cancelled();
    }
    return PurchaseFailed(e);
  }
}

Future<CustomerInfo?> restorePurchases() async {
  if (!isPurchasesSupported) return null;
  try {
    return await Purchases.restorePurchases();
  } on PlatformException {
    return null;
  }
}
