import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/category_group.dart';
import '../models/category_item.dart';

final defaultCategoryGroupsInitial = [
  const CategoryGroup(
    id: 'cg_giving',
    name: 'Giving',
    items: [CategoryItem(id: 'ci_tithe', name: 'Tithe'), CategoryItem(id: 'ci_charity', name: 'Charity')],
  ),
  const CategoryGroup(
    id: 'cg_saving',
    name: 'Saving',
    items: [CategoryItem(id: 'ci_emergency', name: 'Emergency Fund')],
  ),
  const CategoryGroup(
    id: 'cg_housing',
    name: 'Housing',
    items: [CategoryItem(id: 'ci_rent', name: 'Rent/Mortgage'), CategoryItem(id: 'ci_water', name: 'Water'), CategoryItem(id: 'ci_elec', name: 'Electricity')],
  ),
  const CategoryGroup(
    id: 'cg_transportation',
    name: 'Transportation',
    items: [CategoryItem(id: 'ci_gas', name: 'Gas'), CategoryItem(id: 'ci_maintenance', name: 'Maintenance')],
  ),
  const CategoryGroup(
    id: 'cg_food',
    name: 'Food',
    items: [CategoryItem(id: 'ci_groceries', name: 'Groceries'), CategoryItem(id: 'ci_restaurants', name: 'Restaurants')],
  ),
  const CategoryGroup(
    id: 'cg_personal',
    name: 'Personal',
    items: [CategoryItem(id: 'ci_clothing', name: 'Clothing'), CategoryItem(id: 'ci_fun', name: 'Fun Money')],
  ),
];

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    return const UserProfile(name: 'User', email: 'user@example.com');
  }

  void updateProfile({String? name, String? email}) {
    state = state.copyWith(name: name, email: email);
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);

class DefaultCategoriesNotifier extends Notifier<List<CategoryGroup>> {
  @override
  List<CategoryGroup> build() {
    return defaultCategoryGroupsInitial;
  }

  void revertToDefault() {
    state = defaultCategoryGroupsInitial;
  }

  void addGroup(CategoryGroup group) {
    state = [...state, group];
  }

  void updateGroupName(String groupId, String name) {
    state = state.map((g) {
      if (g.id == groupId) return g.copyWith(name: name);
      return g;
    }).toList();
  }

  void addItemToGroup(String groupId, CategoryItem item) {
    state = state.map((g) {
      if (g.id == groupId) return g.copyWith(items: [...g.items, item]);
      return g;
    }).toList();
  }

  void updateItemName(String groupId, String itemId, String name) {
    state = state.map((g) {
      if (g.id == groupId) {
        return g.copyWith(
          items: g.items.map((i) => i.id == itemId ? i.copyWith(name: name) : i).toList(),
        );
      }
      return g;
    }).toList();
  }

  void deleteGroup(String groupId) {
    state = state.where((g) => g.id != groupId).toList();
  }

  void deleteItem(String groupId, String itemId) {
    state = state.map((g) {
      if (g.id == groupId) {
        return g.copyWith(items: g.items.where((i) => i.id != itemId).toList());
      }
      return g;
    }).toList();
  }
}

final defaultCategoriesProvider = NotifierProvider<DefaultCategoriesNotifier, List<CategoryGroup>>(DefaultCategoriesNotifier.new);