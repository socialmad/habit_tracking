import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/repositories/habit_repository.dart';
import '../models/habit_model.dart';

class HabitRepositoryImpl implements HabitRepository {
  final SupabaseClient supabaseClient;

  HabitRepositoryImpl(this.supabaseClient);

  @override
  Future<Either<Failure, List<HabitEntity>>> getHabits() async {
    try {
      final response = await supabaseClient
          .from('habits')
          .select()
          .order('created_at', ascending: false);

      final habits = (response as List)
          .map((e) => HabitModel.fromJson(e))
          .toList();
      return Right(habits);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HabitEntity>> addHabit(HabitEntity habit) async {
    try {
      final habitModel = HabitModel(
        id: habit.id,
        userId: supabaseClient.auth.currentUser!.id,
        name: habit.name,
        description: habit.description,
        iconAsset: habit.iconAsset,
        colorHex: habit.colorHex,
        frequency: habit.frequency,
        categoryId: habit.categoryId,
        reminderTime: habit.reminderTime,
        reminderEnabled: habit.reminderEnabled,
        reminderDays: habit.reminderDays,
        createdAt: habit.createdAt,
        archived: habit.archived,
      );

      final response = await supabaseClient
          .from('habits')
          .insert(habitModel.toJson())
          .select()
          .single();

      return Right(HabitModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HabitEntity>> updateHabit(HabitEntity habit) async {
    try {
      final habitModel = HabitModel(
        id: habit.id,
        userId: habit.userId,
        name: habit.name,
        description: habit.description,
        iconAsset: habit.iconAsset,
        colorHex: habit.colorHex,
        frequency: habit.frequency,
        categoryId: habit.categoryId,
        reminderTime: habit.reminderTime,
        reminderEnabled: habit.reminderEnabled,
        reminderDays: habit.reminderDays,
        createdAt: habit.createdAt,
        archived: habit.archived,
      );

      final response = await supabaseClient
          .from('habits')
          .update(habitModel.toJson())
          .eq('id', habit.id)
          .select()
          .single();

      return Right(HabitModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHabit(String habitId) async {
    try {
      await supabaseClient.from('habits').delete().eq('id', habitId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
