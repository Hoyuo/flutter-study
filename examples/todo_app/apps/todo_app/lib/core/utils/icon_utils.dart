import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

class IconUtils {
  static IconData getIconFromName(String? iconName) {
    switch (iconName) {
      case 'folder':
        return LucideIcons.folder;
      case 'work':
        return LucideIcons.briefcase;
      case 'person':
        return LucideIcons.user;
      case 'shopping_cart':
        return LucideIcons.shoppingCart;
      case 'school':
        return LucideIcons.graduationCap;
      case 'home':
        return LucideIcons.home;
      default:
        return LucideIcons.folder;
    }
  }

  static String getIconName(IconData icon) {
    if (icon == LucideIcons.folder) return 'folder';
    if (icon == LucideIcons.briefcase) return 'work';
    if (icon == LucideIcons.user) return 'person';
    if (icon == LucideIcons.shoppingCart) return 'shopping_cart';
    if (icon == LucideIcons.graduationCap) return 'school';
    if (icon == LucideIcons.home) return 'home';
    return 'folder';
  }
}
