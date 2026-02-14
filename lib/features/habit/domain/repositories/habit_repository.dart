import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';

abstract class HabitRepository {
  Future<Either<Failure, List<HabitEntity>>> getHabits();
  Future<Either<Failure, HabitEntity>> addHabit(HabitEntity habit);
  Future<Either<Failure, HabitEntity>> updateHabit(HabitEntity habit);
  Future<Either<Failure, void>> deleteHabit(String habitId);
}
