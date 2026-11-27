import 'package:littlehands_gpt/services/subscription_service.dart';

/// In-memory store for tests: no RevenueCat, no network.
class FakeSubscriptions implements SubscriptionBackend {
  bool premium;
  bool configured;
  bool cancelNext = false;
  bool restorable = false;
  final List<SubscriptionPlan> available;

  FakeSubscriptions({
    this.premium = false,
    this.configured = true,
    this.available = const [
      SubscriptionPlan(
          id: 'monthly',
          title: 'Monthly',
          price: r'$4.99',
          period: 'per month'),
      SubscriptionPlan(
          id: 'annual',
          title: 'Yearly',
          price: r'$39.99',
          period: 'per year',
          trial: '7-day free trial',
          isAnnual: true),
    ],
  });

  SubscriptionPlan? bought;

  @override
  bool get isConfigured => configured;

  @override
  Future<void> init(void Function(bool premium) onPremiumChanged) async =>
      onPremiumChanged(premium);

  @override
  Future<List<SubscriptionPlan>> plans() async => available;

  @override
  Future<bool> buy(SubscriptionPlan plan) async {
    if (cancelNext) throw PurchaseCancelled();
    bought = plan;
    return premium = true;
  }

  @override
  Future<bool> restore() async => premium = restorable;
}

Future<FakeSubscriptions> useFakeSubscriptions({bool premium = false}) async {
  final fake = FakeSubscriptions(premium: premium);
  SubscriptionService.useBackend(fake);
  await SubscriptionService.init();
  return fake;
}
