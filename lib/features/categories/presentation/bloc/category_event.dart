part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object> get props => [];
}

class LoadCategories extends CategoryEvent {}

class AddCategoryEvent extends CategoryEvent {
  final CategoryEntity category;
  const AddCategoryEvent(this.category);
  @override
  List<Object> get props => [category];
}

class DeleteCategoryEvent extends CategoryEvent {
  final String categoryId;
  const DeleteCategoryEvent(this.categoryId);
  @override
  List<Object> get props => [categoryId];
}
