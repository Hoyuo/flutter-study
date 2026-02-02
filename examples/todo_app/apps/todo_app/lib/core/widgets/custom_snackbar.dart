import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomSnackbar {
  CustomSnackbar._();

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _SnackbarContent(
          message: message,
          type: _SnackbarType.success,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _SnackbarContent(
          message: message,
          type: _SnackbarType.error,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

enum _SnackbarType { success, error }

class _SnackbarContent extends StatelessWidget {
  final String message;
  final _SnackbarType type;

  const _SnackbarContent({
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getColors(isDark);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colors.containerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.iconContainerColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              type == _SnackbarType.success ? LucideIcons.check : LucideIcons.x,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          // Message text
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _SnackbarColors _getColors(bool isDark) {
    if (type == _SnackbarType.success) {
      return _SnackbarColors(
        containerColor: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
        iconContainerColor: const Color(0xFF22C55E),
        textColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
      );
    } else {
      return _SnackbarColors(
        containerColor: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
        iconContainerColor: const Color(0xFFEF4444),
        textColor: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
      );
    }
  }
}

class _SnackbarColors {
  final Color containerColor;
  final Color iconContainerColor;
  final Color textColor;

  const _SnackbarColors({
    required this.containerColor,
    required this.iconContainerColor,
    required this.textColor,
  });
}
