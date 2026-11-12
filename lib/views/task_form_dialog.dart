import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';

class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({super.key, this.existingTask});

  final TaskItem? existingTask;

  static Future<TaskItem?> show(BuildContext context, {TaskItem? existingTask}) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (isDesktop) {
      return showDialog<TaskItem>(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: TaskFormDialog(existingTask: existingTask),
          ),
        ),
      );
    } else {
      return Navigator.of(context).push<TaskItem>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                existingTask != null ? 'Ubah Tugas' : 'Tambah Tugas Baru',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: TaskFormDialog(existingTask: existingTask),
            ),
          ),
        ),
      );
    }
  }

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _courseController;
  late final TextEditingController _notesController;
  late final TextEditingController _newSubtaskController;

  late DateTime _deadline;
  late TaskPriority _priority;
  late List<SubTask> _subtasks;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _courseController = TextEditingController(text: task?.course ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');
    _newSubtaskController = TextEditingController();

    _deadline = task?.deadline ??
        DateTime.now().add(const Duration(days: 1)).copyWith(
              minute: 0,
              second: 0,
            );
    _priority = task?.priority ?? TaskPriority.medium;
    _subtasks = task?.subtasks.map((s) => s.copyWith()).toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseController.dispose();
    _notesController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(now) ? now : _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Tenggat',
      cancelText: 'Batal',
      confirmText: 'Lanjut',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
      helpText: 'Pilih Jam Tenggat',
      cancelText: 'Batal',
      confirmText: 'Selesai',
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _addSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _subtasks.add(
        SubTask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: text,
          isCompleted: false,
        ),
      );
      _newSubtaskController.clear();
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final task = TaskItem(
      id: widget.existingTask?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      course: _courseController.text.trim(),
      deadline: _deadline,
      priority: _priority,
      notes: _notesController.text.trim(),
      isCompleted: widget.existingTask?.isCompleted ?? false,
      subtasks: _subtasks,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final surfaceColor =
        isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      color: surfaceColor,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header title on desktop dialog
              if (MediaQuery.of(context).size.width >= 768) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Ubah Tugas' : 'Tambah Tugas Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Guidance note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E283D)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E4068)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lengkapi informasi tugas dan subtask untuk memantau progres secara detail.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFF1E40AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              _buildFieldLabel('Judul Tugas', required: true, textPrimary: textPrimary),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 15, color: textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Misal: Mengerjakan Praktikum Mobile',
                  prefixIcon: Icon(Icons.title_rounded, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul tugas tidak boleh kosong.';
                  }
                  if (val.trim().length < 3) {
                    return 'Judul tugas minimal 3 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Course / Category Field
              _buildFieldLabel(
                'Mata Kuliah / Kategori',
                required: true,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _courseController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(fontSize: 15, color: textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Misal: Pemrograman Mobile / Basis Data',
                  prefixIcon: Icon(Icons.folder_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Mata kuliah/kategori wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Deadline Picker
              _buildFieldLabel(
                'Tenggat Waktu (Deadline)',
                required: true,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfaceSecondary
                        : AppTheme.lightSurfaceSecondary,
                    border: Border.all(color: borderColor, width: 1.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TaskItem.formatIndonesianDate(_deadline),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pukul ${_deadline.hour.toString().padLeft(2, '0')}:${_deadline.minute.toString().padLeft(2, '0')} WIB',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_calendar_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Priority Selector
              _buildFieldLabel('Tingkat Prioritas', textPrimary: textPrimary),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPriorityChip(
                      label: 'Rendah',
                      priority: TaskPriority.low,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPriorityChip(
                      label: 'Sedang',
                      priority: TaskPriority.medium,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPriorityChip(
                      label: 'Tinggi',
                      priority: TaskPriority.high,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ==========================================
              // SUBTASKS MANAGER (Checklist Items)
              // ==========================================
              _buildFieldLabel('Daftar Subtask / Langkah Kerja', textPrimary: textPrimary),
              const SizedBox(height: 6),

              // Add Subtask row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _newSubtaskController,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Tambah langkah subtask...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.add_task_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle_rounded),
                          color: Theme.of(context).primaryColor,
                          onPressed: _addSubtask,
                          tooltip: 'Tambah Subtask',
                        ),
                      ),
                      onFieldSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                ],
              ),
              if (_subtasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfaceSecondary
                        : AppTheme.lightSurfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: List.generate(_subtasks.length, (idx) {
                      final sub = _subtasks[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              sub.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 18,
                              color: sub.isCompleted
                                  ? const Color(0xFF16A34A)
                                  : textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sub.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textPrimary,
                                  decoration: sub.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: textSecondary,
                              tooltip: 'Hapus subtask',
                              onPressed: () => _removeSubtask(idx),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Notes Field
              _buildFieldLabel('Catatan Tambahan (Opsional)', textPrimary: textPrimary),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 15, color: textPrimary),
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Tambahkan instruksi, tautan, atau pengingat penting...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 26),

              // Action buttons (Batal & Simpan)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        _isEditing ? 'Simpan Perubahan' : 'Tambahkan Tugas',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label,
      {bool required = false, required Color textPrimary}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriorityChip({
    required String label,
    required TaskPriority priority,
    required bool isDark,
  }) {
    final isSelected = _priority == priority;
    final colors = AppTheme.getPriorityColors(priority, isDark);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _priority = priority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.bgColor
              : (isDark
                  ? AppTheme.darkSurfaceSecondary
                  : AppTheme.lightSurfaceSecondary),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.borderColor : Colors.transparent,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.flag_rounded,
              size: 18,
              color: isSelected
                  ? colors.textColor
                  : (isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colors.textColor
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
