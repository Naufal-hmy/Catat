import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';

class TaskStorage {
  static const String _tasksKey = 'my_task_app_tasks_v1';
  static const String _themeKey = 'app_theme_mode_pref';

  static Future<List<TaskItem>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_tasksKey);
      if (savedData != null && savedData.isNotEmpty) {
        final decoded = jsonDecode(savedData) as List<dynamic>;
        return decoded
            .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // In case of parsing error, return empty list
    }
    return [];
  }

  static Future<bool> saveTasks(List<TaskItem> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(tasks.map((task) => task.toJson()).toList());
      return await prefs.setString(_tasksKey, encoded);
    } catch (_) {
      return false;
    }
  }

  static Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_themeKey);
      if (modeStr == 'light') return ThemeMode.light;
      if (modeStr == 'dark') return ThemeMode.dark;
      return ThemeMode.system;
    } catch (_) {
      return ThemeMode.system;
    }
  }

  static Future<bool> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String value = 'system';
      if (mode == ThemeMode.light) value = 'light';
      if (mode == ThemeMode.dark) value = 'dark';
      return await prefs.setString(_themeKey, value);
    } catch (_) {
      return false;
    }
  }

  /// Default starter tasks for demonstration if the user opens a brand new clean database
  static List<TaskItem> getStarterTasks() {
    final now = DateTime.now();
    return [
      TaskItem(
        id: 'starter_1',
        title: 'Review materi ujian Pemrograman Mobile',
        course: 'Pemrograman Mobile',
        deadline: DateTime(now.year, now.month, now.day, 16, 0),
        priority: TaskPriority.high,
        notes: 'Pelajari konsep State Management, Layout Responsive, dan Material 3.',
        isCompleted: false,
      ),
      TaskItem(
        id: 'starter_2',
        title: 'Kumpulkan laporan praktikum basis data',
        course: 'Basis Data Lanjut',
        deadline: DateTime(now.year, now.month, now.day + 1, 23, 59),
        priority: TaskPriority.medium,
        notes: 'Format PDF, pastikan ERD dan query SQL disertakan dengan rapi.',
        isCompleted: false,
      ),
      TaskItem(
        id: 'starter_3',
        title: 'Diskusi kelompok perancangan antarmuka',
        course: 'Interaksi Manusia & Komputer',
        deadline: DateTime(now.year, now.month, now.day + 2, 10, 0),
        priority: TaskPriority.low,
        notes: 'Evaluasi aksesibilitas aplikasi untuk semua rentang usia.',
        isCompleted: true,
      ),
    ];
  }
}
