/// Seed data for the `Category` table, inserted once by the Phase 1 DB
/// migration (see `AppDatabase._seedDefaultCategories`).
///
/// `icon` stores a lookup key resolved to a [IconData] via
/// `AppIcons.byName` (see `icon_map.dart`) rather than a raw codepoint, so
/// icon packs can change without touching stored data.
library;

class DefaultCategorySeed {
  const DefaultCategorySeed({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.parentName,
    this.sortOrder = 0,
  });

  final String name;
  final String icon;
  final int color;
  final String type; // 'expense' | 'income'
  final String? parentName;
  final int sortOrder;
}

/// Default expense categories, with a couple of Food subcategories to
/// demonstrate the self-referential `parentCategoryId` hierarchy.
const List<DefaultCategorySeed> kDefaultExpenseCategories = <DefaultCategorySeed>[
  DefaultCategorySeed(name: 'Food', icon: 'restaurant', color: 0xFFEF6C00, type: 'expense', sortOrder: 0),
  DefaultCategorySeed(name: 'Restaurant', icon: 'restaurant_menu', color: 0xFFEF6C00, type: 'expense', parentName: 'Food', sortOrder: 1),
  DefaultCategorySeed(name: 'Groceries', icon: 'local_grocery_store', color: 0xFFEF6C00, type: 'expense', parentName: 'Food', sortOrder: 2),
  DefaultCategorySeed(name: 'Cafe', icon: 'local_cafe', color: 0xFFEF6C00, type: 'expense', parentName: 'Food', sortOrder: 3),
  DefaultCategorySeed(name: 'Transport', icon: 'directions_bus', color: 0xFF1976D2, type: 'expense', sortOrder: 4),
  DefaultCategorySeed(name: 'Shopping', icon: 'shopping_bag', color: 0xFF8E24AA, type: 'expense', sortOrder: 5),
  DefaultCategorySeed(name: 'Bills & Utilities', icon: 'receipt_long', color: 0xFF546E7A, type: 'expense', sortOrder: 6),
  DefaultCategorySeed(name: 'Entertainment', icon: 'movie', color: 0xFFD81B60, type: 'expense', sortOrder: 7),
  DefaultCategorySeed(name: 'Health', icon: 'local_hospital', color: 0xFFE53935, type: 'expense', sortOrder: 8),
  DefaultCategorySeed(name: 'Education', icon: 'school', color: 0xFF3949AB, type: 'expense', sortOrder: 9),
  DefaultCategorySeed(name: 'Rent', icon: 'home', color: 0xFF6D4C41, type: 'expense', sortOrder: 10),
  DefaultCategorySeed(name: 'Travel', icon: 'flight', color: 0xFF00897B, type: 'expense', sortOrder: 11),
  DefaultCategorySeed(name: 'Subscriptions', icon: 'subscriptions', color: 0xFF5E35B1, type: 'expense', sortOrder: 12),
  DefaultCategorySeed(name: 'Personal Care', icon: 'spa', color: 0xFFAD1457, type: 'expense', sortOrder: 13),
  DefaultCategorySeed(name: 'Gifts & Donations', icon: 'card_giftcard', color: 0xFFC2185B, type: 'expense', sortOrder: 14),
  DefaultCategorySeed(name: 'Others', icon: 'category', color: 0xFF757575, type: 'expense', sortOrder: 15),
];

/// Default income categories.
const List<DefaultCategorySeed> kDefaultIncomeCategories = <DefaultCategorySeed>[
  DefaultCategorySeed(name: 'Salary', icon: 'work', color: 0xFF2E7D32, type: 'income', sortOrder: 0),
  DefaultCategorySeed(name: 'Business', icon: 'store', color: 0xFF2E7D32, type: 'income', sortOrder: 1),
  DefaultCategorySeed(name: 'Investment', icon: 'trending_up', color: 0xFF2E7D32, type: 'income', sortOrder: 2),
  DefaultCategorySeed(name: 'Freelance', icon: 'laptop_mac', color: 0xFF2E7D32, type: 'income', sortOrder: 3),
  DefaultCategorySeed(name: 'Gift', icon: 'redeem', color: 0xFF2E7D32, type: 'income', sortOrder: 4),
  DefaultCategorySeed(name: 'Other Income', icon: 'attach_money', color: 0xFF2E7D32, type: 'income', sortOrder: 5),
];

List<DefaultCategorySeed> get kAllDefaultCategories =>
    <DefaultCategorySeed>[...kDefaultExpenseCategories, ...kDefaultIncomeCategories];
