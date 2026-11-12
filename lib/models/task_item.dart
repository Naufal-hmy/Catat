enum TaskPriority { low, medium, high }

enum TaskFilter {
  all,
  today,
  calendar,
  pending,
  completed,
  highPriority,
}

enum TaskSortBy {
  deadlineAsc,
  priorityDesc,
  titleAsc,
}

class SubTask {
  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final bool isCompleted;

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.course,
    required this.deadline,
    required this.priority,
    required this.notes,
    required this.isCompleted,
    this.subtasks = const [],
  });

  final String id;
  final String title;
  final String course;
  final DateTime deadline;
  final TaskPriority priority;
  final String notes;
  final bool isCompleted;
  final List<SubTask> subtasks;

  int get totalSubtasks => subtasks.length;
  int get completedSubtasksCount =>
      subtasks.where((s) => s.isCompleted).length;

  double get progress {
    if (subtasks.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }
    return completedSubtasksCount / subtasks.length;
  }

  int get progressPercent => (progress * 100).round();

  TaskItem copyWith({
    String? id,
    String? title,
    String? course,
    DateTime? deadline,
    TaskPriority? priority,
    String? notes,
    bool? isCompleted,
    List<SubTask>? subtasks,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      course: course ?? this.course,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'course': course,
        'deadline': deadline.toIso8601String(),
        'priority': priority.name,
        'notes': notes,
        'isCompleted': isCompleted,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      course: json['course'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      notes: (json['notes'] as String?) ?? '',
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((item) => SubTask.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    return deadline.isBefore(now);
  }

  bool get isDueToday {
    final now = DateTime.now();
    return deadline.year == now.year &&
        deadline.month == now.month &&
        deadline.day == now.day;
  }

  bool get isDueTomorrow {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return deadline.year == tomorrow.year &&
        deadline.month == tomorrow.month &&
        deadline.day == tomorrow.day;
  }

  bool isSameDay(DateTime other) {
    return deadline.year == other.year &&
        deadline.month == other.month &&
        deadline.day == other.day;
  }

  String get relativeDeadlineText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(deadline.year, deadline.month, deadline.day);
    final diffDays = dueDay.difference(today).inDays;
    final timeStr =
        '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';

    if (isCompleted) {
      return 'Selesai';
    }
    if (diffDays < 0) {
      final daysLate = diffDays.abs();
      return 'Terlambat $daysLate hari • $timeStr';
    }
    if (diffDays == 0) {
      return 'Hari ini • $timeStr';
    }
    if (diffDays == 1) {
      return 'Besok • $timeStr';
    }
    if (diffDays == 2) {
      return 'Lusa • $timeStr';
    }
    return '${formatIndonesianDate(deadline)} • $timeStr';
  }

  static String formatIndonesianDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
