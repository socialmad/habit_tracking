import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, CategoryEntity>> addCategory(CategoryEntity category);
  Future<Either<Failure, void>> deleteCategory(String categoryId);
  Future<void> seedDefaultCategories();
}
