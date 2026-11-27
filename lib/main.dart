import 'package:flutter/material.dart';

import 'models/child_profile.dart';
import 'screens/home_screen.dart';
import 'screens/time_up_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/play_time_service.dart';
import 'services/profile_service.dart';
import 'services/subscription_service.dart';

/// Entry point of the LittleHands application.
///
/// The app is fully offline: no API keys, no network calls and no
/// microphone. All content ships inside the app bundle, and profiles,
/// stars and play time are stored only on this device.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProfileService.load();
  PlayTimeService.instance.start();
  // Doesn't block startup; premium unlocks as soon as RevenueCat answers.
  SubscriptionService.init();
  runApp(const MyApp());
}

/// Lets screens outside the page stack (the time-up overlay) navigate.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Root widget for the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LittleHands',
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // The time-up screen sits above every page once today's limit is hit.
      builder: (context, child) => TimeUpOverlay(child: child!),
      home: const AppRoot(),
    );
  }
}

/// Shows first-run setup until a child profile exists, then the home
/// screen for the active child (rebuilt when the child changes).
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChildProfile?>(
      valueListenable: ProfileService.active,
      builder: (context, profile, _) => profile == null
          ? const WelcomeScreen()
          : HomeScreen(key: ValueKey(profile.id), profile: profile),
    );
  }
}
