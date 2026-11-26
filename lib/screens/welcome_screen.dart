import 'package:flutter/material.dart';

import 'parent/parent_gate.dart';
import 'parent/profile_edit_screen.dart';

/// First launch: a grown-up creates the parent PIN and the first child.
/// Once a child exists the app switches to the home screen by itself.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _setUp(BuildContext context) async {
    final ok = await showParentGate(context);
    if (!ok || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👋', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                const Text('Welcome to LittleHands',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(
                  'A grown-up needs to set things up first: a parent PIN '
                  "and your child's name and age.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  key: const ValueKey('welcome_start'),
                  onPressed: () => _setUp(context),
                  icon: const Icon(Icons.lock_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Text("Let's set up", style: TextStyle(fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
