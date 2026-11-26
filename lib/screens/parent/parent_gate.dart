import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/parent_lock.dart';
import '../../widgets/pin_pad.dart';

/// Asks for the parent PIN (or creates one the first time).
/// Returns true only if a grown-up got through.
Future<bool> showParentGate(BuildContext context,
    {bool changePin = false}) async {
  final ok = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ParentGateScreen(changePin: changePin),
    ),
  );
  return ok ?? false;
}

enum _Stage { loading, create, confirm, verify, forgot }

class ParentGateScreen extends StatefulWidget {
  /// Skip verification and go straight to choosing a new PIN
  /// (used after the gate has already been passed).
  final bool changePin;

  const ParentGateScreen({super.key, this.changePin = false});

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  final _random = Random();
  _Stage _stage = _Stage.loading;
  String? _error;
  String? _firstEntry;
  int _a = 7, _b = 8;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasPin = await ParentLock.hasPin();
    if (!mounted) return;
    setState(() =>
        _stage = (widget.changePin || !hasPin) ? _Stage.create : _Stage.verify);
  }

  Future<void> _onPin(String value) async {
    switch (_stage) {
      case _Stage.create:
        setState(() {
          _firstEntry = value;
          _error = null;
          _stage = _Stage.confirm;
        });
      case _Stage.confirm:
        if (value == _firstEntry) {
          await ParentLock.setPin(value);
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() {
            _error = "Those didn't match. Try again.";
            _stage = _Stage.create;
          });
        }
      case _Stage.verify:
        if (await ParentLock.verify(value)) {
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() => _error = 'Wrong PIN. Try again.');
        }
      case _Stage.forgot:
        if (int.tryParse(value) == _a * _b) {
          setState(() {
            _error = null;
            _stage = _Stage.create;
          });
        } else {
          setState(() => _error = 'Not quite. Try again.');
        }
      case _Stage.loading:
        break;
    }
  }

  void _startForgot() {
    setState(() {
      _a = 6 + _random.nextInt(4); // 6..9
      _b = 6 + _random.nextInt(4);
      _error = null;
      _stage = _Stage.forgot;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_stage) {
      case _Stage.loading:
        body = const CircularProgressIndicator();
      case _Stage.create:
        body = PinPad(
          key: const ValueKey('create'),
          title: 'Create a parent PIN',
          subtitle: 'Choose 4 numbers. This keeps settings for grown-ups only.',
          error: _error,
          onCompleted: _onPin,
        );
      case _Stage.confirm:
        body = PinPad(
          key: const ValueKey('confirm'),
          title: 'Enter the PIN again',
          error: _error,
          onCompleted: _onPin,
        );
      case _Stage.verify:
        body = PinPad(
          key: const ValueKey('verify'),
          title: 'Grown-ups only',
          subtitle: 'Enter your parent PIN',
          error: _error,
          onCompleted: _onPin,
        );
      case _Stage.forgot:
        body = PinPad(
          key: const ValueKey('forgot'),
          title: 'What is $_a × $_b?',
          subtitle: 'Answer to set a new PIN',
          error: _error,
          length: 2,
          onCompleted: _onPin,
        );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('gate_close'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Text('🔒', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                body,
                if (_stage == _Stage.verify)
                  TextButton(
                    key: const ValueKey('forgot_pin'),
                    onPressed: _startForgot,
                    child: const Text('Forgot PIN?'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
