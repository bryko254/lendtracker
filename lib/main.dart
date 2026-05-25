import 'package:flutter/material.dart';

import 'data/lend_repository.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LendTrackerApp());
}

class LendTrackerApp extends StatelessWidget {
  const LendTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = LendRepository();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B5E5A),
    );
    return MaterialApp(
      title: 'LendTracker',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F7F5),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0.8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F2EF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: const ChipThemeData(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: colorScheme.surface,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.black54,
          type: BottomNavigationBarType.fixed,
        ),
        useMaterial3: true,
      ),
      home: HomeShell(repository: repository),
    );
  }
}
