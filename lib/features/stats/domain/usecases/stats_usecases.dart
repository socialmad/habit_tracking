import 'package:dartz/dartz.dart';
import 'package:habit_tracker/core/error/failures.dart';
import 'package:habit_tracker/core/usecases/usecase.dart';
import 'package:habit_tracker/features/stats/domain/entities/stats_entity.dart';
import 'package:habit_tracker/features/stats/domain/repositories/stats_repository.dart';

import 'package:habit_tracker/features/stats/domain/entities/global_stats_entity.dart';

class GetHabitStats implements UseCase<StatsEntity, String> {
  final StatsRepository repository;
  GetHabitStats(this.repository);
  @override
  Future<Either<Failure, StatsEntity>> call(String habitId) async =>
      await repository.getStatsForHabit(habitId);
}

class GetGlobalStats implements UseCase<GlobalStatsEntity, NoParams> {
  final StatsRepository repository;
  GetGlobalStats(this.repository);
  @override
  Future<Either<Failure, GlobalStatsEntity>> call(NoParams params) async =>
      await repository.getGlobalStats();
}

class GetHeatMapData implements UseCase<Map<DateTime, int>, NoParams> {
  final StatsRepository repository;
  GetHeatMapData(this.repository);
  @override
  Future<Either<Failure, Map<DateTime, int>>> call(NoParams params) async =>
      await repository.getHeatMapData();
}
