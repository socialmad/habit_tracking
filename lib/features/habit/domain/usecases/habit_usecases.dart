import 'package:dartz/dartz.dart';

import 'package:habit_tracker/core/error/failures.dart';
import 'package:habit_tracker/core/usecases/usecase.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/habit/domain/repositories/habit_repository.dart';

class GetHabits implements UseCase<List<HabitEntity>, NoParams> {
  final HabitRepository repository;
  GetHabits(this.repository);
  @override
  Future<Either<Failure, List<HabitEntity>>> call(NoParams params) async =>
      await repository.getHabits();
}

class AddHabit implements UseCase<HabitEntity, HabitEntity> {
  final HabitRepository repository;
  AddHabit(this.repository);
  @override
  Future<Either<Failure, HabitEntity>> call(HabitEntity params) async =>
      await repository.addHabit(params);
}

class UpdateHabit implements UseCase<HabitEntity, HabitEntity> {
  final HabitRepository repository;
  UpdateHabit(this.repository);
  @override
  Future<Either<Failure, HabitEntity>> call(HabitEntity params) async =>
      await repository.updateHabit(params);
}

class DeleteHabit implements UseCase<void, String> {
  final HabitRepository repository;
  DeleteHabit(this.repository);
  @override
  Future<Either<Failure, void>> call(String params) async =>
      await repository.deleteHabit(params);
}
