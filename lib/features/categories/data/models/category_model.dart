import 'package:habit_tracker/features/categories/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.icon,
    required super.colorHex,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      icon: json['icon'] ?? '🔖',
      colorHex: json['color_hex'] ?? 'FF9800',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color_hex': colorHex,
    };
  }
}
