import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'medication_service.dart';

/// Service for managing medication reminders and notifications
class MedicationNotificationService {
  static final MedicationNotificationService _instance = MedicationNotificationService._internal();
  factory MedicationNotificationService() => _instance;
  MedicationNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final MedicationService _medicationService = MedicationService();

  /// Initialize notification service
  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate to medication detail screen
      // Format: "medicationId|reminderId|action"
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final medicationId = parts[0];
        final reminderId = parts[1];
        // Navigate or handle action
        print('Notification tapped: Medication $medicationId, Reminder $reminderId');
      }
    }
  }

  /// Schedule daily reminder at specific time with smart context-aware messages
  Future<void> scheduleDailyReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required int hour,
    required int minute,
    String? instructions,
    String? form,
    String? timing,
    bool takeWithFood = false,
    bool takeOnEmptyStomach = false,
    bool takeBeforeMeal = false,
    bool takeAfterMeal = false,
  }) async {
    final notificationId = medicationId.hashCode + hour * 100 + minute;

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    // Build smart notification message
    final message = _buildSmartNotificationMessage(
      dosage: dosage,
      form: form,
      timing: timing,
      instructions: instructions,
      takeWithFood: takeWithFood,
      takeOnEmptyStomach: takeOnEmptyStomach,
      takeBeforeMeal: takeBeforeMeal,
      takeAfterMeal: takeAfterMeal,
    );

    // Get action label based on form
    final actionLabel = _getActionLabel(form);

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      actions: [
        AndroidNotificationAction(
          'taken',
          'Mark as Taken',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'skip',
          'Skip',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze 10min',
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '💊 Time to $actionLabel $medicationName',
      message,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$medicationId|$notificationId|daily',
    );

    print('Scheduled daily reminder for $medicationName at ${hour}:${minute}');
  }

  /// Schedule interval-based reminder (e.g., every 8 hours)
  Future<void> scheduleIntervalReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required int intervalHours,
    String? instructions,
  }) async {
    // Schedule 3 reminders per day based on interval
    final reminderTimes = _calculateIntervalTimes(intervalHours);

    for (var i = 0; i < reminderTimes.length; i++) {
      final time = reminderTimes[i];
      await scheduleDailyReminder(
        medicationId: '$medicationId-interval-$i',
        medicationName: medicationName,
        dosage: dosage,
        hour: time['hour']!,
        minute: time['minute']!,
        instructions: instructions,
      );
    }
  }

  /// Schedule reminder for specific days of week
  Future<void> scheduleWeeklyReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required List<int> days, // 1=Monday, 7=Sunday
    required int hour,
    required int minute,
    String? instructions,
  }) async {
    for (var day in days) {
      final notificationId = medicationId.hashCode + day * 1000 + hour * 100 + minute;

      final scheduledDate = _nextInstanceOfWeekday(day, hour, minute);

      const androidDetails = AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Reminders to take your medications',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction('taken', 'Mark as Taken'),
          AndroidNotificationAction('skip', 'Skip'),
          AndroidNotificationAction('snooze', 'Snooze 10min'),
        ],
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        '💊 Time to take $medicationName',
        '${dosage}${instructions != null ? ' • $instructions' : ''}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '$medicationId|$notificationId|weekly',
      );
    }
  }

  /// Schedule one-time reminder
  Future<void> scheduleOneTimeReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? instructions,
  }) async {
    final notificationId = medicationId.hashCode + scheduledTime.millisecondsSinceEpoch ~/ 1000;

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medications',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('taken', 'Mark as Taken'),
        AndroidNotificationAction('skip', 'Skip'),
      ],
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '💊 Time to take $medicationName',
      '${dosage}${instructions != null ? ' • $instructions' : ''}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$medicationId|$notificationId|onetime',
    );
  }

  /// Snooze reminder (reschedule after 10 minutes)
  Future<void> snoozeReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    int snoozeMinutes = 10,
  }) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));

    await scheduleOneTimeReminder(
      medicationId: '$medicationId-snooze',
      medicationName: medicationName,
      dosage: dosage,
      scheduledTime: snoozeTime,
      instructions: 'Snoozed reminder',
    );
  }

  /// Cancel all reminders for a medication
  Future<void> cancelMedicationReminders(String medicationId) async {
    // Cancel all possible notification IDs for this medication
    // This is a simplified approach - in production, store notification IDs in database
    for (var i = 0; i < 100; i++) {
      final notificationId = medicationId.hashCode + i;
      await _notifications.cancel(notificationId);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Helper: Calculate next instance of time today or tomorrow
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Helper: Calculate next instance of weekday
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Helper: Calculate reminder times based on interval
  List<Map<String, int>> _calculateIntervalTimes(int intervalHours) {
    final times = <Map<String, int>>[];
    final reminderCount = (24 / intervalHours).floor();

    for (var i = 0; i < reminderCount; i++) {
      final hour = (i * intervalHours) % 24;
      times.add({'hour': hour, 'minute': 0});
    }

    return times;
  }

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String medicationName,
    required String dosage,
    String? instructions,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medications',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('taken', 'Mark as Taken'),
        AndroidNotificationAction('skip', 'Skip'),
        AndroidNotificationAction('snooze', 'Snooze 10min'),
      ],
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '💊 Time to take $medicationName',
      '${dosage}${instructions != null ? ' • $instructions' : ''}',
      details,
    );
  }

  /// Build smart, context-aware notification message
  String _buildSmartNotificationMessage({
    required String dosage,
    String? form,
    String? timing,
    String? instructions,
    bool takeWithFood = false,
    bool takeOnEmptyStomach = false,
    bool takeBeforeMeal = false,
    bool takeAfterMeal = false,
  }) {
    final parts = <String>[];

    // Add dosage
    parts.add(dosage);

    // Add food timing instruction
    String? foodInstruction = _getFoodTimingInstruction(
      form: form,
      timing: timing,
      takeWithFood: takeWithFood,
      takeOnEmptyStomach: takeOnEmptyStomach,
      takeBeforeMeal: takeBeforeMeal,
      takeAfterMeal: takeAfterMeal,
    );

    if (foodInstruction != null) {
      parts.add(foodInstruction);
    }

    // Add custom instructions if provided
    if (instructions != null && instructions.isNotEmpty) {
      parts.add(instructions);
    }

    return parts.join(' • ');
  }

  /// Get food timing instruction based on medication properties
  String? _getFoodTimingInstruction({
    String? form,
    String? timing,
    bool takeWithFood = false,
    bool takeOnEmptyStomach = false,
    bool takeBeforeMeal = false,
    bool takeAfterMeal = false,
  }) {
    // For topical applications (cream, ointment)
    if (form != null && (form.toLowerCase() == 'cream' || form.toLowerCase() == 'ointment')) {
      String instruction = 'Apply on affected area';
      if (timing != null && timing.toLowerCase() == 'night') {
        instruction += ' after bath/shower';
      }
      return instruction;
    }

    // For drops
    if (form != null && form.toLowerCase() == 'drops') {
      if (form.toLowerCase().contains('eye')) {
        return 'Apply to eyes as directed';
      } else if (form.toLowerCase().contains('ear')) {
        return 'Apply to ears as directed';
      }
      return 'Use as directed';
    }

    // For inhalers
    if (form != null && form.toLowerCase() == 'inhaler') {
      return 'Use inhaler as directed';
    }

    // For oral medications (tablet, capsule, syrup, liquid)
    if (takeOnEmptyStomach) {
      String instruction = '⚠️ Take with EMPTY STOMACH';
      if (timing != null && timing.toLowerCase() == 'morning') {
        instruction += ' (before breakfast)';
      }
      instruction += ' • Don\'t eat for 30 minutes after';
      return instruction;
    }

    if (takeBeforeMeal) {
      String mealName = _getMealNameFromTiming(timing);
      return '⚠️ Take BEFORE $mealName';
    }

    if (takeAfterMeal) {
      String mealName = _getMealNameFromTiming(timing);
      return '✓ Take AFTER eating $mealName';
    }

    if (takeWithFood) {
      String mealName = _getMealNameFromTiming(timing);
      return '✓ Take WITH $mealName';
    }

    return null;
  }

  /// Get meal name from timing
  String _getMealNameFromTiming(String? timing) {
    if (timing == null) return 'meal';

    switch (timing.toLowerCase()) {
      case 'morning':
        return 'breakfast';
      case 'afternoon':
        return 'lunch';
      case 'evening':
      case 'night':
        return 'dinner';
      case 'before-sleep':
        return 'dinner';
      default:
        return 'meal';
    }
  }

  /// Get action label based on medication form
  String _getActionLabel(String? form) {
    if (form == null) return 'take';

    switch (form.toLowerCase()) {
      case 'cream':
      case 'ointment':
        return 'apply';
      case 'drops':
        return 'use';
      case 'inhaler':
        return 'use';
      case 'injection':
        return 'take';
      default:
        return 'take';
    }
  }
}
