import 'package:flutter/material.dart';

class IconHelper {
  static const List<IconData> predefinedIcons = [
    Icons.folder,
    Icons.star,
    Icons.favorite,
    Icons.work,
    Icons.home,
    Icons.music_note,
    Icons.camera,
    Icons.book,
    Icons.pets,
    Icons.flight,
    Icons.train,
    Icons.directions_car,
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.lock,
    Icons.shield,
    Icons.key,
    Icons.wallet,
    Icons.notes,
    Icons.article,
    Icons.code,
    Icons.build,
  ];

  static IconData getIcon(int? codePoint) {
    if (codePoint == null) return Icons.folder_rounded;
    try {
      return predefinedIcons.firstWhere(
        (icon) => icon.codePoint == codePoint,
        orElse: () => Icons.folder_rounded,
      );
    } catch (_) {
      return Icons.folder_rounded;
    }
  }
}
