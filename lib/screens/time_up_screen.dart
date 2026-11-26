import 'package:flutter/material.dart';

import '../main.dart' show appNavigatorKey;
import '../services/parent_lock.dart';
import '../services/play_time_service.dart';
import '../services/profile_service.dart';
import '../services/tts_service.dart';
import '../widgets/pin_pad.dart';

/// Covers the whole app once today's play time is used up. A grown-up can
/// unlock it with the PIN to add extra minutes or switch to another child.
/// It is drawn above every page, so it needs no navigation of its own.
class TimeUpOverlay extends StatelessWidget {
  final Widget child;

  const TimeUpOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PlayTimeService.instance.timeUp,
      builder: (context, timeUp, _) => Stack(
        children: [
          child,
          if (timeUp) const Positioned.fill(child: TimeUpScreen()),
        ],
      ),
    );
  }
}

class TimeUpScreen extends StatefulWidget {
  const TimeUpScreen({super.key});

  @override
  State<TimeUpScreen> createState() => _TimeUpScreenState();
}

enum _View { rest, pin, options }

class _TimeUpScreenState extends State<TimeUpScreen> {
  _View _view = _View.rest;
  String? _error;

  String get _name => ProfileService.active.value?.name ?? 'friend';

  @override
  void initState() {
    super.initState();
    TtsService().speak(
        'Time for a break, $_name! You played so well today. See you tomorrow!',
        speed: NarrationSpeed.slow);
  }

  Future<void> _checkPin(String pin) async {
    if (await ParentLock.verify(pin)) {
      setState(() {
        _error = null;
        _view = _View.options;
      });
    } else {
      setState(() => _error = 'Wrong PIN. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('time_up'),
      color: const Color(0xFF1E2A5A),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: switch (_view) {
              _View.rest => _rest(),
              _View.pin => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PinPad(
                        title: 'Grown-ups only',
                        subtitle: 'Enter your parent PIN',
                        error: _error,
                        onCompleted: _checkPin,
                      ),
                      TextButton(
                        onPressed: () => setState(() => _view = _View.rest),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              _View.options => _options(),
            },
          ),
        ),
      ),
    );
  }

  Widget _rest() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🌙', style: TextStyle(fontSize: 96)),
        const SizedBox(height: 16),
        Text('Time for a break, $_name!',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 12),
        const Text('You played so well today.\nSee you tomorrow!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: Colors.white70)),
        const SizedBox(height: 40),
        TextButton.icon(
          key: const ValueKey('time_up_grownups'),
          onPressed: () => setState(() => _view = _View.pin),
          icon: const Icon(Icons.lock_rounded, color: Colors.white70),
          label: const Text('Grown-ups',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _options() {
    final others = ProfileService.profiles
        .where((p) => p.id != ProfileService.active.value?.id)
        .toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('More time for $_name today?',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          for (final m in const [15, 30])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton(
                key: ValueKey('extra_$m'),
                onPressed: () => PlayTimeService.instance.grantExtra(m),
                child: Text('+$m minutes'),
              ),
            ),
          for (final p in others)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () async {
                  // Close the previous child's activity, back to home.
                  appNavigatorKey.currentState?.popUntil((r) => r.isFirst);
                  await ProfileService.setActive(p.id);
                },
                child: Text('Switch to ${p.avatar} ${p.name}'),
              ),
            ),
          TextButton(
            onPressed: () => setState(() => _view = _View.rest),
            child: const Text('Done for today'),
          ),
        ],
      ),
    );
  }
}
