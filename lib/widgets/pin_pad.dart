import 'package:flutter/material.dart';

/// Big number keypad with dots, for the parent PIN and the grown-up
/// question. Calls [onCompleted] once [length] digits are entered, then
/// clears itself.
class PinPad extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? error;
  final int length;
  final ValueChanged<String> onCompleted;

  const PinPad({
    super.key,
    required this.title,
    this.subtitle,
    this.error,
    this.length = 4,
    required this.onCompleted,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _entered = '';

  void _press(String digit) {
    if (_entered.length >= widget.length) return;
    setState(() => _entered += digit);
    if (_entered.length == widget.length) {
      final value = _entered;
      Future.microtask(() {
        if (mounted) setState(() => _entered = '');
        widget.onCompleted(value);
      });
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          Text(widget.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _entered.length
                      ? Colors.deepPurple
                      : Colors.grey.shade300,
                ),
              ),
          ],
        ),
        SizedBox(
          height: 32,
          child: Center(
            child: Text(widget.error ?? '',
                key: const ValueKey('pin_error'),
                style: const TextStyle(color: Colors.red, fontSize: 16)),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '<'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final key in row) _key(key)],
          ),
      ],
    );
  }

  Widget _key(String key) {
    if (key.isEmpty) return const SizedBox(width: 88, height: 72);
    final isBack = key == '<';
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 76,
        height: 60,
        child: FilledButton.tonal(
          key: ValueKey('pin_key_$key'),
          style: FilledButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.zero,
          ),
          onPressed: isBack ? _backspace : () => _press(key),
          child: isBack
              ? const Icon(Icons.backspace_outlined, size: 26)
              : Text(key, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}
