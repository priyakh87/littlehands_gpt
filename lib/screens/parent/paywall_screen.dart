import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/play_time_service.dart';
import '../../services/subscription_service.dart';
import 'parent_gate.dart';

/// Opens the paywall behind the parent gate (required for kids' apps).
Future<void> openPremium(BuildContext context) async {
  if (!await showParentGate(context) || !context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PaywallScreen()),
  );
}

/// LittleHands Premium. Only reachable by grown-ups (after the parent gate).
/// Plans and prices come from the stores through RevenueCat.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  List<SubscriptionPlan>? _plans;
  SubscriptionPlan? _selected;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    PlayTimeService.instance.pause();
    _load();
  }

  @override
  void dispose() {
    PlayTimeService.instance.resume();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final plans = await SubscriptionService.plans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _selected =
            plans.where((p) => p.isAnnual).firstOrNull ?? plans.firstOrNull;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _plans = [];
        _error = "Couldn't load plans. Check the internet connection.";
      });
    }
  }

  Future<void> _run(Future<bool> Function() action, String successText) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final premium = await action();
      if (!mounted) return;
      if (premium) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successText)));
        Navigator.pop(context);
      } else {
        setState(() => _error = 'No active Premium subscription was found.');
      }
    } on PurchaseCancelled {
      // The grown-up backed out; nothing to show.
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LittleHands Premium')),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: SubscriptionService.isPremium,
          builder: (context, premium, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('👑', style: TextStyle(fontSize: 72))),
                const SizedBox(height: 8),
                Text(
                  premium
                      ? 'Premium is active'
                      : 'Unlock every level and story',
                  key: const ValueKey('paywall_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                for (final b in const [
                  'All levels in Color, Matching and ABC games',
                  'Every bedtime story',
                  'New activities as they are added',
                  'For all children on this device',
                  'No ads, ever',
                ])
                  ListTile(
                    dense: true,
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(b, style: const TextStyle(fontSize: 16)),
                  ),
                const SizedBox(height: 12),
                if (premium)
                  Text(
                    'Thank you! To change or cancel, use the subscriptions '
                    'section of your ${_storeName()} account.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  )
                else
                  ..._purchaseSection(),
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('restore'),
                  onPressed: _busy || !SubscriptionService.isConfigured
                      ? null
                      : () =>
                          _run(SubscriptionService.restore, 'Premium restored'),
                  child: const Text('Restore purchases'),
                ),
                const SizedBox(height: 8),
                _legal(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _purchaseSection() {
    if (!SubscriptionService.isConfigured) {
      return [
        Card(
          color: Colors.amber.shade50,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Subscriptions are not available in this build yet.',
              key: ValueKey('paywall_not_configured'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (kDebugMode) _debugToggle(),
      ];
    }
    final plans = _plans;
    if (plans == null) {
      return [const Center(child: CircularProgressIndicator())];
    }
    return [
      if (plans.isEmpty && _error == null)
        const Text('No plans are available right now.',
            textAlign: TextAlign.center),
      for (final plan in plans)
        Card(
          key: ValueKey('plan_${plan.id}'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _selected?.id == plan.id
                  ? Colors.deepPurple
                  : Colors.grey.shade300,
              width: _selected?.id == plan.id ? 3 : 1,
            ),
          ),
          child: ListTile(
            onTap: () => setState(() => _selected = plan),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(plan.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            subtitle: Text(
              [
                '${plan.price} ${plan.period}'.trim(),
                if (plan.trial != null) plan.trial!,
              ].join(' · '),
              style: const TextStyle(fontSize: 16),
            ),
            trailing: plan.isAnnual
                ? Chip(
                    label: const Text('Best value'),
                    backgroundColor: Colors.amber.shade100)
                : null,
          ),
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
        ),
      const SizedBox(height: 12),
      FilledButton(
        key: const ValueKey('subscribe'),
        onPressed: _busy || _selected == null
            ? null
            : () => _run(() => SubscriptionService.buy(_selected!),
                'Welcome to Premium!'),
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16)),
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(_selected?.trial != null ? 'Start free trial' : 'Subscribe',
                style: const TextStyle(fontSize: 18)),
      ),
    ];
  }

  Widget _debugToggle() => ValueListenableBuilder<bool>(
        valueListenable: SubscriptionService.debugPremium,
        builder: (context, on, _) => SwitchListTile(
          key: const ValueKey('debug_premium'),
          title: const Text('Developer: pretend Premium'),
          subtitle: const Text('Debug builds only'),
          value: on,
          onChanged: (v) => SubscriptionService.debugPremium.value = v,
        ),
      );

  String _storeName() {
    if (kIsWeb) return 'store';
    return Platform.isIOS ? 'Apple ID' : 'Google Play';
  }

  Widget _legal() {
    final links = [
      if (SubscriptionService.termsUrl.isNotEmpty)
        TextButton(
          onPressed: () => launchUrl(Uri.parse(SubscriptionService.termsUrl)),
          child: const Text('Terms of Use'),
        ),
      if (SubscriptionService.privacyUrl.isNotEmpty)
        TextButton(
          onPressed: () => launchUrl(Uri.parse(SubscriptionService.privacyUrl)),
          child: const Text('Privacy Policy'),
        ),
    ];
    return Column(
      children: [
        Text(
          'Payment is charged to your ${_storeName()} account. Subscriptions '
          'renew automatically unless cancelled at least 24 hours before the '
          'end of the current period. Manage or cancel any time in your '
          'account settings.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (links.isNotEmpty)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: links),
      ],
    );
  }
}
