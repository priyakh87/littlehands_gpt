import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// Entry point of the LittleHands application.
///
/// The app is fully offline: no API keys, no network calls and no
/// microphone. All content ships inside the app bundle.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Root widget for the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LittleHands',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
