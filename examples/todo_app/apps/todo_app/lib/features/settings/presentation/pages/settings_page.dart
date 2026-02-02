import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_app/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:settings/settings.dart';
import 'package:todo_app/core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            final settings = state.settings;

            return Column(
                children: [
                  // Header
                  _buildHeader(context),
                  // Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Appearance Section
                        _buildSectionLabel(AppLocalizations.of(context)!.appearance, isDark),
                        const SizedBox(height: 12),
                        _buildSectionContainer(
                          isDark: isDark,
                          children: [
                            _buildThemeItem(context, settings.themeMode, isDark),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // General Section
                        _buildSectionLabel(AppLocalizations.of(context)!.general, isDark),
                        const SizedBox(height: 12),
                        _buildSectionContainer(
                          isDark: isDark,
                          children: [
                            _buildNotificationItem(
                              context,
                              settings.notificationsEnabled,
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildLanguageItem(context, settings.language, isDark),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // About Section
                        _buildSectionLabel(AppLocalizations.of(context)!.about, isDark),
                        const SizedBox(height: 12),
                        _buildSectionContainer(
                          isDark: isDark,
                          children: [
                            _buildVersionItem(context, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Back button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              icon: Icon(
                LucideIcons.arrowLeft,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
          // Title
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.settings,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          // Placeholder for symmetry
          const SizedBox(
            width: 44,
            height: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSectionContainer({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildThemeItem(BuildContext context, ThemeMode themeMode, bool isDark) {
    return Row(
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.sunMoon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Title
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.theme,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        // Value
        DropdownButton<ThemeMode>(
          value: themeMode,
          underline: const SizedBox(),
          isDense: true,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text(AppLocalizations.of(context)!.themeSystem),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text(AppLocalizations.of(context)!.themeLight),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text(AppLocalizations.of(context)!.themeDark),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(
                    SettingsEvent.updateTheme(value),
                  );
            }
          },
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    bool notificationsEnabled,
    bool isDark,
  ) {
    return Row(
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.bell,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Title
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.notifications,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        // Switch
        Switch(
          value: notificationsEnabled,
          onChanged: (_) {
            context.read<SettingsBloc>().add(
                  const SettingsEvent.toggleNotifications(),
                );
          },
          activeTrackColor: AppColors.primary,
          thumbColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ],
    );
  }

  Widget _buildLanguageItem(BuildContext context, String language, bool isDark) {
    return Row(
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.globe,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Title
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.language,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        // Value
        DropdownButton<String>(
          value: language,
          underline: const SizedBox(),
          isDense: true,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          items: const [
            DropdownMenuItem(
              value: 'en',
              child: Text('English'),
            ),
            DropdownMenuItem(
              value: 'ko',
              child: Text('한국어'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(
                    SettingsEvent.updateLanguage(value),
                  );
            }
          },
        ),
      ],
    );
  }

  Widget _buildVersionItem(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.info,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Title
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.version,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        // Value
        Text(
          '1.0.0',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
