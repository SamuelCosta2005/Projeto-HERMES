import 'package:flutter/material.dart';
import 'screens/materials_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HermesApp());
}

class HermesApp extends StatelessWidget {
  const HermesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hermes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MaterialsScreen(),
    );
  }
}
