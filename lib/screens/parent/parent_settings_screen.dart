import 'package:flutter/material.dart';

import '../../models/child_profile.dart';
import '../../services/play_time_service.dart';
import '../../services/profile_service.dart';
import 'parent_gate.dart';
import 'profile_edit_screen.dart';

/// Grown-ups area (opened only after the parent gate): manage children,
/// their daily play time, and the parent PIN. Play time is not counted
/// while this screen is open.
class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  Map<String, int> _minutesToday = {};

  @override
  void initState() {
    super.initState();
    PlayTimeService.instance.pause();
    _refresh();
  }

  @override
  void dispose() {
    PlayTimeService.instance.resume();
    super.dispose();
  }

  Future<void> _refresh() async {
    final minutes = <String, int>{};
    for (final p in ProfileService.profiles) {
      minutes[p.id] =
          (await PlayTimeService.instance.playedSecondsToday(p)) ~/ 60;
    }
    if (mounted) setState(() => _minutesToday = minutes);
  }

  Future<void> _edit([ChildProfile? profile]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileEditScreen(profile: profile)),
    );
    await _refresh();
  }

  String _limitText(ChildProfile p) => p.dailyLimitMinutes == 0
      ? 'No limit'
      : '${p.dailyLimitMinutes} min a day';

  @override
  Widget build(BuildContext context) {
    final profiles = ProfileService.profiles;
    final activeId = ProfileService.active.value?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Grown-ups')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text('Children',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            for (final p in profiles)
              Card(
                key: ValueKey('settings_child_${p.id}'),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Text(p.avatar, style: const TextStyle(fontSize: 40)),
                  title: Text(
                    p.id == activeId ? '${p.name} (playing now)' : p.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Age ${p.age} · ${_limitText(p)} · '
                    'Today ${_minutesToday[p.id] ?? 0} min',
                  ),
                  trailing: const Icon(Icons.edit_rounded),
                  onTap: () => _edit(p),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('add_child'),
              onPressed: () => _edit(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add a child'),
            ),
            const Divider(height: 40),
            ListTile(
              key: const ValueKey('change_pin'),
              leading: const Icon(Icons.pin_rounded),
              title: const Text('Change parent PIN'),
              onTap: () async {
                final changed = await showParentGate(context, changePin: true);
                if (changed && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Parent PIN changed')));
                }
              },
            ),
            const ListTile(
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('Privacy'),
              subtitle:
                  Text('Everything stays on this device. LittleHands has no '
                      'accounts, ads or tracking.'),
            ),
          ],
        ),
      ),
    );
  }
}
