import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_app/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:category/category.dart';
import 'package:task/task.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<CategoryBloc>()
            ..add(const CategoryEvent.loadCategories()),
        ),
        BlocProvider(
          create: (_) => GetIt.instance<TaskBloc>()
            ..add(const TaskEvent.loadTasks()),
        ),
      ],
      child: Builder(
        builder: (blocContext) => Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Custom header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, size: 20),
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(blocContext),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      // Title
                      Expanded(
                        child: Text(
                          AppLocalizations.of(blocContext)!.categories,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      // Add button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.plus, size: 20),
                          color: AppColors.textOnPrimary,
                          padding: EdgeInsets.zero,
                          onPressed: () => _showCategoryModal(blocContext),
                        ),
                      ),
                    ],
                  ),
                ),
              // Category list
              Expanded(
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, categoryState) {
                    return categoryState.when(
                      initial: (categories) => Center(
                        child: Text(AppLocalizations.of(context)!.loadingCategories),
                      ),
                      loading: (categories) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      loaded: (categories) {
                        if (categories.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.folderOpen,
                                  size: 64,
                                  color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary).withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.noCategories,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.addToOrganize,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textPlaceholder,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return BlocBuilder<TaskBloc, TaskState>(
                          builder: (context, taskState) {
                            final tasks = taskState.tasks;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.card),
                                ),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: categories.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    thickness: 1,
                                    indent: 76,
                                    color: (isDark ? AppColors.backgroundDark : AppColors.background).withValues(alpha: 0.5),
                                  ),
                                  itemBuilder: (context, index) {
                                    final category = categories[index];
                                    final taskCount = tasks.where((task) => task.categoryId == category.id).length;
                                    return _CategoryItem(
                                      category: category,
                                      taskCount: taskCount,
                                      isDark: isDark,
                                      onTap: () => _showCategoryModal(
                                        context,
                                        category: category,
                                      ),
                                      onDelete: () {
                                        context.read<CategoryBloc>().add(
                                              CategoryEvent.deleteCategory(
                                                categoryId: category.id,
                                                categoryName: category.name,
                                              ),
                                            );
                                        CustomSnackbar.showSuccess(
                                          context,
                                          AppLocalizations.of(context)!.categoryDeleted,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                      error: (categories, failure) => Center(
                        child: Text(
                          '${AppLocalizations.of(context)!.errorOccurred}: ${failure.message}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: isDark ? AppColors.error : AppColors.error,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showCategoryModal(BuildContext context, {Category? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: _CategoryCreateModal(category: category),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final Category category;
  final int taskCount;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CategoryItem({
    required this.category,
    required this.taskCount,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            // Color circle with icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(
                  int.parse('FF${category.colorHex}', radix: 16),
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Icon(
                IconUtils.getIconFromName(category.iconName),
                color: Color(
                  int.parse('FF${category.colorHex}', radix: 16),
                ),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Category info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$taskCount ${AppLocalizations.of(context)!.tasks}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // More icon
            PopupMenuButton<String>(
              icon: Icon(
                LucideIcons.moreVertical,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textPlaceholder,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              color: isDark ? AppColors.backgroundDark : AppColors.background,
              elevation: 2,
              offset: const Offset(0, 8),
              onSelected: (value) {
                if (value == 'edit') {
                  onTap();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(LucideIcons.pencil, size: 18, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        AppLocalizations.of(context)!.edit,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        AppLocalizations.of(context)!.delete,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCreateModal extends StatefulWidget {
  final Category? category;

  const _CategoryCreateModal({this.category});

  @override
  State<_CategoryCreateModal> createState() => _CategoryCreateModalState();
}

class _CategoryCreateModalState extends State<_CategoryCreateModal> {
  late TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIcon;

  static const List<String> _colors = [
    '8B5CF6', // Purple
    '14B8A6', // Teal
    'F472B6', // Pink
    'F59E0B', // Amber
    'EF4444', // Red
    '6366F1', // Indigo
  ];

  static const List<IconData> _icons = [
    LucideIcons.folder,
    LucideIcons.briefcase,
    LucideIcons.user,
    LucideIcons.shoppingCart,
    LucideIcons.graduationCap,
    LucideIcons.home,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.colorHex ?? _colors.first;
    _selectedIcon = widget.category?.iconName ?? 'folder';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
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
                  isEditing ? AppLocalizations.of(context)!.editCategory : AppLocalizations.of(context)!.newCategory,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
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
                // Name field
                Text(
                  AppLocalizations.of(context)!.categoryName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.enterName,
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textPlaceholder,
                        fontSize: 15,
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Color field
                Text(
                  AppLocalizations.of(context)!.color,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _colors.map((colorHex) {
                    final isSelected = _selectedColor == colorHex;
                    final color = Color(int.parse('FF$colorHex', radix: 16));
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedColor = colorHex);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(22),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Icon field
                Text(
                  AppLocalizations.of(context)!.icon,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _icons.map((icon) {
                    final iconName = IconUtils.getIconName(icon);
                    final isSelected = _selectedIcon == iconName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedIcon = iconName);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : (isDark ? AppColors.surfaceDark : AppColors.surface),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Create button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    final l10n = AppLocalizations.of(context)!;
                    if (isEditing) {
                      context.read<CategoryBloc>().add(
                            CategoryEvent.updateCategory(
                              category: widget.category!.copyWith(
                                name: _nameController.text,
                                colorHex: _selectedColor,
                                iconName: _selectedIcon,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                      // Show snackbar after a short delay to ensure context is valid
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted) {
                          CustomSnackbar.showSuccess(context, l10n.categoryUpdated);
                        }
                      });
                    } else {
                      const uuid = Uuid();
                      final newCategory = Category(
                        id: uuid.v4(),
                        name: _nameController.text,
                        colorHex: _selectedColor,
                        iconName: _selectedIcon,
                        createdAt: DateTime.now(),
                        taskCount: 0,
                      );
                      context.read<CategoryBloc>().add(
                            CategoryEvent.createCategory(category: newCategory),
                          );
                      Navigator.pop(context);
                      // Show snackbar after a short delay to ensure context is valid
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted) {
                          CustomSnackbar.showSuccess(context, l10n.categoryCreated);
                        }
                      });
                    }
                  }
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
                  isEditing ? AppLocalizations.of(context)!.updateCategory : AppLocalizations.of(context)!.createCategory,
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
}
