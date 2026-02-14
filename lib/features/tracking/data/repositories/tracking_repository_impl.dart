import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final SupabaseClient supabaseClient;

  TrackingRepositoryImpl(this.supabaseClient);

  @override
  Future<Either<Failure, List<String>>> getCompletionsForDate(
    DateTime date,
  ) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await supabaseClient
          .from('habit_completions')
          .select('habit_id')
          .eq('completed_date', formattedDate);

      final completedHabitIds = (response as List)
          .map((e) => e['habit_id'] as String)
          .toList();
      return Right(completedHabitIds);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> completeHabit(
    String habitId,
    DateTime date,
  ) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final userId = supabaseClient.auth.currentUser!.id;

      final today = DateTime(date.year, date.month, date.day);

      // Perform transaction-like operations
      await supabaseClient
          .rpc(
            'complete_habit',
            params: {
              'p_habit_id': habitId,
              'p_user_id': userId,
              'p_date': formattedDate,
            },
          )
          .catchError((error) async {
            // Fallback to manual updates if RPC fails or doesn't exist yet
            // 1. Insert completion
            await supabaseClient.from('habit_completions').insert({
              'habit_id': habitId,
              'user_id': userId,
              'completed_date': formattedDate,
            });

            // 2. Fetch current habit data
            final habitResponse = await supabaseClient
                .from('habits')
                .select('current_streak, longest_streak, last_completed_date')
                .eq('id', habitId)
                .single();

            int currentStreak = habitResponse['current_streak'] ?? 0;
            int longestStreak = habitResponse['longest_streak'] ?? 0;
            final lastCompletedStr = habitResponse['last_completed_date'];
            DateTime? lastCompletedDate = lastCompletedStr != null
                ? DateTime.parse(lastCompletedStr)
                : null;

            // 3. Calculate new streak
            if (lastCompletedDate != null) {
              final difference = today.difference(lastCompletedDate).inDays;
              if (difference == 1) {
                // Consecutive day
                currentStreak++;
              } else if (difference > 1) {
                // Streak broken
                // Save old streak to history
                if (currentStreak > 0) {
                  await supabaseClient.from('streak_history').insert({
                    'habit_id': habitId,
                    'user_id': userId,
                    'streak_count': currentStreak,
                    'started_date': lastCompletedDate
                        .subtract(Duration(days: currentStreak - 1))
                        .toIso8601String(),
                    'ended_date': lastCompletedDate.toIso8601String(),
                  });
                }
                currentStreak = 1;
              }
              // If difference == 0 (same day), do nothing (should be handled by unique constraint on completions)
            } else {
              // First completion ever
              currentStreak = 1;
            }

            if (currentStreak > longestStreak) {
              longestStreak = currentStreak;
            }

            // 4. Update habit
            await supabaseClient
                .from('habits')
                .update({
                  'current_streak': currentStreak,
                  'longest_streak': longestStreak,
                  'last_completed_date': formattedDate,
                })
                .eq('id', habitId);

            return null;
          });

      return Right(habitId);
    } catch (e) {
      if (e is PostgrestException && e.code == '23505') {
        // Unique constraint violation - already completed details
        return Right(habitId);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> uncompleteHabit(
    String habitId,
    DateTime date,
  ) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final userId = supabaseClient.auth.currentUser!.id;

      // 1. Delete the completion
      await supabaseClient
          .from('habit_completions')
          .delete()
          .eq('habit_id', habitId)
          .eq('completed_date', formattedDate);

      // 2. Fetch current habit data
      final habitResponse = await supabaseClient
          .from('habits')
          .select('current_streak, last_completed_date')
          .eq('id', habitId)
          .single();

      final lastCompletedStr = habitResponse['last_completed_date'];

      // 3. Recalculate streak based on the new last completed date
      if (lastCompletedStr == formattedDate) {
        // Find the new last_completed_date
        final latestCompletionResponse = await supabaseClient
            .from('habit_completions')
            .select('completed_date')
            .eq('habit_id', habitId)
            .order('completed_date', ascending: false)
            .limit(1)
            .maybeSingle();

        final String? newLastCompletedDate = latestCompletionResponse != null
            ? latestCompletionResponse['completed_date']
            : null;

        int newStreak = 0;
        if (newLastCompletedDate != null) {
          newStreak = await _calculateStreak(
            habitId,
            DateTime.parse(newLastCompletedDate),
          );
        }

        await supabaseClient
            .from('habits')
            .update({
              'current_streak': newStreak,
              'last_completed_date': newLastCompletedDate,
            })
            .eq('id', habitId);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<int> _calculateStreak(String habitId, DateTime endDate) async {
    try {
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      final response = await supabaseClient
          .from('habit_completions')
          .select('completed_date')
          .eq('habit_id', habitId)
          .lte('completed_date', formattedEndDate)
          .order('completed_date', ascending: false);

      final dates = (response as List)
          .map((e) => DateTime.parse(e['completed_date'] as String))
          .toList();

      if (dates.isEmpty) return 0;

      int streak = 0;
      DateTime expectedDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      );

      for (final date in dates) {
        final d = DateTime(date.year, date.month, date.day);

        if (d.isAtSameMomentAs(expectedDate)) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else if (d.isBefore(expectedDate)) {
          // Gap found
          break;
        }
        // If d is after expectedDate, it means we have duplicates or unordered data (but we ordered by desc)
        // With 'lte' filter, d cannot be > original endDate.
        // But if we decremented expectedDate, d could be > expectedDate?
        // No, because we iterate desc.
        // Example: End=10. Expected=10. D=10. Streak=1. Expected=9.
        // D=9. Streak=2. Expected=8.
        // D=7. 7 < 8. Break.
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getCompletionsForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      final response = await supabaseClient
          .from('habit_completions')
          .select('habit_id, completed_date')
          .gte('completed_date', startStr)
          .lte('completed_date', endStr);

      final data = (response as List).cast<Map<String, dynamic>>();
      return Right(data);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
