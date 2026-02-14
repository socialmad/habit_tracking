import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String colorHex;

  const CategoryEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.colorHex,
  });

  @override
  List<Object> get props => [id, userId, name, icon, colorHex];
}
