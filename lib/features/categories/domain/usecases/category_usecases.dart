import 'package:dartz/dartz.dart';
import 'package:habit_tracker/core/error/failures.dart';
import 'package:habit_tracker/core/usecases/usecase.dart';
import 'package:habit_tracker/features/categories/domain/entities/category_entity.dart';
import 'package:habit_tracker/features/categories/domain/repositories/category_repository.dart';

class GetCategories implements UseCase<List<CategoryEntity>, NoParams> {
  final CategoryRepository repository;
  GetCategories(this.repository);
  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams params) async =>
      await repository.getCategories();
}

class AddCategory implements UseCase<CategoryEntity, CategoryEntity> {
  final CategoryRepository repository;
  AddCategory(this.repository);
  @override
  Future<Either<Failure, CategoryEntity>> call(CategoryEntity category) async =>
      await repository.addCategory(category);
}

class DeleteCategory implements UseCase<void, String> {
  final CategoryRepository repository;
  DeleteCategory(this.repository);
  @override
  Future<Either<Failure, void>> call(String categoryId) async =>
      await repository.deleteCategory(categoryId);
}

class SeedCategories implements UseCase<void, NoParams> {
  final CategoryRepository repository;
  SeedCategories(this.repository);
  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await repository.seedDefaultCategories();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
