import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait orientation for standard mobile puzzle experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MouseMazeApp());
}

class MouseMazeApp extends StatelessWidget {
  const MouseMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mouse Stealth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
