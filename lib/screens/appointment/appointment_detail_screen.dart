import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/appointment_service.dart';
import '../../services/appointment_notification_service.dart';
import 'add_appointment_screen.dart';
import 'appointment_preparation_screen.dart';

/// Appointment Detail Screen - Shows full appointment details and actions
class AppointmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final AppointmentNotificationService _notificationService =
      AppointmentNotificationService();

  late Map<String, dynamic> _appointment;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history =
        await _appointmentService.getAppointmentHistory(_appointment['id']);
    setState(() => _history = history);
  }

  Future<void> _openInMaps() async {
    final location = _appointment['location'] as String?;
    if (location == null || location.isEmpty) {
      Get.snackbar(
        'No Location',
        'Location not specified for this appointment',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }

    // URL encode the location
    final query = Uri.encodeComponent(location);
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$query';

    try {
      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Could not open maps',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error opening maps: $e');
      Get.snackbar(
        'Error',
        'Failed to open maps',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _sendTestReminder() async {
    final doctorName = _appointment['doctor_name'] as String;
    final appointmentDate = DateTime.parse(_appointment['appointment_date']);
    final specialty = _appointment['specialty'] as String?;

    await _notificationService.showImmediateNotification(
      appointmentId: _appointment['id'],
      doctorName: doctorName,
      appointmentDate: appointmentDate,
      specialty: specialty,
    );

    Get.snackbar(
      'Test Sent!',
      'Check your notifications',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  Future<void> _cancelAppointment() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text(
            'Are you sure you want to cancel this appointment? Reminders will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final success =
          await _appointmentService.cancelAppointment(_appointment['id']);

      if (success) {
        // Cancel notifications
        await _notificationService
            .cancelAppointmentReminders(_appointment['id']);

        Get.snackbar(
          'Cancelled',
          'Appointment cancelled successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        Get.back(result: true);
      } else {
        Get.snackbar(
          'Error',
          'Failed to cancel appointment',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsCompleted() async {
    setState(() => _isLoading = true);

    final success =
        await _appointmentService.markAsCompleted(_appointment['id']);

    if (success) {
      Get.snackbar(
        'Completed',
        'Appointment marked as completed',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
      Get.back(result: true);
    } else {
      Get.snackbar(
        'Error',
        'Failed to update appointment',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteAppointment() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Appointment?'),
        content: const Text(
            'Are you sure you want to delete this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final success =
          await _appointmentService.deleteAppointment(_appointment['id']);

      if (success) {
        // Cancel notifications
        await _notificationService
            .cancelAppointmentReminders(_appointment['id']);

        Get.snackbar(
          'Deleted',
          'Appointment deleted successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        Get.back(result: true);
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete appointment',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentDate = DateTime.parse(_appointment['appointment_date']);
    final doctorName = _appointment['doctor_name'] as String;
    final specialty = _appointment['specialty'] as String?;
    final location = _appointment['location'] as String?;
    final reason = _appointment['reason_for_visit'] as String?;
    final visitType = _appointment['visit_type'] as String;
    final status = _appointment['status'] as String;
    final notes = _appointment['notes'] as String?;
    final durationMinutes = _appointment['duration_minutes'] as int? ?? 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Get.to(
                () => AddAppointmentScreen(existingAppointment: _appointment),
              );
              if (result == true) {
                Get.back(result: true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteAppointment,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Doctor Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Icon(Icons.person,
                                  color: AppColors.primary, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctorName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (specialty != null)
                                    Text(
                                      specialty,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Status Card
                Card(
                  color: _getStatusColor(status).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(_getStatusIcon(status),
                            color: _getStatusColor(status)),
                        const SizedBox(width: 12),
                        Text(
                          'Status: ${status.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Appointment Details Card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.calendar_today, color: AppColors.primary),
                        title: const Text('Date & Time'),
                        subtitle: Text(
                          '${DateFormat('EEEE, MMMM d, yyyy').format(appointmentDate)}\n${DateFormat('h:mm a').format(appointmentDate)} ($durationMinutes min)',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(_getVisitTypeIcon(visitType),
                            color: AppColors.healthBlue),
                        title: const Text('Visit Type'),
                        subtitle: Text(_getVisitTypeLabel(visitType)),
                      ),
                      if (location != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.location_on, color: AppColors.error),
                          title: const Text('Location'),
                          subtitle: Text(location),
                          trailing: IconButton(
                            icon: const Icon(Icons.map),
                            onPressed: _openInMaps,
                            tooltip: 'Open in Maps',
                          ),
                        ),
                      ],
                      if (reason != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.notes, color: AppColors.warning),
                          title: const Text('Reason for Visit'),
                          subtitle: Text(reason),
                        ),
                      ],
                      if (notes != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.description,
                              color: AppColors.textSecondary),
                          title: const Text('Notes'),
                          subtitle: Text(notes),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Preparation Checklist Card
                Card(
                  child: ListTile(
                    leading: Icon(Icons.checklist, color: AppColors.healthBlue),
                    title: const Text('Preparation Checklist'),
                    subtitle: const Text('Questions, symptoms, medications to discuss'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Get.to(() => AppointmentPreparationScreen(
                            appointment: _appointment,
                          ));
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Reminder Settings Card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.notifications, color: AppColors.primary),
                        title: const Text('Reminder Settings'),
                        subtitle: Text(
                          '${_appointment['reminder_24h'] == true ? '✓ ' : ''}24-hour reminder\n${_appointment['reminder_1h'] == true ? '✓ ' : ''}1-hour reminder',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.notification_add, color: AppColors.success),
                        title: const Text('Test Reminder'),
                        subtitle: const Text('Send a test notification now'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _sendTestReminder,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                if (status == 'scheduled' || status == 'rescheduled') ...[
                  ElevatedButton.icon(
                    onPressed: _markAsCompleted,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cancelAppointment,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Appointment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // History Section
                if (_history.isNotEmpty) ...[
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final historyItem = _history[index];
                        final action = historyItem['action'] as String;
                        final createdAt =
                            DateTime.parse(historyItem['created_at']);

                        return ListTile(
                          leading: Icon(_getHistoryIcon(action),
                              color: AppColors.primary, size: 20),
                          title: Text(_getHistoryLabel(action)),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy • h:mm a').format(createdAt),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
      case 'rescheduled':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.textSecondary;
      case 'missed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
      case 'rescheduled':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'missed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  IconData _getVisitTypeIcon(String visitType) {
    switch (visitType) {
      case 'online':
        return Icons.video_call;
      case 'home-visit':
        return Icons.home;
      default:
        return Icons.local_hospital;
    }
  }

  String _getVisitTypeLabel(String visitType) {
    switch (visitType) {
      case 'online':
        return 'Online Consultation';
      case 'home-visit':
        return 'Home Visit';
      default:
        return 'In-Person Visit';
    }
  }

  IconData _getHistoryIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle;
      case 'updated':
        return Icons.edit;
      case 'rescheduled':
        return Icons.update;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.history;
    }
  }

  String _getHistoryLabel(String action) {
    switch (action) {
      case 'created':
        return 'Appointment created';
      case 'updated':
        return 'Appointment updated';
      case 'rescheduled':
        return 'Appointment rescheduled';
      case 'completed':
        return 'Marked as completed';
      case 'cancelled':
        return 'Appointment cancelled';
      default:
        return action;
    }
  }
}
