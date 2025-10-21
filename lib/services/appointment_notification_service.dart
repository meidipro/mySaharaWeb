import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Service for managing appointment notifications
class AppointmentNotificationService {
  static final AppointmentNotificationService _instance =
      AppointmentNotificationService._internal();

  factory AppointmentNotificationService() => _instance;

  AppointmentNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification service
  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
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

  /// Request notification permissions (Android 13+)
  Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
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
    print('Notification tapped: ${response.payload}');
    // You can navigate to appointment detail screen here
    // Parse payload to get appointment ID
    // Get.to(() => AppointmentDetailScreen(appointmentId: response.payload));
  }

  /// Schedule 24-hour reminder for appointment
  Future<void> schedule24HourReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentDate,
    String? specialty,
    String? location,
  }) async {
    try {
      final reminderTime = appointmentDate.subtract(const Duration(hours: 24));

      // Only schedule if reminder time is in the future
      if (reminderTime.isBefore(DateTime.now())) {
        print('24h reminder time is in the past, skipping');
        return;
      }

      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'appointment_reminders_24h',
        'Appointment Reminders (24h)',
        channelDescription: 'Reminders sent 24 hours before appointments',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
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

      final title = 'Appointment Tomorrow';
      final body = specialty != null
          ? 'You have an appointment with Dr. $doctorName ($specialty) tomorrow at ${_formatTime(appointmentDate)}'
          : 'You have an appointment with Dr. $doctorName tomorrow at ${_formatTime(appointmentDate)}';

      await _notifications.zonedSchedule(
        appointmentId.hashCode % 100000, // Use unique ID
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: appointmentId,
      );

      print('Scheduled 24h reminder for $doctorName at $reminderTime');
    } catch (e) {
      print('Error scheduling 24h reminder: $e');
    }
  }

  /// Schedule 1-hour reminder for appointment
  Future<void> schedule1HourReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentDate,
    String? specialty,
    String? location,
  }) async {
    try {
      final reminderTime = appointmentDate.subtract(const Duration(hours: 1));

      // Only schedule if reminder time is in the future
      if (reminderTime.isBefore(DateTime.now())) {
        print('1h reminder time is in the past, skipping');
        return;
      }

      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'appointment_reminders_1h',
        'Appointment Reminders (1h)',
        channelDescription: 'Reminders sent 1 hour before appointments',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
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

      final title = 'Appointment in 1 Hour';
      final body = location != null
          ? 'Appointment with Dr. $doctorName at ${_formatTime(appointmentDate)} - Location: $location'
          : 'Appointment with Dr. $doctorName at ${_formatTime(appointmentDate)}';

      await _notifications.zonedSchedule(
        (appointmentId.hashCode % 100000) + 1, // Use unique ID (offset by 1)
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: appointmentId,
      );

      print('Scheduled 1h reminder for $doctorName at $reminderTime');
    } catch (e) {
      print('Error scheduling 1h reminder: $e');
    }
  }

  /// Schedule custom reminder
  Future<void> scheduleCustomReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime reminderTime,
    String? customMessage,
  }) async {
    try {
      // Only schedule if reminder time is in the future
      if (reminderTime.isBefore(DateTime.now())) {
        print('Custom reminder time is in the past, skipping');
        return;
      }

      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'appointment_reminders_custom',
        'Custom Appointment Reminders',
        channelDescription: 'Custom reminders for appointments',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
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

      final title = 'Appointment Reminder';
      final body = customMessage ??
          'Don\'t forget your appointment with Dr. $doctorName';

      await _notifications.zonedSchedule(
        (appointmentId.hashCode % 100000) + 2, // Use unique ID (offset by 2)
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: appointmentId,
      );

      print('Scheduled custom reminder for $doctorName at $reminderTime');
    } catch (e) {
      print('Error scheduling custom reminder: $e');
    }
  }

  /// Send immediate notification (for testing or urgent reminders)
  Future<void> showImmediateNotification({
    required String appointmentId,
    required String doctorName,
    required DateTime appointmentDate,
    String? specialty,
    String? location,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'appointment_immediate',
        'Immediate Appointment Notifications',
        channelDescription: 'Immediate appointment reminders',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
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

      final title = 'Appointment Reminder';
      final body = specialty != null
          ? 'Appointment with Dr. $doctorName ($specialty) on ${_formatDate(appointmentDate)} at ${_formatTime(appointmentDate)}'
          : 'Appointment with Dr. $doctorName on ${_formatDate(appointmentDate)} at ${_formatTime(appointmentDate)}';

      await _notifications.show(
        appointmentId.hashCode % 100000,
        title,
        body,
        details,
        payload: appointmentId,
      );

      print('Showed immediate notification for $doctorName');
    } catch (e) {
      print('Error showing immediate notification: $e');
    }
  }

  /// Cancel all reminders for an appointment
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    try {
      final baseId = appointmentId.hashCode % 100000;

      // Cancel 24h reminder
      await _notifications.cancel(baseId);

      // Cancel 1h reminder
      await _notifications.cancel(baseId + 1);

      // Cancel custom reminder
      await _notifications.cancel(baseId + 2);

      print('Cancelled all reminders for appointment: $appointmentId');
    } catch (e) {
      print('Error cancelling reminders: $e');
    }
  }

  /// Cancel all appointment notifications
  Future<void> cancelAllAppointmentNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Cancelled all appointment notifications');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      print('Error getting pending notifications: $e');
      return 0;
    }
  }

  /// Helper: Format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Helper: Format date
  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}
