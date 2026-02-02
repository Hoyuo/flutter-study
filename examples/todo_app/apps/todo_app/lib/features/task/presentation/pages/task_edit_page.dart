import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:task/task.dart';
import 'package:category/category.dart';
import 'package:core/core.dart' hide AppColors, AppTheme;
import 'package:todo_app/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class TaskEditPage extends StatelessWidget {
  final String? taskId;

  const TaskEditPage({super.key, this.taskId});

  bool get isEditing => taskId != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<TaskEditBloc>()
            ..add(TaskEditEvent.loadTask(taskId)),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<CategoryBloc>()
            ..add(const CategoryEvent.loadCategories()),
        ),
      ],
      child: BlocBuilder<TaskEditBloc, TaskEditState>(
        builder: (context, state) {
          final isLoading = state.isLoading;

          if (isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, state, isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTitleField(context, state, isDark),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildDescriptionField(context, state, isDark),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildPriorityField(context, state, isDark),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildDueDateField(context, state, isDark),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildCategoryField(context, state, isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TaskEditState state, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                LucideIcons.arrowLeft,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Title
          Expanded(
            child: Text(
              isEditing ? AppLocalizations.of(context)!.editTask : AppLocalizations.of(context)!.newTask,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          // Save button
          GestureDetector(
            onTap: state.isSaving
                ? null
                : () {
                    final l10n = AppLocalizations.of(context)!;
                    context.read<TaskEditBloc>().add(
                          const TaskEditEvent.saveTask(),
                        );
                    // Show snackbar and navigate back after a short delay
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (context.mounted) {
                        CustomSnackbar.showSuccess(
                          context,
                          isEditing ? l10n.taskUpdated : l10n.taskCreated,
                        );
                        context.pop();
                      }
                    });
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: state.isSaving
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: state.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textOnPrimary,
                        ),
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.save,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(BuildContext context, TaskEditState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.taskTitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 52,
          child: TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterTitle,
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              hintStyle: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textPlaceholder,
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
            ),
            controller: TextEditingController(text: state.title)
              ..selection = TextSelection.collapsed(
                offset: state.title.length,
              ),
            onChanged: (value) {
              context.read<TaskEditBloc>().add(
                    TaskEditEvent.updateTitle(value),
                  );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context, TaskEditState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.description,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.addDescription,
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
              hintStyle: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textPlaceholder,
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
            ),
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            controller: TextEditingController(text: state.description)
              ..selection = TextSelection.collapsed(
                offset: state.description.length,
              ),
            onChanged: (value) {
              context.read<TaskEditBloc>().add(
                    TaskEditEvent.updateDescription(value),
                  );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityField(BuildContext context, TaskEditState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.priority,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: Priority.values.map((priority) {
            final isSelected = state.priority == priority;
            final isHigh = priority == Priority.high;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: priority != Priority.low ? AppSpacing.sm : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    context.read<TaskEditBloc>().add(
                          TaskEditEvent.updatePriority(priority),
                        );
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isHigh ? AppColors.priorityHighBg : priority.color.withValues(alpha: 0.15))
                          : (isDark ? AppColors.surfaceDark : AppColors.surface),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: isSelected
                          ? Border.all(
                              color: priority.color,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        priority.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? priority.color
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDateField(BuildContext context, TaskEditState state, bool isDark) {
    final dateText = state.dueDate != null
        ? _formatDate(context, state.dueDate!)
        : AppLocalizations.of(context)!.selectDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.dueDate,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: state.dueDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null && context.mounted) {
              context.read<TaskEditBloc>().add(
                    TaskEditEvent.updateDueDate(date),
                  );
            }
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: state.dueDate != null
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textPlaceholder),
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.calendar,
                  size: 20,
                  color: state.dueDate != null
                      ? AppColors.primary
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField(BuildContext context, TaskEditState state, bool isDark) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        final categories = categoryState.when(
          initial: (cats) => cats,
          loading: (cats) => cats,
          loaded: (cats) => cats,
          error: (cats, _) => cats,
        );

        // Find selected category name
        String categoryText = AppLocalizations.of(context)!.selectCategory;
        Color? selectedColor;
        if (state.categoryId != null && categories.isNotEmpty) {
          final selected = categories.where((c) => c.id == state.categoryId).firstOrNull;
          if (selected != null) {
            categoryText = selected.name;
            selectedColor = Color(int.parse('FF${selected.colorHex}', radix: 16));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.category,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => _showCategoryPicker(context, categories, state.categoryId, isDark),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Row(
                  children: [
                    if (selectedColor != null) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        categoryText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          color: state.categoryId != null
                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textPlaceholder),
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    List<Category> categories,
    String? selectedCategoryId,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                    AppLocalizations.of(context)!.selectCategory,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  if (selectedCategoryId != null)
                    TextButton(
                      onPressed: () {
                        context.read<TaskEditBloc>().add(
                              const TaskEditEvent.updateCategory(null),
                            );
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.clear,
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
            // Category list
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  AppLocalizations.of(context)!.noCategoriesAvailable,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: categories.length,
                itemBuilder: (_, index) {
                  final category = categories[index];
                  final isSelected = category.id == selectedCategoryId;
                  final color = Color(int.parse('FF${category.colorHex}', radix: 16));

                  return ListTile(
                    onTap: () {
                      context.read<TaskEditBloc>().add(
                            TaskEditEvent.updateCategory(category.id),
                          );
                      Navigator.pop(ctx);
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.folder,
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            LucideIcons.check,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    final format = locale == 'ko'
        ? '${date.year}년 ${date.month}월 ${date.day}일'
        : '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    return format;
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
