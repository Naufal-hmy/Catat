import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../services/task_storage.dart';
import '../theme/app_theme.dart';
import 'task_form_dialog.dart';
import 'widgets/calendar_deadline_view.dart';
import 'widgets/dashboard_stats_chart.dart';
import 'widgets/notification_modal.dart';
import 'widgets/task_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  TaskFilter _selectedFilter = TaskFilter.all;
  DateTime? _selectedCalendarDate;
  String? _selectedCourse;
  String _searchQuery = '';
  TaskSortBy _sortBy = TaskSortBy.deadlineAsc;

  bool _isSearchExpandedMobile = false;
  bool _showChartsOnMobile = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final loaded = await TaskStorage.loadTasks();
    if (loaded.isEmpty) {
      // First run default starter tasks so user has instant varied visual feedback
      _tasks = TaskStorage.getStarterTasks();
      await TaskStorage.saveTasks(_tasks);
    } else {
      _tasks = loaded;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTasks() async {
    await TaskStorage.saveTasks(_tasks);
  }

  // Task Operations
  Future<void> _openTaskForm({TaskItem? task}) async {
    final result = await TaskFormDialog.show(context, existingTask: task);
    if (result == null || !mounted) return;

    setState(() {
      final index = _tasks.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _tasks.insert(0, result);
      } else {
        _tasks[index] = result;
      }
    });
    await _saveTasks();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          task == null
              ? 'Tugas "${result.title}" berhasil ditambahkan!'
              : 'Tugas "${result.title}" berhasil diperbarui!',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleTaskStatus(TaskItem task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;

    final nextStatus = !task.isCompleted;
    // If completing the task, also mark all subtasks complete for consistency
    final updatedSubtasks = nextStatus
        ? task.subtasks.map((s) => s.copyWith(isCompleted: true)).toList()
        : task.subtasks;

    setState(() {
      _tasks[index] = task.copyWith(
        isCompleted: nextStatus,
        subtasks: updatedSubtasks,
      );
    });
    await _saveTasks();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextStatus
              ? 'Hebat! Tugas "${task.title}" telah selesai.'
              : 'Status tugas "${task.title}" dikembalikan ke berjalan.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleSubtask(TaskItem task, int subtaskIndex) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1 || subtaskIndex >= task.subtasks.length) return;

    final subtasks = List<SubTask>.from(task.subtasks);
    final currentSub = subtasks[subtaskIndex];
    subtasks[subtaskIndex] =
        currentSub.copyWith(isCompleted: !currentSub.isCompleted);

    final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.isCompleted);

    setState(() {
      _tasks[index] = task.copyWith(
        subtasks: subtasks,
        isCompleted: allDone ? true : task.isCompleted,
      );
    });
    await _saveTasks();
  }

  Future<void> _deleteTask(TaskItem task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Tugas Ini?'),
        content: Text(
          'Tugas "${task.title}" akan dihapus permanen dari daftar catatan Anda.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _tasks.removeWhere((item) => item.id == task.id);
    });
    await _saveTasks();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tugas telah dihapus.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Getters for Stats & Categories
  int get _totalCount => _tasks.length;
  int get _completedCount => _tasks.where((t) => t.isCompleted).length;
  int get _pendingCount => _tasks.where((t) => !t.isCompleted).length;
  int get _todayCount => _tasks.where((t) => t.isDueToday).length;
  int get _highPriorityCount =>
      _tasks.where((t) => t.priority == TaskPriority.high && !t.isCompleted).length;

  int get _notificationAlertCount {
    final overdue = _tasks.where((t) => t.isOverdue).length;
    final dueToday = _tasks.where((t) => t.isDueToday && !t.isCompleted).length;
    final dueTomorrow =
        _tasks.where((t) => t.isDueTomorrow && !t.isCompleted).length;
    return overdue + dueToday + dueTomorrow;
  }

  List<String> get _courseList {
    final set = <String>{};
    for (final t in _tasks) {
      if (t.course.trim().isNotEmpty) {
        set.add(t.course.trim());
      }
    }
    return set.toList()..sort();
  }

  List<TaskItem> get _filteredTasks {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _tasks.where((task) {
      // Calendar date filter
      if (_selectedCalendarDate != null) {
        if (!task.isSameDay(_selectedCalendarDate!)) return false;
      }

      // Course filter
      if (_selectedCourse != null && task.course != _selectedCourse) {
        return false;
      }

      // Tab filter
      final matchesFilter = switch (_selectedFilter) {
        TaskFilter.all => true,
        TaskFilter.today => task.isDueToday,
        TaskFilter.calendar => true,
        TaskFilter.pending => !task.isCompleted,
        TaskFilter.completed => task.isCompleted,
        TaskFilter.highPriority => task.priority == TaskPriority.high,
      };

      if (!matchesFilter) return false;

      // Search query
      if (query.isNotEmpty) {
        final inTitle = task.title.toLowerCase().contains(query);
        final inCourse = task.course.toLowerCase().contains(query);
        final inNotes = task.notes.toLowerCase().contains(query);
        final inSubtasks =
            task.subtasks.any((s) => s.title.toLowerCase().contains(query));
        if (!inTitle && !inCourse && !inNotes && !inSubtasks) return false;
      }

      return true;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      // Completed items always sink to the bottom
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      switch (_sortBy) {
        case TaskSortBy.deadlineAsc:
          return a.deadline.compareTo(b.deadline);
        case TaskSortBy.priorityDesc:
          return b.priority.index.compareTo(a.priority.index);
        case TaskSortBy.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return filtered;
  }

  String _formatTodayHeader() {
    final now = DateTime.now();
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
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
    final dayName = days[now.weekday - 1];
    return '$dayName, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showNotificationCenter() {
    NotificationModal.show(
      context,
      tasks: _tasks,
      onSelectTask: (t) => _openTaskForm(task: t),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        if (isDesktop) {
          return _buildDesktopLayout(context, constraints);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // ==========================================
  // MOBILE VIEW (< 768px)
  // ==========================================
  Widget _buildMobileLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final progress = _totalCount == 0 ? 0.0 : _completedCount / _totalCount;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        // App Brand Icon & Titles
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTodayHeader(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Catatan Tugas',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Notification Center Bell Button with Badge
                        _buildNotificationBellButton(),

                        // Search icon button
                        IconButton(
                          icon: Icon(
                            _isSearchExpandedMobile
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            color: textPrimary,
                          ),
                          tooltip: 'Cari tugas',
                          onPressed: () {
                            setState(() {
                              _isSearchExpandedMobile =
                                  !_isSearchExpandedMobile;
                              if (!_isSearchExpandedMobile) {
                                _searchQuery = '';
                                _searchController.clear();
                              }
                            });
                          },
                        ),

                        // Theme Mode Switcher
                        _buildThemeMenuButton(context),
                      ],
                    ),

                    // Expandable Search Bar on Mobile
                    if (_isSearchExpandedMobile) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Ketik nama tugas, subtask, atau mata kuliah...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Calm Daily Motivation & Progress Card
                    _buildDailySummaryCard(progress, isDark),

                    const SizedBox(height: 14),

                    // Toggle Button: Tampilkan Grafik & Kalender di Mobile
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 42),
                              side: BorderSide(
                                color: _showChartsOnMobile
                                    ? Theme.of(context).primaryColor
                                    : (isDark
                                        ? AppTheme.darkBorder
                                        : AppTheme.lightBorder),
                              ),
                              backgroundColor: _showChartsOnMobile
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.08)
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _showChartsOnMobile = !_showChartsOnMobile;
                              });
                            },
                            icon: Icon(
                              _showChartsOnMobile
                                  ? Icons.expand_less_rounded
                                  : Icons.insights_rounded,
                              size: 18,
                              color: _showChartsOnMobile
                                  ? Theme.of(context).primaryColor
                                  : textPrimary,
                            ),
                            label: Text(
                              _showChartsOnMobile
                                  ? 'Sembunyikan Grafik & Kalender'
                                  : 'Lihat Grafik & Kalender Deadline',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _showChartsOnMobile
                                    ? Theme.of(context).primaryColor
                                    : textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Mobile Expandable Charts & Calendar
                    if (_showChartsOnMobile) ...[
                      const SizedBox(height: 16),
                      DashboardStatsChart(tasks: _tasks),
                      const SizedBox(height: 16),
                      CalendarDeadlineView(
                        tasks: _tasks,
                        selectedDate: _selectedCalendarDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedCalendarDate = date;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Filter Tabs Horizontal List
                    _buildMobileFilterChips(isDark),

                    // Active Course Filter Chip if selected
                    if (_selectedCourse != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Mata Kuliah: $_selectedCourse',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () =>
                                      setState(() => _selectedCourse = null),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Section Title & Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _getFilterTitle(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildSortDropdown(isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tasks List
            if (_filteredTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(isDark),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = _filteredTasks[index];
                      return TaskCard(
                        task: task,
                        onToggle: _toggleTaskStatus,
                        onEdit: (t) => _openTaskForm(task: t),
                        onDelete: _deleteTask,
                        onSubtaskToggle: _toggleSubtask,
                      );
                    },
                    childCount: _filteredTasks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Tambah Tugas',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ==========================================
  // DESKTOP / TABLET VIEW (>= 768px)
  // ==========================================
  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final sidebarBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final isVeryWide = constraints.maxWidth >= 1200;

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar (Navigation & Filters)
          Container(
            width: 290,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(right: BorderSide(color: borderColor, width: 1.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.task_alt_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan Tugas',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Dashboard Produktivitas',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Theme Mode Selector in Sidebar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEMA TAMPILAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDesktopThemeToggle(isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Navigation list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      Text(
                        'STATUS TUGAS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSidebarNavItem(
                        title: 'Semua Tugas',
                        icon: Icons.list_alt_rounded,
                        count: _totalCount,
                        isSelected: _selectedFilter == TaskFilter.all &&
                            _selectedCourse == null &&
                            _selectedCalendarDate == null,
                        onTap: () {
                          setState(() {
                            _selectedFilter = TaskFilter.all;
                            _selectedCourse = null;
                            _selectedCalendarDate = null;
                          });
                        },
                      ),
                      _buildSidebarNavItem(
                        title: 'Hari Ini',
                        icon: Icons.today_rounded,
                        count: _todayCount,
                        isSelected: _selectedFilter == TaskFilter.today &&
                            _selectedCourse == null &&
                            _selectedCalendarDate == null,
                        onTap: () {
                          setState(() {
                            _selectedFilter = TaskFilter.today;
                            _selectedCourse = null;
                            _selectedCalendarDate = null;
                          });
                        },
                      ),
                      _buildSidebarNavItem(
                        title: 'Sedang Berjalan',
                        icon: Icons.timelapse_rounded,
                        count: _pendingCount,
                        isSelected: _selectedFilter == TaskFilter.pending &&
                            _selectedCourse == null &&
                            _selectedCalendarDate == null,
                        onTap: () {
                          setState(() {
                            _selectedFilter = TaskFilter.pending;
                            _selectedCourse = null;
                            _selectedCalendarDate = null;
                          });
                        },
                      ),
                      _buildSidebarNavItem(
                        title: 'Sudah Selesai',
                        icon: Icons.check_circle_outline_rounded,
                        count: _completedCount,
                        isSelected: _selectedFilter == TaskFilter.completed &&
                            _selectedCourse == null &&
                            _selectedCalendarDate == null,
                        onTap: () {
                          setState(() {
                            _selectedFilter = TaskFilter.completed;
                            _selectedCourse = null;
                            _selectedCalendarDate = null;
                          });
                        },
                      ),
                      _buildSidebarNavItem(
                        title: 'Prioritas Tinggi',
                        icon: Icons.flag_rounded,
                        count: _highPriorityCount,
                        iconColor: const Color(0xFFDC2626),
                        isSelected: _selectedFilter == TaskFilter.highPriority &&
                            _selectedCourse == null &&
                            _selectedCalendarDate == null,
                        onTap: () {
                          setState(() {
                            _selectedFilter = TaskFilter.highPriority;
                            _selectedCourse = null;
                            _selectedCalendarDate = null;
                          });
                        },
                      ),

                      if (_courseList.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'MATA KULIAH / KATEGORI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._courseList.map((course) {
                          final count =
                              _tasks.where((t) => t.course == course).length;
                          final isSelected = _selectedCourse == course;
                          return _buildSidebarNavItem(
                            title: course,
                            icon: Icons.folder_outlined,
                            count: count,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCourse = isSelected ? null : course;
                                _selectedCalendarDate = null;
                              });
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),

                // Bottom Sidebar Productivity Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceSecondary
                          : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Penyelesaian',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              '${_totalCount == 0 ? 0 : ((_completedCount / _totalCount) * 100).round()}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _totalCount == 0
                                ? 0.0
                                : _completedCount / _totalCount,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? const Color(0xFF2C3342)
                                : const Color(0xFFDCE2EC),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_completedCount dari $_totalCount tugas selesai',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Desktop Header (Search, Sort, Notification, Add Task button)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: BoxDecoration(
                    color: sidebarBg,
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 1.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Search Box
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(fontSize: 14, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Cari tugas, subtask, mata kuliah...',
                              prefixIcon:
                                  const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Notification Center Bell Button
                      _buildNotificationBellButton(),
                      const SizedBox(width: 12),

                      // Sort dropdown
                      _buildSortDropdown(isDark),
                      const SizedBox(width: 14),

                      // Add Task Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(160, 46),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _openTaskForm(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Tambah Tugas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Dashboard Body: Split into Tasks & Analytics/Calendar
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 20,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left / Center Column: Task list
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Heading Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getFilterTitle(),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTodayHeader(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.darkSurfaceSecondary
                                          : AppTheme.lightSurfaceSecondary,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Text(
                                      '${_filteredTasks.length} tugas ditampilkan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Tasks List Area
                              Expanded(
                                child: _filteredTasks.isEmpty
                                    ? _buildEmptyState(isDark)
                                    : ListView.builder(
                                        itemCount: _filteredTasks.length,
                                        itemBuilder: (context, index) {
                                          final task = _filteredTasks[index];
                                          return TaskCard(
                                            task: task,
                                            onToggle: _toggleTaskStatus,
                                            onEdit: (t) =>
                                                _openTaskForm(task: t),
                                            onDelete: _deleteTask,
                                            onSubtaskToggle: _toggleSubtask,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Right Column on Desktop: Calendar & Graphic Dashboard
                        SizedBox(
                          width: isVeryWide ? 380 : 330,
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              // Interactive Calendar View
                              CalendarDeadlineView(
                                tasks: _tasks,
                                selectedDate: _selectedCalendarDate,
                                onDateSelected: (date) {
                                  setState(() {
                                    _selectedCalendarDate = date;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),

                              // Statistics & Analytics Charts
                              DashboardStatsChart(tasks: _tasks),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED WIDGET HELPERS
  // ==========================================

  Widget _buildNotificationBellButton() {
    final alertCount = _notificationAlertCount;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 22),
          tooltip: 'Pusat Notifikasi & Deadline',
          onPressed: _showNotificationCenter,
        ),
        if (alertCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$alertCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDailySummaryCard(double progress, bool isDark) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Hari Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _pendingCount == 0 && _totalCount > 0
                          ? 'Keren! Semua tugas Anda telah rampung.'
                          : 'Ada $_pendingCount tugas yang siap diselesaikan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: isDark
                  ? const Color(0xFF2B3342)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'Semua',
            count: _totalCount,
            isSelected: _selectedFilter == TaskFilter.all &&
                _selectedCourse == null &&
                _selectedCalendarDate == null,
            onTap: () => setState(() {
              _selectedFilter = TaskFilter.all;
              _selectedCourse = null;
              _selectedCalendarDate = null;
            }),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Hari Ini',
            count: _todayCount,
            isSelected: _selectedFilter == TaskFilter.today &&
                _selectedCourse == null &&
                _selectedCalendarDate == null,
            onTap: () => setState(() {
              _selectedFilter = TaskFilter.today;
              _selectedCourse = null;
              _selectedCalendarDate = null;
            }),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Berjalan',
            count: _pendingCount,
            isSelected: _selectedFilter == TaskFilter.pending &&
                _selectedCourse == null &&
                _selectedCalendarDate == null,
            onTap: () => setState(() {
              _selectedFilter = TaskFilter.pending;
              _selectedCourse = null;
              _selectedCalendarDate = null;
            }),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Selesai',
            count: _completedCount,
            isSelected: _selectedFilter == TaskFilter.completed &&
                _selectedCourse == null &&
                _selectedCalendarDate == null,
            onTap: () => setState(() {
              _selectedFilter = TaskFilter.completed;
              _selectedCourse = null;
              _selectedCalendarDate = null;
            }),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Prioritas Tinggi',
            count: _highPriorityCount,
            isSelected: _selectedFilter == TaskFilter.highPriority &&
                _selectedCourse == null &&
                _selectedCalendarDate == null,
            onTap: () => setState(() {
              _selectedFilter = TaskFilter.highPriority;
              _selectedCourse = null;
              _selectedCalendarDate = null;
            }),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : (isDark
                        ? AppTheme.darkSurfaceSecondary
                        : AppTheme.lightSurfaceSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required String title,
    required IconData icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? primary
                      : (iconColor ??
                          (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? primary
                          : (isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withValues(alpha: 0.20)
                        : (isDark
                            ? AppTheme.darkSurfaceSecondary
                            : AppTheme.lightSurfaceSecondary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? primary
                          : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary),
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

  Widget _buildDesktopThemeToggle(bool isDark) {
    final current = widget.currentThemeMode;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurfaceSecondary
            : AppTheme.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildThemeToggleOption(
            icon: Icons.light_mode_rounded,
            label: 'Terang',
            isSelected: current == ThemeMode.light,
            onTap: () => widget.onThemeChanged(ThemeMode.light),
          ),
          _buildThemeToggleOption(
            icon: Icons.dark_mode_rounded,
            label: 'Gelap',
            isSelected: current == ThemeMode.dark,
            onTap: () => widget.onThemeChanged(ThemeMode.dark),
          ),
          _buildThemeToggleOption(
            icon: Icons.brightness_auto_rounded,
            label: 'Sistem',
            isSelected: current == ThemeMode.system,
            onTap: () => widget.onThemeChanged(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.darkSurface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary)
                      : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeMenuButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = widget.currentThemeMode;

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Pilih tema tampilan',
      icon: Icon(
        current == ThemeMode.light
            ? Icons.light_mode_rounded
            : current == ThemeMode.dark
                ? Icons.dark_mode_rounded
                : Icons.brightness_auto_rounded,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (mode) => widget.onThemeChanged(mode),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode_rounded,
                size: 18,
                color: current == ThemeMode.light
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 10),
              const Text('Mode Terang'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(
                Icons.dark_mode_rounded,
                size: 18,
                color: current == ThemeMode.dark
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 10),
              const Text('Mode Gelap'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(
                Icons.brightness_auto_rounded,
                size: 18,
                color: current == ThemeMode.system
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 10),
              const Text('Ikuti Sistem'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortDropdown(bool isDark) {
    return PopupMenuButton<TaskSortBy>(
      tooltip: 'Urutkan tugas',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort_rounded,
              size: 16,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              switch (_sortBy) {
                TaskSortBy.deadlineAsc => 'Deadline',
                TaskSortBy.priorityDesc => 'Prioritas',
                TaskSortBy.titleAsc => 'Judul',
              },
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ],
        ),
      ),
      onSelected: (sort) => setState(() => _sortBy = sort),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: TaskSortBy.deadlineAsc,
          child: Text('Urutkan: Deadline Terdekat'),
        ),
        const PopupMenuItem(
          value: TaskSortBy.priorityDesc,
          child: Text('Urutkan: Prioritas Tertinggi'),
        ),
        const PopupMenuItem(
          value: TaskSortBy.titleAsc,
          child: Text('Urutkan: Abjad Judul (A-Z)'),
        ),
      ],
    );
  }

  String _getFilterTitle() {
    if (_selectedCalendarDate != null) {
      return 'Tenggat: ${TaskItem.formatIndonesianDate(_selectedCalendarDate!)}';
    }
    if (_selectedCourse != null) {
      return 'Mata Kuliah: $_selectedCourse';
    }
    return switch (_selectedFilter) {
      TaskFilter.all => 'Semua Tugas',
      TaskFilter.today => 'Tugas Hari Ini',
      TaskFilter.calendar => 'Kalender Deadline',
      TaskFilter.pending => 'Tugas Sedang Berjalan',
      TaskFilter.completed => 'Tugas Selesai',
      TaskFilter.highPriority => 'Prioritas Tinggi',
    };
  }

  Widget _buildEmptyState(bool isDark) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final isSearching = _searchQuery.isNotEmpty;
    final isCalendarFiltered = _selectedCalendarDate != null;

    final title = isSearching
        ? 'Tugas Tidak Ditemukan'
        : isCalendarFiltered
            ? 'Tidak Ada Deadline Pada Tanggal Ini'
            : _selectedFilter == TaskFilter.completed
                ? 'Belum Ada Tugas Selesai'
                : 'Tidak Ada Tugas Saat Ini';

    final message = isSearching
        ? 'Coba periksa kembali kata kunci pencarian Anda.'
        : isCalendarFiltered
            ? 'Tidak ada tenggat waktu tugas yang dijadwalkan pada ${TaskItem.formatIndonesianDate(_selectedCalendarDate!)}.'
            : _selectedFilter == TaskFilter.completed
                ? 'Selesaikan tugas dari daftar berjalan Anda.'
                : 'Mulai dengan menambahkan tugas baru agar target Anda tercapai dengan teratur.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : isCalendarFiltered
                        ? Icons.event_busy_rounded
                        : Icons.check_circle_outline_rounded,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: textSecondary,
                ),
              ),
            ),
            if (isCalendarFiltered) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() => _selectedCalendarDate = null),
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Tampilkan Semua Tanggal'),
              ),
            ] else if (!isSearching && _selectedFilter != TaskFilter.completed) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 46),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _openTaskForm(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Buat Tugas Baru',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
