import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import 'package:habit_tracker/features/stats/domain/entities/global_stats_entity.dart';
import 'package:habit_tracker/features/stats/domain/entities/stats_entity.dart';

abstract class StatsRepository {
  Future<Either<Failure, StatsEntity>> getStatsForHabit(String habitId);
  Future<Either<Failure, GlobalStatsEntity>> getGlobalStats();
  Future<Either<Failure, Map<DateTime, int>>>
  getHeatMapData(); // Date -> Completion Count
}
