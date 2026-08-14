import 'package:flutter/material.dart';

/// Resolves the string icon keys stored in the DB (see
/// `default_categories.dart`) to concrete [IconData].
class AppIcons {
  const AppIcons._();

  static const Map<String, IconData> _byName = <String, IconData>{
    'restaurant': Icons.restaurant,
    'restaurant_menu': Icons.restaurant_menu,
    'local_grocery_store': Icons.local_grocery_store,
    'local_cafe': Icons.local_cafe,
    'directions_bus': Icons.directions_bus,
    'shopping_bag': Icons.shopping_bag,
    'receipt_long': Icons.receipt_long,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'home': Icons.home,
    'flight': Icons.flight,
    'subscriptions': Icons.subscriptions,
    'spa': Icons.spa,
    'card_giftcard': Icons.card_giftcard,
    'category': Icons.category,
    'work': Icons.work,
    'store': Icons.store,
    'trending_up': Icons.trending_up,
    'laptop_mac': Icons.laptop_mac,
    'redeem': Icons.redeem,
    'attach_money': Icons.attach_money,
    'wallet': Icons.account_balance_wallet,
    'bank': Icons.account_balance,
    'credit_card': Icons.credit_card,
  };

  static IconData byName(String name) => _byName[name] ?? Icons.circle;

  /// All selectable icon keys, for the category/account icon picker.
  static List<String> get allNames => _byName.keys.toList(growable: false);
}

/// Curated Material palette offered by the category/account color picker.
const List<int> kColorPalette = <int>[
  0xFFEF6C00,
  0xFF1976D2,
  0xFF8E24AA,
  0xFF546E7A,
  0xFFD81B60,
  0xFFE53935,
  0xFF3949AB,
  0xFF6D4C41,
  0xFF00897B,
  0xFF5E35B1,
  0xFFAD1457,
  0xFFC2185B,
  0xFF2E7D32,
  0xFF757575,
  0xFFF9A825,
  0xFF0097A7,
];
