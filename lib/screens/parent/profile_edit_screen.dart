import 'package:flutter/material.dart';

import '../../models/child_profile.dart';
import '../../services/play_time_service.dart';
import '../../services/profile_service.dart';

/// Add a new child (profile == null) or edit an existing one.
class ProfileEditScreen extends StatefulWidget {
  final ChildProfile? profile;

  const ProfileEditScreen({super.key, this.profile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.profile?.name ?? '');
  late String _avatar = widget.profile?.avatar ?? ChildProfile.avatars.first;
  late int _age = widget.profile?.age ?? 3;
  late int _limit = widget.profile?.dailyLimitMinutes ?? 30;

  bool get _isNew => widget.profile == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter the child's name")));
      return;
    }
    final profile = (widget.profile ??
            ChildProfile(
                id: ProfileService.newId(),
                name: name,
                avatar: _avatar,
                age: _age))
        .copyWith(
            name: name, avatar: _avatar, age: _age, dailyLimitMinutes: _limit);
    await ProfileService.save(profile);
    await PlayTimeService.instance.check();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final p = widget.profile!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${p.name}?'),
        content: const Text(
            "This deletes this child's stars and progress on this device. "
            'It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              key: const ValueKey('confirm_delete'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    await ProfileService.delete(p.id);
    await PlayTimeService.instance.check();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = !_isNew && ProfileService.profiles.length > 1;
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Add a child' : 'Edit child')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              key: const ValueKey('profile_name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: "Child's name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const _Label('Picture'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in ChildProfile.avatars)
                  ChoiceChip(
                    key: ValueKey('avatar_$a'),
                    label: Text(a, style: const TextStyle(fontSize: 28)),
                    selected: _avatar == a,
                    onSelected: (_) => setState(() => _avatar = a),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const _Label('Age'),
            Wrap(
              spacing: 8,
              children: [
                for (final age in ChildProfile.ages)
                  ChoiceChip(
                    key: ValueKey('age_$age'),
                    label: Text('$age', style: const TextStyle(fontSize: 18)),
                    selected: _age == age,
                    onSelected: (_) => setState(() => _age = age),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const _Label('Daily play time'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in ChildProfile.limitOptions)
                  ChoiceChip(
                    key: ValueKey('limit_$m'),
                    label: Text(m == 0 ? 'No limit' : '$m min',
                        style: const TextStyle(fontSize: 16)),
                    selected: _limit == m,
                    onSelected: (_) => setState(() => _limit = m),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              key: const ValueKey('profile_save'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_isNew ? 'Add child' : 'Save',
                  style: const TextStyle(fontSize: 18)),
            ),
            if (canDelete) ...[
              const SizedBox(height: 12),
              TextButton(
                key: const ValueKey('profile_delete'),
                onPressed: _delete,
                child: const Text('Remove this child',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      );
}
