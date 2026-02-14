import 'package:equatable/equatable.dart';
import 'package:habit_tracker/features/stats/domain/entities/global_stats_entity.dart';
import 'package:habit_tracker/features/stats/domain/entities/stats_entity.dart';

abstract class StatsState extends Equatable {
  const StatsState();
  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final StatsEntity? stats;
  final GlobalStatsEntity? globalStats;
  final Map<DateTime, int>? heatMapData;

  const StatsLoaded({this.stats, this.globalStats, this.heatMapData});

  StatsLoaded copyWith({
    StatsEntity? stats,
    GlobalStatsEntity? globalStats,
    Map<DateTime, int>? heatMapData,
  }) {
    return StatsLoaded(
      stats: stats ?? this.stats,
      globalStats: globalStats ?? this.globalStats,
      heatMapData: heatMapData ?? this.heatMapData,
    );
  }

  @override
  List<Object?> get props => [stats, globalStats, heatMapData];
}

class StatsError extends StatsState {
  final String message;
  const StatsError(this.message);
  @override
  List<Object?> get props => [message];
}
