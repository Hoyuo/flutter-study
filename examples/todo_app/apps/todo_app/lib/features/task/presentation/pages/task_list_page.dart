import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_app/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:task/task.dart';
import 'package:category/category.dart';
import 'package:core/types/priority.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/icon_utils.dart';

class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<TaskBloc>()..add(const TaskEvent.loadTasks()),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<CategoryBloc>()..add(const CategoryEvent.loadCategories()),
        ),
      ],
      child: const Scaffold(
        body: SafeArea(
          child: _TaskListView(),
        ),
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, taskState) {
        return BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, categoryState) {
            final tasks = taskState.tasks;
            final isLoading = taskState.isLoading;

            if (isLoading && tasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final activeTasks = tasks.where((t) => !t.isCompleted).toList();
            final completedTasks = tasks.where((t) => t.isCompleted).toList();
            final todayTasks = _getTodayTasks(tasks);

            // Get categories from state
            final categories = categoryState.when(
              initial: (cats) => cats,
              loading: (cats) => cats,
              loaded: (cats) => cats,
              error: (cats, _) => cats,
            );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, isDark),
                        const SizedBox(height: 24),
                        _buildStatsRow(context, activeTasks.length, completedTasks.length, isDark),
                        const SizedBox(height: 32),
                        _buildTodayTasksSection(context, todayTasks, isDark),
                        const SizedBox(height: 32),
                        _buildCategoriesSection(context, categories, tasks, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Task> _getTodayTasks(List<Task> tasks) {
    return tasks.where((t) {
      if (t.dueDate == null) return false;
      final now = DateTime.now();
      final dueDate = t.dueDate!;
      return dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day;
    }).toList();
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(context),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.myTasks,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Add button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
            onPressed: () => context.pushNamed('new-task'),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 12),
        // Settings button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: IconButton(
            icon: Icon(LucideIcons.settings, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, size: 24),
            onPressed: () => context.pushNamed('settings'),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 17) {
      return l10n.goodAfternoon;
    } else {
      return l10n.goodEvening;
    }
  }

  Widget _buildStatsRow(BuildContext context, int activeCount, int completedCount, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            count: activeCount,
            label: l10n.inProgress,
            backgroundColor: AppColors.primary,
            textColor: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            count: completedCount,
            label: l10n.completed,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            textColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required int count,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasksSection(BuildContext context, List<Task> todayTasks, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.todaysTasks,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    todayTasks.length.toString(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.pushNamed('all-tasks'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)!.seeAll,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: todayTasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.clipboardList,
                          size: 48,
                          color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary).withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.noTasksToday,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayTasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final task = todayTasks[index];
                    return _buildTaskItem(context, task, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task, bool isDark) {
    return InkWell(
      onTap: () {
        context.pushNamed(
          'edit-task',
          pathParameters: {'id': task.id},
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
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
            const SizedBox(width: 14),
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
                      color: task.isCompleted
                          ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildPriorityIndicator(task.priority),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(Priority priority) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: priority.color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    List<Category> categories,
    List<Task> allTasks,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.categories,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                context.pushNamed('categories').then((_) {
                  if (context.mounted) {
                    context.read<CategoryBloc>().add(const CategoryEvent.loadCategories());
                  }
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)!.seeAll,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: categories.isEmpty
              ? Center(
                  child: TextButton.icon(
                    onPressed: () {
                      context.pushNamed('categories').then((_) {
                        if (context.mounted) {
                          context.read<CategoryBloc>().add(const CategoryEvent.loadCategories());
                        }
                      });
                    },
                    icon: const Icon(LucideIcons.plus, size: 20),
                    label: Text(AppLocalizations.of(context)!.addCategory),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    // Count tasks for this category
                    final taskCount = allTasks
                        .where((t) => t.categoryId == category.id)
                        .length;
                    return _buildCategoryCard(context, category, taskCount, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category, int taskCount, bool isDark) {
    final color = Color(int.parse('FF${category.colorHex}', radix: 16));

    return InkWell(
      onTap: () {
        context.pushNamed('categories').then((_) {
          if (context.mounted) {
            context.read<CategoryBloc>().add(const CategoryEvent.loadCategories());
          }
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconUtils.getIconFromName(category.iconName),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$taskCount ${AppLocalizations.of(context)!.tasks}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<TaskBloc>(),
        child: const _FilterBottomSheet(),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet();

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String _selectedStatus = 'all';
  String _selectedSort = 'date';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF52525B) : const Color(0xFFD4D4D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filterAndSort,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'all';
                      _selectedSort = 'date';
                    });
                  },
                  child: Text(
                    l10n.reset,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status section
                Text(
                  l10n.status,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip(l10n.all, 'all', _selectedStatus, (v) {
                      setState(() => _selectedStatus = v);
                    }, isDark),
                    const SizedBox(width: 12),
                    _buildFilterChip(l10n.active, 'active', _selectedStatus, (v) {
                      setState(() => _selectedStatus = v);
                    }, isDark),
                    const SizedBox(width: 12),
                    _buildFilterChip(l10n.done, 'done', _selectedStatus, (v) {
                      setState(() => _selectedStatus = v);
                    }, isDark),
                  ],
                ),
                const SizedBox(height: 20),
                // Sort section
                Text(
                  l10n.sortBy,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip(l10n.date, 'date', _selectedSort, (v) {
                      setState(() => _selectedSort = v);
                    }, isDark),
                    const SizedBox(width: 12),
                    _buildFilterChip(l10n.priority, 'priority', _selectedSort, (v) {
                      setState(() => _selectedSort = v);
                    }, isDark),
                    const SizedBox(width: 12),
                    _buildFilterChip(l10n.name, 'name', _selectedSort, (v) {
                      setState(() => _selectedSort = v);
                    }, isDark),
                  ],
                ),
              ],
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Apply filters based on status selection
                  bool? isCompleted;
                  if (_selectedStatus == 'active') {
                    isCompleted = false;
                  } else if (_selectedStatus == 'done') {
                    isCompleted = true;
                  }
                  // Apply filter
                  context.read<TaskBloc>().add(TaskEvent.applyFilter(
                    isCompleted: isCompleted,
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.apply,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String selectedValue,
    ValueChanged<String> onSelected,
    bool isDark,
  ) {
    final isSelected = value == selectedValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
