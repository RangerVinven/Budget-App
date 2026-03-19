import 'category_item.dart';

class CategoryGroup {
  final String id;
  final String name;
  final List<CategoryItem> items;

  const CategoryGroup({
    required this.id,
    required this.name,
    this.items = const [],
  });

  CategoryGroup copyWith({
    String? id,
    String? name,
    List<CategoryItem>? items,
  }) {
    return CategoryGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}