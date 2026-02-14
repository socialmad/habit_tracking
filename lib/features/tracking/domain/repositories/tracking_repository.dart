import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class TrackingRepository {
  Future<Either<Failure, List<String>>> getCompletionsForDate(DateTime date);
  Future<Either<Failure, String>> completeHabit(String habitId, DateTime date);
  Future<Either<Failure, void>> uncompleteHabit(String habitId, DateTime date);
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getCompletionsForDateRange(DateTime startDate, DateTime endDate);
}
