import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// One subscription option shown on the paywall (prices come from the
/// App Store / Google Play via RevenueCat, never from this code).
class SubscriptionPlan {
  final String id;
  final String title;
  final String price; // e.g. "$4.99"
  final String period; // e.g. "per month"
  final String? trial; // e.g. "7-day free trial"
  final bool isAnnual;
  final Object? raw; // the RevenueCat Package

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    this.trial,
    this.isAnnual = false,
    this.raw,
  });
}

class PurchaseCancelled implements Exception {}

/// Where purchases actually happen. RevenueCat in the app; a fake in tests.
abstract class SubscriptionBackend {
  bool get isConfigured;
  Future<void> init(void Function(bool premium) onPremiumChanged);
  Future<List<SubscriptionPlan>> plans();

  /// Returns whether premium is active afterwards.
  /// Throws [PurchaseCancelled] if the grown-up backed out.
  Future<bool> buy(SubscriptionPlan plan);
  Future<bool> restore();
}

/// Premium access through RevenueCat. API keys are passed at build time:
///   flutter run --dart-define=REVENUECAT_IOS_KEY=appl_xxx
///               --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
/// Without a key the app still runs; only the free content is available.
class SubscriptionService {
  /// The entitlement identifier created in the RevenueCat dashboard.
  static const entitlementId = 'premium';

  static const _iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const _androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

  /// Links Apple requires on a subscription screen. Set at build time.
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');

  static final ValueNotifier<bool> isPremium = ValueNotifier(false);

  /// Debug builds only: lets developers test premium content without
  /// buying. Has no effect in release builds.
  static final ValueNotifier<bool> debugPremium = ValueNotifier(false);

  static SubscriptionBackend _backend = RevenueCatBackend(
    defaultTargetPlatform == TargetPlatform.iOS ? _iosKey : _androidKey,
  );
  static bool _storePremium = false;
  static Future<void>? _ready;

  static bool get isConfigured => _backend.isConfigured;

  static Future<void> init() => _ready ??= _init();

  static Future<void> _init() async {
    debugPremium.addListener(_update);
    try {
      await _backend.init((premium) {
        _storePremium = premium;
        _update();
      });
    } catch (e) {
      debugPrint('Subscriptions unavailable: $e');
    }
  }

  static void _update() =>
      isPremium.value = _storePremium || (kDebugMode && debugPremium.value);

  static Future<List<SubscriptionPlan>> plans() async {
    await init();
    if (!isConfigured) return [];
    return _backend.plans();
  }

  static Future<bool> buy(SubscriptionPlan plan) async {
    await init();
    _storePremium = await _backend.buy(plan);
    _update();
    return isPremium.value;
  }

  static Future<bool> restore() async {
    await init();
    _storePremium = await _backend.restore();
    _update();
    return isPremium.value;
  }

  @visibleForTesting
  static void useBackend(SubscriptionBackend backend) {
    _backend = backend;
    _ready = null;
    _storePremium = false;
    debugPremium.removeListener(_update);
    debugPremium.value = false;
    isPremium.value = false;
  }
}

class RevenueCatBackend implements SubscriptionBackend {
  final String apiKey;
  RevenueCatBackend(this.apiKey);

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  static bool _hasPremium(CustomerInfo info) =>
      info.entitlements.active.containsKey(SubscriptionService.entitlementId);

  @override
  Future<void> init(void Function(bool premium) onPremiumChanged) async {
    if (!isConfigured) return;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    // Anonymous RevenueCat user id: no names, emails or accounts.
    await Purchases.configure(PurchasesConfiguration(apiKey));
    Purchases.addCustomerInfoUpdateListener(
        (info) => onPremiumChanged(_hasPremium(info)));
    onPremiumChanged(_hasPremium(await Purchases.getCustomerInfo()));
  }

  @override
  Future<List<SubscriptionPlan>> plans() async {
    final offering = (await Purchases.getOfferings()).current;
    if (offering == null) return [];
    return offering.availablePackages.map(_toPlan).toList();
  }

  static SubscriptionPlan _toPlan(Package p) {
    final product = p.storeProduct;
    final period = switch (p.packageType) {
      PackageType.annual => 'per year',
      PackageType.sixMonth => 'every 6 months',
      PackageType.threeMonth => 'every 3 months',
      PackageType.twoMonth => 'every 2 months',
      PackageType.monthly => 'per month',
      PackageType.weekly => 'per week',
      PackageType.lifetime => 'one-time purchase',
      _ => '',
    };
    final intro = product.introductoryPrice;
    String? trial;
    if (intro != null && intro.price == 0) {
      final unit = switch (intro.periodUnit) {
        PeriodUnit.day => 'day',
        PeriodUnit.week => 'week',
        PeriodUnit.month => 'month',
        PeriodUnit.year => 'year',
        PeriodUnit.unknown => '',
      };
      trial = '${intro.periodNumberOfUnits}-$unit free trial';
    }
    return SubscriptionPlan(
      id: p.identifier,
      title: switch (p.packageType) {
        PackageType.annual => 'Yearly',
        PackageType.monthly => 'Monthly',
        PackageType.weekly => 'Weekly',
        PackageType.lifetime => 'Lifetime',
        _ => product.title,
      },
      price: product.priceString,
      period: period,
      trial: trial,
      isAnnual: p.packageType == PackageType.annual,
      raw: p,
    );
  }

  @override
  Future<bool> buy(SubscriptionPlan plan) async {
    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(plan.raw as Package));
      return _hasPremium(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        throw PurchaseCancelled();
      }
      rethrow;
    }
  }

  @override
  Future<bool> restore() async =>
      _hasPremium(await Purchases.restorePurchases());
}
