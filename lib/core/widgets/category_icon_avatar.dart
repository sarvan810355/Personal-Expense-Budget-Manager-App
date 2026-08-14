import 'package:flutter/material.dart';

import '../constants/icon_map.dart';

/// Circular icon badge tinted with a category/account's stored [color],
/// used by the category list, expense list/detail, and calendar day view
/// so the same entity always renders identically across screens.
class CategoryIconAvatar extends StatelessWidget {
  const CategoryIconAvatar({
    required this.iconName,
    required this.color,
    super.key,
    this.radius = 20,
  });

  final String iconName;
  final int color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color tint = Color(color);
    return CircleAvatar(
      radius: radius,
      backgroundColor: tint.withOpacity(0.15),
      child: Icon(AppIcons.byName(iconName), color: tint, size: radius),
    );
  }
}
