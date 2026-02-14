import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:habit_tracker/core/usecases/usecase.dart';
import 'package:habit_tracker/features/categories/domain/entities/category_entity.dart';
import 'package:habit_tracker/features/categories/domain/usecases/category_usecases.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetCategories getCategories;
  final AddCategory addCategory;
  final DeleteCategory deleteCategory;
  final SeedCategories seedCategories;

  CategoryBloc({
    required this.getCategories,
    required this.addCategory,
    required this.deleteCategory,
    required this.seedCategories,
  }) : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategoryEvent>(_onAddCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await getCategories(NoParams());
    result.fold((failure) => emit(CategoryError(failure.message)), (
      categories,
    ) async {
      if (categories.isEmpty) {
        await seedCategories(NoParams());
        final retryResult = await getCategories(NoParams());
        retryResult.fold(
          (failure) => emit(CategoryError(failure.message)),
          (newCategories) => emit(CategoriesLoaded(newCategories)),
        );
      } else {
        emit(CategoriesLoaded(categories));
      }
    });
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await addCategory(event.category);
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (_) => add(LoadCategories()),
    );
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await deleteCategory(event.categoryId);
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (_) => add(LoadCategories()),
    );
  }
}
