import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/tracking_repository.dart';

class GetHabitCalendarData
    implements UseCase<Map<DateTime, int>, GetHabitCalendarDataParams> {
  final TrackingRepository repository;

  GetHabitCalendarData(this.repository);

  @override
  Future<Either<Failure, Map<DateTime, int>>> call(
    GetHabitCalendarDataParams params,
  ) async {
    final result = await repository.getCompletionsForDateRange(
      params.startDate,
      params.endDate,
    );

    return result.map((data) {
      final Map<DateTime, int> heatmapData = {};

      for (var entry in data) {
        final dateStr = entry['completed_date'] as String;
        final date = DateTime.parse(dateStr);
        final normalizedDate = DateTime(date.year, date.month, date.day);

        // Filter by habitId if provided
        if (params.habitId != null && entry['habit_id'] != params.habitId) {
          continue;
        }

        heatmapData[normalizedDate] = (heatmapData[normalizedDate] ?? 0) + 1;
      }
      return heatmapData;
    });
  }
}

class GetHabitCalendarDataParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? habitId;

  GetHabitCalendarDataParams({
    required this.startDate,
    required this.endDate,
    this.habitId,
  });
}
