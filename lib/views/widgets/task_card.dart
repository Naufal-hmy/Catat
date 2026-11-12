import 'package:flutter/material.dart';
import '../../models/task_item.dart';
import '../../theme/app_theme.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onSubtaskToggle,
    this.compact = false,
  });

  final TaskItem task;
  final ValueChanged<TaskItem> onToggle;
  final ValueChanged<TaskItem> onEdit;
  final ValueChanged<TaskItem> onDelete;
  final void Function(TaskItem task, int subtaskIndex)? onSubtaskToggle;
  final bool compact;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isSubtasksExpanded = true;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColors = AppTheme.getPriorityColors(task.priority, isDark);
    final isLate = task.isOverdue;

    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final hasSubtasks = task.subtasks.isNotEmpty;
    final subtaskProgress = task.progress;
    final subtaskPercent = task.progressPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted
              ? borderColor.withValues(alpha: 0.5)
              : borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onEdit(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Big accessible Checkbox + Title + More menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accessible check target (44x44)
                    Semantics(
                      label: task.isCompleted
                          ? 'Tandai belum selesai: ${task.title}'
                          : 'Tandai selesai: ${task.title}',
                      button: true,
                      child: InkWell(
                        onTap: () => widget.onToggle(task),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: task.isCompleted
                                  ? const Color(0xFF16A34A)
                                  : Colors.transparent,
                              border: Border.all(
                                color: task.isCompleted
                                    ? const Color(0xFF16A34A)
                                    : (isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8)),
                                width: 2,
                              ),
                            ),
                            child: task.isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Title & Course
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: task.isCompleted
                                    ? (isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8))
                                    : textPrimary,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 15,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    task.course,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // More Options Popup Menu
                    PopupMenuButton<String>(
                      tooltip: 'Pilihan tugas',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        size: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderColor),
                      ),
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      onSelected: (value) {
                        if (value == 'toggle') widget.onToggle(task);
                        if (value == 'edit') widget.onEdit(task);
                        if (value == 'delete') widget.onDelete(task);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                task.isCompleted
                                    ? Icons.undo_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 18,
                                color: textPrimary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                task.isCompleted
                                    ? 'Batalkan Selesai'
                                    : 'Tandai Selesai',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 18, color: textPrimary),
                              const SizedBox(width: 10),
                              Text(
                                'Ubah Tugas',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Hapus Tugas',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Notes snippet if present
                if (task.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceSecondary
                          : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      task.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],

                // ==========================================
                // SUBTASKS SECTION WITH PERCENTAGE GRAPHIC
                // ==========================================
                if (hasSubtasks) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceSecondary.withValues(alpha: 0.6)
                          : AppTheme.lightSurfaceSecondary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : AppTheme.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtask title & toggle expand
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.checklist_rounded,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Subtask (${task.completedSubtasksCount}/${task.totalSubtasks})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => setState(() =>
                                  _isSubtasksExpanded = !_isSubtasksExpanded),
                              child: Row(
                                children: [
                                  Text(
                                    _isSubtasksExpanded
                                        ? 'Sembunyikan'
                                        : 'Tampilkan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  Icon(
                                    _isSubtasksExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (_isSubtasksExpanded) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: Checklist of Subtasks
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(task.subtasks.length,
                                      (subIdx) {
                                    final sub = task.subtasks[subIdx];
                                    return InkWell(
                                      onTap: () {
                                        if (widget.onSubtaskToggle != null) {
                                          widget.onSubtaskToggle!(task, subIdx);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 2),
                                        child: Row(
                                          children: [
                                            // Checkbox
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 150),
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: sub.isCompleted
                                                    ? const Color(0xFF16A34A)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                border: Border.all(
                                                  color: sub.isCompleted
                                                      ? const Color(0xFF16A34A)
                                                      : (isDark
                                                          ? const Color(0xFF64748B)
                                                          : const Color(0xFF94A3B8)),
                                                  width: 1.6,
                                                ),
                                              ),
                                              child: sub.isCompleted
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 14,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sub.title,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: sub.isCompleted
                                                      ? textSecondary
                                                      : textPrimary,
                                                  decoration: sub.isCompleted
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Right: Dedicated Percentage Graphic Chart
                              Container(
                                width: 78,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.darkSurface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppTheme.darkBorder
                                        : AppTheme.lightBorder,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CircularProgressIndicator(
                                            value: subtaskProgress,
                                            strokeWidth: 4.5,
                                            backgroundColor: isDark
                                                ? const Color(0xFF2C3241)
                                                : const Color(0xFFE2E8F0),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              subtaskProgress == 1.0
                                                  ? const Color(0xFF16A34A)
                                                  : Theme.of(context)
                                                      .primaryColor,
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              '$subtaskPercent%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      subtaskProgress == 1.0
                                          ? 'Selesai'
                                          : '${task.completedSubtasksCount}/${task.totalSubtasks}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: subtaskProgress == 1.0
                                            ? const Color(0xFF16A34A)
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Bottom Meta Row: Priority Badge + Deadline Status
                Row(
                  children: [
                    // Priority Badge
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: priorityColors.bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: priorityColors.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 13,
                            color: priorityColors.textColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            priorityColors.label,
                            style: TextStyle(
                              color: priorityColors.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Deadline info
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: isLate
                                ? const Color(0xFFDC2626)
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              task.relativeDeadlineText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isLate ? FontWeight.w700 : FontWeight.w500,
                                color: isLate
                                    ? const Color(0xFFDC2626)
                                    : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? (isDark
                                ? const Color(0xFF13362A)
                                : const Color(0xFFDCFCE7))
                            : (isDark
                                ? const Color(0xFF242934)
                                : const Color(0xFFEEF2F6)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.isCompleted ? 'Selesai' : 'Berjalan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted
                              ? (isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF16A34A))
                              : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
