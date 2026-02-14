import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();
    // Set timezone to device's local timezone
    // This automatically detects the device timezone and uses it
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      // Try to get the location by timezone name (e.g., "IST", "PST", etc.)
      // If that fails, fall back to UTC offset detection
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
    } catch (e) {
      // Fallback: Use the system's local timezone
      // This works by detecting the UTC offset from the device
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Find a timezone that matches the current offset
      // This is a fallback approach when timezone name is not recognized
      for (final locationName in tz.timeZoneDatabase.locations.keys) {
        final location = tz.getLocation(locationName);
        final testTime = tz.TZDateTime.now(location);
        if (testTime.timeZoneOffset == offset) {
          tz.setLocalLocation(location);
          break;
        }
      }
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to the specific habit or today view
    // This will be implemented when integrating with the router
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    // Android 13+ requires runtime permission
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted != true) return false;

      // Request exact alarm permission for Android 12+ (API 31+)
      // This is required for exact scheduling
      try {
        final exactAlarmGranted = await androidPlugin
            .requestExactAlarmsPermission();
        print('📱 Exact alarm permission: $exactAlarmGranted');
      } catch (e) {
        print('⚠️ Could not request exact alarm permission: $e');
        // Continue anyway - older Android versions don't need this
      }
    }

    // iOS permissions
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted != true) return false;
    }

    return true;
  }

  /// Check if permissions are granted
  Future<bool> arePermissionsGranted() async {
    if (!_initialized) await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.areNotificationsEnabled();
      return granted ?? false;
    }

    // For iOS, we assume granted if we reach here
    // (iOS will show system dialog on first request)
    return true;
  }

  /// Schedule a habit reminder
  Future<void> scheduleHabitReminder(HabitEntity habit) async {
    if (!_initialized) await initialize();
    if (!habit.reminderEnabled || habit.reminderTime == null) return;

    print('📱 DEBUG: Scheduling for Habit: "${habit.name}" (ID: ${habit.id})');
    print('   Time: ${habit.reminderTime}, Days: ${habit.reminderDays}');
    print('   Enabled: ${habit.reminderEnabled}');

    // Cancel existing notifications for this habit
    await cancelHabitReminder(habit.id);

    final time = habit.reminderTime!;
    final days =
        habit.reminderDays ?? [0, 1, 2, 3, 4, 5, 6]; // Default to all days

    // Schedule notification for each selected day
    for (final day in days) {
      final notificationId = _getNotificationId(habit.id, day);
      final scheduledDate = _nextInstanceOfDayAndTime(day, time);

      print('   📅 Day: $day, NotifID: $notificationId, Date: $scheduledDate');

      try {
        await _notifications.zonedSchedule(
          id: notificationId,
          title: _getNotificationTitle(habit),
          body: _getNotificationBody(habit),
          scheduledDate: scheduledDate,
          notificationDetails: _notificationDetails(habit),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: habit.id,
        );
        print('   ✅ Scheduled successfully (ID: $notificationId)');
      } catch (e, stack) {
        print('   ❌ Failed to schedule (ID: $notificationId): $e');
        print('   Stack: $stack');
      }
    }

    // Verify scheduled notifications
    final pending = await _notifications.pendingNotificationRequests();
    print('   ✅ Total pending notifications: ${pending.length}');
    for (final p in pending) {
      print('      - ID: ${p.id}, Title: ${p.title}');
    }
  }

  /// Cancel habit reminder
  Future<void> cancelHabitReminder(String habitId) async {
    if (!_initialized) await initialize();

    // Cancel all possible day notifications for this habit
    for (int day = 0; day < 7; day++) {
      final notificationId = _getNotificationId(habitId, day);
      await _notifications.cancel(id: notificationId);
    }
  }

  /// Reschedule all reminders (useful after app restart)
  Future<void> rescheduleAllReminders(List<HabitEntity> habits) async {
    if (!_initialized) await initialize();

    // Cancel all existing notifications
    await _notifications.cancelAll();

    // Schedule reminders for all habits with reminders enabled
    for (final habit in habits) {
      if (habit.reminderEnabled && habit.reminderTime != null) {
        await scheduleHabitReminder(habit);
      }
    }
  }

  /// Show completion notification
  Future<void> showCompletionNotification(HabitEntity habit) async {
    if (!_initialized) await initialize();

    const notificationId = 999999; // Special ID for completion notifications

    await _notifications.show(
      id: notificationId,
      title: '🎉 Great job!',
      body: 'You completed "${habit.name}"! Keep up the streak! 🔥',
      notificationDetails: _notificationDetails(habit),
      payload: habit.id,
    );
  }

  /// Show a test notification immediately (for debugging)
  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    print('🧪 Showing test notification...');

    await _notifications.show(
      id: 12345,
      title: '🧪 Test Notification',
      body:
          'If you see this, notifications are working! Time: ${DateTime.now()}',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders_v2',
          'Habit Reminders',
          channelDescription: 'Notifications to remind you about your habits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    print('✅ Test notification sent!');
  }

  /// Get notification details
  NotificationDetails _notificationDetails(HabitEntity habit) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_reminders_v2',
        'Habit Reminders',
        channelDescription: 'Notifications to remind you about your habits',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Get notification title based on habit
  String _getNotificationTitle(HabitEntity habit) {
    return 'Time for ${habit.name}! 🎯';
  }

  /// Get notification body based on streak
  String _getNotificationBody(HabitEntity habit) {
    if (habit.currentStreak == 0) {
      return habit.description.isNotEmpty
          ? habit.description
          : 'Start your streak today!';
    } else if (habit.currentStreak >= 7) {
      return 'Don\'t break your ${habit.currentStreak}-day streak! 🔥';
    } else {
      return 'Keep your streak alive! 🔥';
    }
  }

  /// Generate unique notification ID from habit ID and day
  int _getNotificationId(String habitId, int day) {
    // Use hash code of habit ID combined with day to create unique ID
    final hashCode = habitId.hashCode;
    // Ensure positive integer and add day offset
    return (hashCode.abs() % 1000000) * 10 + day;
  }

  /// Calculate next instance of a specific day and time
  /// day: 0-6 where 0=Sunday, 6=Saturday
  tz.TZDateTime _nextInstanceOfDayAndTime(int day, DateTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Convert our day format (0=Sunday) to Dart's weekday format (1=Monday, 7=Sunday)
    // Our format: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
    // Dart format: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
    final targetDartWeekday = day == 0 ? 7 : day;

    // Adjust to the target day of week
    while (scheduledDate.weekday != targetDartWeekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the scheduled time has passed today, schedule for next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    if (!_initialized) await initialize();
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }
}
