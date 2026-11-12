import 'package:flutter/material.dart';
import '../../models/task_item.dart';
import '../../theme/app_theme.dart';

class NotificationModal extends StatelessWidget {
  const NotificationModal({
    super.key,
    required this.tasks,
    required this.onSelectTask,
  });

  final List<TaskItem> tasks;
  final ValueChanged<TaskItem> onSelectTask;

  static void show(
    BuildContext context, {
    required List<TaskItem> tasks,
    required ValueChanged<TaskItem> onSelectTask,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
            child: NotificationModal(tasks: tasks, onSelectTask: onSelectTask),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => FractionallySizedBox(
          heightFactor: 0.8,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: NotificationModal(tasks: tasks, onSelectTask: onSelectTask),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final overdueTasks = tasks.where((t) => t.isOverdue).toList();
    final todayTasks = tasks.where((t) => t.isDueToday && !t.isCompleted).toList();
    final tomorrowTasks = tasks.where((t) => t.isDueTomorrow && !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).take(3).toList();

    final totalAlerts = overdueTasks.length + todayTasks.length + tomorrowTasks.length;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Notifikasi & Pengingat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '$totalAlerts pengingat aktif memerlukan tindakan',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Notifications List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              // 1. Overdue Alerts
              if (overdueTasks.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Perhatian: Melewati Deadline (${overdueTasks.length})',
                  color: const Color(0xFFDC2626),
                  icon: Icons.error_outline_rounded,
                ),
                ...overdueTasks.map((t) => _buildNotificationCard(
                      context: context,
                      task: t,
                      badgeText: 'Terlambat',
                      badgeColor: const Color(0xFFDC2626),
                      badgeBg: const Color(0xFFFEE2E2),
                      isDark: isDark,
                    )),
                const SizedBox(height: 16),
              ],

              // 2. Due Today Alerts
              if (todayTasks.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Jatuh Tempo Hari Ini (${todayTasks.length})',
                  color: const Color(0xFFD97706),
                  icon: Icons.alarm_rounded,
                ),
                ...todayTasks.map((t) => _buildNotificationCard(
                      context: context,
                      task: t,
                      badgeText: 'Hari ini',
                      badgeColor: const Color(0xFFD97706),
                      badgeBg: const Color(0xFFFEF3C7),
                      isDark: isDark,
                    )),
                const SizedBox(height: 16),
              ],

              // 3. Due Tomorrow
              if (tomorrowTasks.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Tenggat Waktu Besok (${tomorrowTasks.length})',
                  color: const Color(0xFF2563EB),
                  icon: Icons.event_available_rounded,
                ),
                ...tomorrowTasks.map((t) => _buildNotificationCard(
                      context: context,
                      task: t,
                      badgeText: 'Besok',
                      badgeColor: const Color(0xFF2563EB),
                      badgeBg: const Color(0xFFDBEAFE),
                      isDark: isDark,
                    )),
                const SizedBox(height: 16),
              ],

              // 4. Completed History
              if (completedTasks.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Tugas Selesai Baru-baru Ini',
                  color: const Color(0xFF16A34A),
                  icon: Icons.check_circle_outline_rounded,
                ),
                ...completedTasks.map((t) => _buildNotificationCard(
                      context: context,
                      task: t,
                      badgeText: 'Selesai',
                      badgeColor: const Color(0xFF16A34A),
                      badgeBg: const Color(0xFFDCFCE7),
                      isDark: isDark,
                    )),
              ],

              if (totalAlerts == 0 && completedTasks.isEmpty) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada notifikasi saat ini',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semua deadline tugas Anda berada dalam jadwal yang rapi.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required TaskItem task,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required bool isDark,
  }) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            onSelectTask(task);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${task.course} • ${task.relativeDeadlineText}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? badgeColor.withValues(alpha: 0.18) : badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
