import 'package:flutter/material.dart';
import '../../models/task_item.dart';
import '../../theme/app_theme.dart';

class CalendarDeadlineView extends StatefulWidget {
  const CalendarDeadlineView({
    super.key,
    required this.tasks,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final List<TaskItem> tasks;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  @override
  State<CalendarDeadlineView> createState() => _CalendarDeadlineViewState();
}

class _CalendarDeadlineViewState extends State<CalendarDeadlineView> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedDate ?? DateTime.now();
    _displayedMonth = DateTime(initial.year, initial.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
    });
    widget.onDateSelected(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final now = DateTime.now();

    final monthName = TaskItem.formatIndonesianDate(_displayedMonth).split(' ')[1];
    final year = _displayedMonth.year;

    // Days in current month
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    // Monday is 1, Sunday is 7 in Dart. We adjust so Monday is index 0.
    final startingWeekday = firstDayOfMonth.weekday - 1; // 0 for Monday

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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Month, Year, and Controls
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
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
                      '$monthName $year',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Kalender Tenggat Waktu Tugas',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Today shortcut
              TextButton(
                onPressed: _goToToday,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Hari Ini'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                tooltip: 'Bulan Sebelumnya',
                onPressed: _prevMonth,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                tooltip: 'Bulan Berikutnya',
                onPressed: _nextMonth,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Days of the week row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekdayLabel('Sen'),
              _WeekdayLabel('Sel'),
              _WeekdayLabel('Rab'),
              _WeekdayLabel('Kam'),
              _WeekdayLabel('Jum'),
              _WeekdayLabel('Sab'),
              _WeekdayLabel('Min', isWeekend: true),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 rows of 7
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - startingWeekday;
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }

              final currentDay = dayOffset + 1;
              final cellDate = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                currentDay,
              );

              final isToday = cellDate.year == now.year &&
                  cellDate.month == now.month &&
                  cellDate.day == now.day;

              final isSelected = widget.selectedDate != null &&
                  widget.selectedDate!.year == cellDate.year &&
                  widget.selectedDate!.month == cellDate.month &&
                  widget.selectedDate!.day == cellDate.day;

              // Find tasks due on this day
              final tasksOnThisDay = widget.tasks
                  .where((t) => t.isSameDay(cellDate))
                  .toList();
              final hasTasks = tasksOnThisDay.isNotEmpty;
              final hasHighPriority = tasksOnThisDay
                  .any((t) => t.priority == TaskPriority.high && !t.isCompleted);
              final allCompleted = hasTasks && tasksOnThisDay.every((t) => t.isCompleted);

              return InkWell(
                onTap: () {
                  if (isSelected) {
                    widget.onDateSelected(null); // Deselect
                  } else {
                    widget.onDateSelected(cellDate);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : isToday
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : isToday
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$currentDay',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? Theme.of(context).primaryColor
                                  : textPrimary,
                        ),
                      ),
                      if (hasTasks) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : allCompleted
                                        ? const Color(0xFF16A34A)
                                        : hasHighPriority
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFFEAB308),
                              ),
                            ),
                            if (tasksOnThisDay.length > 1) ...[
                              const SizedBox(width: 2),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          // Selected Date active filter tag
          if (widget.selectedDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_rounded,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menampilkan deadline: ${TaskItem.formatIndonesianDate(widget.selectedDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => widget.onDateSelected(null),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text, {this.isWeekend = false});

  final String text;
  final bool isWeekend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isWeekend
              ? const Color(0xFFEF4444)
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B)),
        ),
      ),
    );
  }
}
