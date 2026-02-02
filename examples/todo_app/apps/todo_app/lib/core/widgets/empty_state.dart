import 'package:flutter/material.dart';
import 'package:todo_app/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

/// Reusable empty state widget for various empty scenarios
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.buttonIcon,
    this.onButtonPressed,
    this.buttonColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final IconData? buttonIcon;
  final VoidCallback? onButtonPressed;
  final Color? buttonColor;

  /// Empty state for when there are no tasks
  factory EmptyState.noTasks({
    required BuildContext context,
    required VoidCallback onNewTask,
  }) {
    return EmptyState(
      icon: LucideIcons.clipboardList,
      title: AppLocalizations.of(context)!.noTasksYet,
      description: AppLocalizations.of(context)!.startByAdding,
      buttonLabel: AppLocalizations.of(context)!.newTask,
      buttonIcon: LucideIcons.plus,
      onButtonPressed: onNewTask,
      buttonColor: AppColors.primary,
    );
  }

  /// Empty state for when search returns no results
  factory EmptyState.noSearchResults({
    required BuildContext context,
    required VoidCallback onClearFilters,
  }) {
    return EmptyState(
      icon: LucideIcons.searchX,
      title: AppLocalizations.of(context)!.noSearchResults,
      description: AppLocalizations.of(context)!.tryDifferentKeywords,
      buttonLabel: AppLocalizations.of(context)!.clearFilters,
      onButtonPressed: onClearFilters,
    );
  }

  /// Empty state for when there are no categories
  factory EmptyState.noCategories({
    required BuildContext context,
    required VoidCallback onNewCategory,
  }) {
    return EmptyState(
      icon: LucideIcons.folderOpen,
      title: AppLocalizations.of(context)!.noCategories,
      description: AppLocalizations.of(context)!.addToOrganize,
      buttonLabel: AppLocalizations.of(context)!.newCategory,
      onButtonPressed: onNewCategory,
      buttonColor: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Icon container colors
    final iconContainerColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final iconColor = isDark ? AppColors.textSecondaryDark : AppColors.textPlaceholder;

    // Button colors
    final Color resolvedButtonColor;
    if (buttonColor != null) {
      resolvedButtonColor = buttonColor!;
    } else {
      resolvedButtonColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    }

    final buttonTextColor = buttonColor == AppColors.primary
        ? AppColors.textOnPrimary
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconContainerColor,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 36,
                color: iconColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            // Button (if provided)
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: resolvedButtonColor,
                  foregroundColor: buttonTextColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (buttonIcon != null) ...[
                      Icon(buttonIcon, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(buttonLabel!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
