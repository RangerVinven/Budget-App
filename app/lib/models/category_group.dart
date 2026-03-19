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

  factory CategoryGroup.fromJson(Map<String, dynamic> json) {
    return CategoryGroup(
      id: json['id'],
      name: json['name'],
      items: (json['items'] as List? ?? [])
          .map((i) => CategoryItem.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

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