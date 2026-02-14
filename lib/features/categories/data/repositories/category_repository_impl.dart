import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_tracker/core/error/failures.dart';
import 'package:habit_tracker/features/categories/domain/entities/category_entity.dart';
import 'package:habit_tracker/features/categories/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final SupabaseClient supabaseClient;

  CategoryRepositoryImpl(this.supabaseClient);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;
      final response = await supabaseClient
          .from('categories')
          .select()
          .eq('user_id', userId)
          .order('name', ascending: true);

      final categories = (response as List)
          .map(
            (e) => CategoryEntity(
              id: e['id'],
              userId: e['user_id'],
              name: e['name'],
              icon: e['icon'] ?? '🏷️',
              colorHex: e['color_hex'] ?? '808080',
            ),
          )
          .toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> addCategory(
    CategoryEntity category,
  ) async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;
      final response = await supabaseClient
          .from('categories')
          .insert({
            'user_id': userId,
            'name': category.name,
            'icon': category.icon,
            'color_hex': category.colorHex,
          })
          .select()
          .single();

      return Right(
        CategoryEntity(
          id: response['id'],
          userId: response['user_id'],
          name: response['name'],
          icon: response['icon'],
          colorHex: response['color_hex'],
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> seedDefaultCategories() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    final existing = await supabaseClient
        .from('categories')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    if ((existing as List).isNotEmpty) return;

    final defaults = [
      {'name': 'Health & Fitness', 'icon': '💪', 'color_hex': 'FF5252'},
      {'name': 'Learning & Growth', 'icon': '📚', 'color_hex': '448AFF'},
      {'name': 'Mindfulness', 'icon': '🧘', 'color_hex': '7C4DFF'},
      {'name': 'Productivity', 'icon': '💼', 'color_hex': 'FFD740'},
      {'name': 'Creativity', 'icon': '🎨', 'color_hex': 'FF4081'},
      {'name': 'Home & Lifestyle', 'icon': '🏠', 'color_hex': '69F0AE'},
      {'name': 'Finance', 'icon': '💰', 'color_hex': '00E676'},
      {'name': 'Social', 'icon': '👥', 'color_hex': '40C4FF'},
    ];

    await supabaseClient
        .from('categories')
        .insert(defaults.map((d) => {...d, 'user_id': userId}).toList());
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String categoryId) async {
    try {
      await supabaseClient.from('categories').delete().eq('id', categoryId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
