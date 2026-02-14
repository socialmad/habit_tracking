import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:habit_tracker/core/error/failures.dart';
import 'package:habit_tracker/core/usecases/usecase.dart';
import 'package:habit_tracker/features/tracking/domain/repositories/tracking_repository.dart';

class GetCompletionsForDate implements UseCase<List<String>, DateTime> {
  final TrackingRepository repository;
  GetCompletionsForDate(this.repository);
  @override
  Future<Either<Failure, List<String>>> call(DateTime date) async =>
      await repository.getCompletionsForDate(date);
}

class CompleteHabit implements UseCase<String, CompletionParams> {
  final TrackingRepository repository;
  CompleteHabit(this.repository);
  @override
  Future<Either<Failure, String>> call(CompletionParams params) async =>
      await repository.completeHabit(params.habitId, params.date);
}

class UncompleteHabit implements UseCase<void, CompletionParams> {
  final TrackingRepository repository;
  UncompleteHabit(this.repository);
  @override
  Future<Either<Failure, void>> call(CompletionParams params) async =>
      await repository.uncompleteHabit(params.habitId, params.date);
}

class GetCompletionsForDateRange
    implements UseCase<List<Map<String, dynamic>>, DateRangeParams> {
  final TrackingRepository repository;
  GetCompletionsForDateRange(this.repository);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
    DateRangeParams params,
  ) async => await repository.getCompletionsForDateRange(
    params.startDate,
    params.endDate,
  );
}

class DateRangeParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  const DateRangeParams({required this.startDate, required this.endDate});
  @override
  List<Object> get props => [startDate, endDate];
}

class CompletionParams extends Equatable {
  final String habitId;
  final DateTime date;
  const CompletionParams({required this.habitId, required this.date});
  @override
  List<Object> get props => [habitId, date];
}
