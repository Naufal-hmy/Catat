import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/task_item.dart';
import '../../theme/app_theme.dart';

class DashboardStatsChart extends StatelessWidget {
  const DashboardStatsChart({
    super.key,
    required this.tasks,
  });

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final surfaceSecondary =
        isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary;

    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final pending = total - completed;
    final overdue = tasks.where((t) => t.isOverdue).length;
    final overallProgress = total == 0 ? 0.0 : completed / total;

    // Weekly day counts (Monday to Sunday of current week)
    final now = DateTime.now();
    final mondayOfThisWeek =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    final weekDaysData = List.generate(7, (index) {
      final day = mondayOfThisWeek.add(Duration(days: index));
      final count = tasks.where((t) => t.isSameDay(day)).length;
      final completedCount =
          tasks.where((t) => t.isSameDay(day) && t.isCompleted).length;
      return _DayChartData(
        dayName: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][index],
        date: day,
        total: count,
        completed: completedCount,
        isToday: day.year == now.year &&
            day.month == now.month &&
            day.day == now.day,
      );
    });

    final maxWeekCount = weekDaysData.map((d) => d.total).fold(1, math.max);

    // Course breakdown
    final courseMap = <String, List<TaskItem>>{};
    for (final task in tasks) {
      if (task.course.trim().isNotEmpty) {
        courseMap.putIfAbsent(task.course.trim(), () => []).add(task);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF16A34A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Statistik & Produktivitas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Pemantauan performa dan distribusi tugas',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(overallProgress * 100).round()}% Selesai',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 4 Metric Mini Cards Row
          Row(
            children: [
              _buildMiniMetric(
                label: 'Total Tugas',
                count: total,
                icon: Icons.layers_outlined,
                color: Theme.of(context).primaryColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMiniMetric(
                label: 'Selesai',
                count: completed,
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF16A34A),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMiniMetric(
                label: 'Berjalan',
                count: pending,
                icon: Icons.timelapse_rounded,
                color: const Color(0xFFD97706),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMiniMetric(
                label: 'Terlambat',
                count: overdue,
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFDC2626),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Weekly Deadline Bar Chart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tenggat Waktu Pekan Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                'Senin - Minggu',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Graphic Bar Chart container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekDaysData.map((data) {
                final heightFactor =
                    data.total == 0 ? 0.08 : (data.total / maxWeekCount);
                final barHeight = 85.0 * heightFactor;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Task count label above bar
                    Text(
                      '${data.total}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: data.total > 0
                            ? (data.isToday
                                ? Theme.of(context).primaryColor
                                : textPrimary)
                            : textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Bar graphic with rounded top
                    Container(
                      width: 22,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: data.total == 0
                            ? (isDark
                                ? const Color(0xFF333A48)
                                : const Color(0xFFCBD5E1))
                            : data.isToday
                                ? Theme.of(context).primaryColor
                                : (data.completed == data.total && data.total > 0
                                    ? const Color(0xFF16A34A)
                                    : (isDark
                                        ? const Color(0xFF4B5563)
                                        : const Color(0xFF64748B))),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Day Name
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: data.isToday
                          ? BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Text(
                        data.dayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: data.isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: data.isToday
                              ? Theme.of(context).primaryColor
                              : textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Course Progress Breakdown Section if courses exist
          if (courseMap.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Progres per Mata Kuliah',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...courseMap.entries.map((entry) {
              final cTotal = entry.value.length;
              final cDone = entry.value.where((t) => t.isCompleted).length;
              final cProgress = cTotal == 0 ? 0.0 : cDone / cTotal;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$cDone/$cTotal tugas • ${(cProgress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: cProgress,
                        minHeight: 6,
                        backgroundColor: surfaceSecondary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          cProgress == 1.0
                              ? const Color(0xFF16A34A)
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChartData {
  _DayChartData({
    required this.dayName,
    required this.date,
    required this.total,
    required this.completed,
    required this.isToday,
  });

  final String dayName;
  final DateTime date;
  final int total;
  final int completed;
  final bool isToday;
}
