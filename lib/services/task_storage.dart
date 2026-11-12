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

  /// Varied sample tasks for thorough testing
  static List<TaskItem> getStarterTasks() {
    final now = DateTime.now();
    return [
      TaskItem(
        id: 'starter_1',
        title: 'Project UTS Pemrograman Mobile - Redesign UI/UX',
        course: 'Pemrograman Mobile',
        deadline: DateTime(now.year, now.month, now.day, 18, 0),
        priority: TaskPriority.high,
        notes: 'Implementasi responsif Desktop & Mobile, Dark Mode, Subtask progress, dan Grafik Statistik.',
        isCompleted: false,
        subtasks: [
          const SubTask(id: 's1_1', title: 'Perancangan palet warna Dark/Light nyaman di mata', isCompleted: true),
          const SubTask(id: 's1_2', title: 'Desain layout adaptif Desktop Sidebar & Mobile AppBar', isCompleted: true),
          const SubTask(id: 's1_3', title: 'Fitur checklist subtask & grafik persentase', isCompleted: true),
          const SubTask(id: 's1_4', title: 'Kalender deadline & panel notifikasi', isCompleted: false),
          const SubTask(id: 's1_5', title: 'Push ke repositori GitHub Naufal-hmy', isCompleted: false),
        ],
      ),
      TaskItem(
        id: 'starter_2',
        title: 'Tugas Makalah Machine Learning & Deep Learning',
        course: 'Kecerdasan Buatan',
        deadline: DateTime(now.year, now.month, now.day + 1, 23, 59),
        priority: TaskPriority.high,
        notes: 'Bandingkan arsitektur CNN vs Vision Transformer untuk klasifikasi citra medis.',
        isCompleted: false,
        subtasks: [
          const SubTask(id: 's2_1', title: 'Cari 5 paper rujukan IEEE / Scopus', isCompleted: true),
          const SubTask(id: 's2_2', title: 'Susun BAB 1 Pendahuluan & Rumusan Masalah', isCompleted: true),
          const SubTask(id: 's2_3', title: 'Analisis komparasi akurasi model', isCompleted: false),
          const SubTask(id: 's2_4', title: 'Kesimpulan dan Daftar Pustaka format APA', isCompleted: false),
        ],
      ),
      TaskItem(
        id: 'starter_3',
        title: 'Praktikum Normalisasi Database & Query SQL',
        course: 'Basis Data Lanjut',
        deadline: DateTime(now.year, now.month, now.day - 1, 14, 30),
        priority: TaskPriority.medium,
        notes: 'Tugas telah melewati tenggat waktu kemarin, selesaikan revisi sebelum dosen input nilai.',
        isCompleted: false,
        subtasks: [
          const SubTask(id: 's3_1', title: 'Normalisasi tabel hingga bentuk 3NF', isCompleted: true),
          const SubTask(id: 's3_2', title: 'Optimasi query join dan indexing', isCompleted: false),
          const SubTask(id: 's3_3', title: 'Export diagram skema relasional', isCompleted: false),
        ],
      ),
      TaskItem(
        id: 'starter_4',
        title: 'Dokumentasi Software Requirement Specification (SRS)',
        course: 'Rekayasa Perangkat Lunak',
        deadline: DateTime(now.year, now.month, now.day + 3, 16, 0),
        priority: TaskPriority.medium,
        notes: 'Format standar IEEE 830, lengkapi Use Case Diagram dan Activity Diagram.',
        isCompleted: false,
        subtasks: [
          const SubTask(id: 's4_1', title: 'Wawancara kebutuhan pengguna sistem', isCompleted: true),
          const SubTask(id: 's4_2', title: 'Pembuatan diagram Use Case & narasi', isCompleted: false),
          const SubTask(id: 's4_3', title: 'Spesifikasi kebutuhan fungsional & non-fungsional', isCompleted: false),
        ],
      ),
      TaskItem(
        id: 'starter_5',
        title: 'Uji Aksesibilitas Heuristic Usability Testing',
        course: 'Interaksi Manusia & Komputer',
        deadline: DateTime(now.year, now.month, now.day + 5, 12, 0),
        priority: TaskPriority.low,
        notes: 'Evaluasi kontras warna WCAG AAA dan ukuran tap target untuk ramah semua batasan umur.',
        isCompleted: true,
        subtasks: [
          const SubTask(id: 's5_1', title: 'Audit kontras teks mode terang & gelap', isCompleted: true),
          const SubTask(id: 's5_2', title: 'Pastikan target sentuh tombol minimal 48dp', isCompleted: true),
          const SubTask(id: 's5_3', title: 'Lakukan user testing dengan pengguna beragam usia', isCompleted: true),
        ],
      ),
      TaskItem(
        id: 'starter_6',
        title: 'Simulasi Routing OSPF & Konfigurasi VLAN',
        course: 'Jaringan Komputer',
        deadline: DateTime(now.year, now.month, now.day + 7, 21, 0),
        priority: TaskPriority.low,
        notes: 'File lab Packet Tracer (.pkt) dan video screen recording pengujian ping.',
        isCompleted: false,
        subtasks: [
          const SubTask(id: 's6_1', title: 'Subnetting IPv4 CIDR /26', isCompleted: true),
          const SubTask(id: 's6_2', title: 'Konfigurasi switch VLAN 10 dan 20', isCompleted: false),
          const SubTask(id: 's6_3', title: 'Verifikasi ping antar router gateway', isCompleted: false),
        ],
      ),
    ];
  }
}
