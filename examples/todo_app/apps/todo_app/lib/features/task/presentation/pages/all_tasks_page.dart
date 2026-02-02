import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_app/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:task/task.dart';
import 'package:category/category.dart';
import 'package:core/types/priority.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';

class AllTasksPage extends StatefulWidget {
  const AllTasksPage({super.key});

  @override
  State<AllTasksPage> createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> {
  final _searchController = TextEditingController();
  Priority? _selectedPriority;
  bool? _showCompleted;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Format date for display (Today, Tomorrow, or formatted date)
  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    final l10n = AppLocalizations.of(context)!;

    if (dateOnly == today) {
      return l10n.today;
    } else if (dateOnly == tomorrow) {
      return l10n.tomorrow;
    } else {
      // Format as "Jan 15" or "1월 15일" based on locale
      final locale = Localizations.localeOf(context).languageCode;
      if (locale == 'ko') {
        return DateFormat('M월 d일').format(date);
      } else {
        return DateFormat('MMM d').format(date);
      }
    }
  }

  /// Get category name from categoryId
  String? _getCategoryName(String? categoryId, List<Category> categories) {
    if (categoryId == null) return null;

    try {
      final category = categories.firstWhere((c) => c.id == categoryId);
      return category.name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<TaskBloc>()..add(const TaskEvent.loadTasks()),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<CategoryBloc>()..add(const CategoryEvent.loadCategories()),
        ),
      ],
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              _buildCustomHeader(context, isDark),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: _buildSearchBar(context, isDark),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Task List
              Expanded(
                child: BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    final tasks = state.tasks;
                    final isLoading = state.isLoading;

                    if (isLoading && tasks.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (tasks.isEmpty) {
                      return EmptyState.noSearchResults(
                        context: context,
                        onClearFilters: () {
                          _searchController.clear();
                          context.read<TaskBloc>().add(
                                const TaskEvent.loadTasks(),
                              );
                        },
                      );
                    }

                    return _buildTaskList(context, tasks, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, bool isDark) {
    final surfaceColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);
    final iconColor = isDark ? Colors.white : const Color(0xFF18181B);
    final textColor = isDark ? Colors.white : const Color(0xFF18181B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: [
          // Back Button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              icon: Icon(
                LucideIcons.arrowLeft,
                size: 22,
                color: iconColor,
              ),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          // Title
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.allTasks,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),

          // Filter Button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              icon: Icon(
                LucideIcons.slidersHorizontal,
                size: 22,
                color: iconColor,
              ),
              onPressed: () => _showFilterBottomSheet(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    final surfaceColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);
    final iconColor = const Color(0xFFA1A1AA);
    final placeholderColor = const Color(0xFFA1A1AA);
    final textColor = isDark ? Colors.white : const Color(0xFF18181B);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            LucideIcons.search,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchTasks,
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: placeholderColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (query) {
                if (query.isEmpty) {
                  context.read<TaskBloc>().add(
                        const TaskEvent.loadTasks(),
                      );
                } else {
                  context.read<TaskBloc>().add(
                        TaskEvent.searchTasks(query),
                      );
                }
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                LucideIcons.x,
                size: 20,
                color: iconColor,
              ),
              onPressed: () {
                _searchController.clear();
                context.read<TaskBloc>().add(
                      const TaskEvent.loadTasks(),
                    );
                setState(() {});
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks, bool isDark) {
    final containerColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: tasks.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: isDark
              ? const Color(0xFF3F3F46)
              : const Color(0xFFE4E4E7),
            indent: 60,
          ),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskItem(context, task, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF18181B);
    final secondaryTextColor = isDark
      ? const Color(0xFF71717A)
      : const Color(0xFFA1A1AA);

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        final categories = categoryState.categories;
        final categoryName = _getCategoryName(task.categoryId, categories);
        final dateText = _formatDate(context, task.dueDate);

        // Build the metadata line (date • category)
        final metadataParts = <String>[];
        if (dateText.isNotEmpty) {
          metadataParts.add(dateText);
        }
        if (categoryName != null) {
          metadataParts.add(categoryName);
        }
        final metadata = metadataParts.join(' • ');

        return InkWell(
          onTap: () {
            context.pushNamed(
              'edit-task',
              pathParameters: {'id': task.id},
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                // Checkbox
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) {
                      context.read<TaskBloc>().add(
                            TaskEvent.toggleCompletion(task.id),
                          );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Title, Description, and Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor,
                            decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          metadata,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Priority Indicator
                _buildPriorityIndicator(task.priority, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityIndicator(Priority priority, bool isDark) {
    Color backgroundColor;
    Color borderColor;

    switch (priority) {
      case Priority.high:
        backgroundColor = isDark
          ? const Color(0xFF7F1D1D)
          : const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFEF4444);
        break;
      case Priority.medium:
        backgroundColor = isDark
          ? const Color(0xFF78350F)
          : const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFF59E0B);
        break;
      case Priority.low:
        backgroundColor = isDark
          ? const Color(0xFF064E3B)
          : const Color(0xFFD1FAE5);
        borderColor = const Color(0xFF14B8A6);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: borderColor,
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF52525B) : const Color(0xFFD4D4D8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                l10n.filter,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              // Priority filter
              Text(
                l10n.priority,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    label: l10n.all,
                    isSelected: _selectedPriority == null,
                    onTap: () {
                      setModalState(() => _selectedPriority = null);
                      setState(() {});
                      _applyFilters(context);
                    },
                    isDark: isDark,
                  ),
                  _buildFilterChip(
                    label: l10n.priorityHigh,
                    isSelected: _selectedPriority == Priority.high,
                    onTap: () {
                      setModalState(() => _selectedPriority = Priority.high);
                      setState(() {});
                      _applyFilters(context);
                    },
                    isDark: isDark,
                    color: const Color(0xFFEF4444),
                  ),
                  _buildFilterChip(
                    label: l10n.priorityMedium,
                    isSelected: _selectedPriority == Priority.medium,
                    onTap: () {
                      setModalState(() => _selectedPriority = Priority.medium);
                      setState(() {});
                      _applyFilters(context);
                    },
                    isDark: isDark,
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildFilterChip(
                    label: l10n.priorityLow,
                    isSelected: _selectedPriority == Priority.low,
                    onTap: () {
                      setModalState(() => _selectedPriority = Priority.low);
                      setState(() {});
                      _applyFilters(context);
                    },
                    isDark: isDark,
                    color: const Color(0xFF14B8A6),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Clear filters button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    setModalState(() {
                      _selectedPriority = null;
                      _showCompleted = null;
                    });
                    setState(() {});
                    context.read<TaskBloc>().add(const TaskEvent.loadTasks());
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.clearFilters,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5)),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: color ?? AppColors.primary, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? (color ?? AppColors.primary)
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  void _applyFilters(BuildContext context) {
    if (_selectedPriority != null) {
      context.read<TaskBloc>().add(TaskEvent.applyFilter(priority: _selectedPriority));
    } else {
      context.read<TaskBloc>().add(const TaskEvent.loadTasks());
    }
  }
}
