import 'package:flutter/material.dart';
import 'services/task_storage.dart';
import 'theme/app_theme.dart';
import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyTaskApp());
}

class MyTaskApp extends StatefulWidget {
  const MyTaskApp({super.key});

  @override
  State<MyTaskApp> createState() => _MyTaskAppState();
}

class _MyTaskAppState extends State<MyTaskApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final savedMode = await TaskStorage.loadThemeMode();
    if (mounted) {
      setState(() => _themeMode = savedMode);
    }
  }

  void _onThemeChanged(ThemeMode newMode) {
    setState(() => _themeMode = newMode);
    TaskStorage.saveThemeMode(newMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Tugas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: HomePage(
        currentThemeMode: _themeMode,
        onThemeChanged: _onThemeChanged,
      ),
    );
  }
}
