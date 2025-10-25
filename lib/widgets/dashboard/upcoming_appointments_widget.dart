import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import '../../screens/appointment/appointment_management_screen.dart';
import '../../screens/appointment/add_appointment_screen.dart';

/// Upcoming Appointments Widget - Shows next family appointments
class UpcomingAppointmentsWidget extends StatefulWidget {
  const UpcomingAppointmentsWidget({super.key});

  @override
  State<UpcomingAppointmentsWidget> createState() => _UpcomingAppointmentsWidgetState();
}

class _UpcomingAppointmentsWidgetState extends State<UpcomingAppointmentsWidget> {
  final AppointmentService _appointmentService = AppointmentService();
  List<Map<String, dynamic>> _upcomingAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingAppointments();
  }

  Future<void> _loadUpcomingAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId != null) {
        final appointments = await _appointmentService.getUpcomingAppointments(
          userId,
          daysAhead: 14, // Next 2 weeks
        );

        if (mounted) {
          setState(() {
            _upcomingAppointments = appointments.take(3).toList(); // Show up to 3
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.healthPurple.withOpacity(0.05),
              AppColors.healthPink.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.healthPurple.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.event_note,
                    color: AppColors.healthPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Upcoming Appointments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.to(() => const AppointmentManagementScreen()),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Appointments list
            if (_isLoading)
              _buildLoadingState()
            else if (_upcomingAppointments.isEmpty)
              _buildEmptyState()
            else
              _buildAppointmentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.healthPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.healthPurple.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.healthPurple.withOpacity(0.1),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: AppColors.healthPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Upcoming Appointments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule appointments for your family\nand never miss a checkup',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const AddAppointmentScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.healthPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Schedule Appointment',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return Column(
      children: [
        ..._upcomingAppointments.map((appt) => _buildAppointmentCard(appt)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Get.to(() => const AddAppointmentScreen()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.healthPurple,
              side: BorderSide(color: AppColors.healthPurple, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Schedule Appointment',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final doctorName = appointment['doctor_name'] as String? ?? 'Doctor';
    final appointmentType = appointment['appointment_type'] as String? ?? 'Checkup';
    final appointmentDateStr = appointment['appointment_date'] as String?;
    final appointmentTime = appointment['appointment_time'] as String?;
    final location = appointment['location'] as String?;

    DateTime? appointmentDate;
    if (appointmentDateStr != null) {
      try {
        appointmentDate = DateTime.parse(appointmentDateStr);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    final isToday = appointmentDate != null &&
        appointmentDate.year == DateTime.now().year &&
        appointmentDate.month == DateTime.now().month &&
        appointmentDate.day == DateTime.now().day;

    final isTomorrow = appointmentDate != null &&
        appointmentDate.difference(DateTime.now()).inDays == 0 &&
        appointmentDate.day == DateTime.now().add(const Duration(days: 1)).day;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.error.withOpacity(0.5)
              : AppColors.healthPurple.withOpacity(0.3),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 60,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.healthPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  appointmentDate != null
                      ? DateFormat('MMM').format(appointmentDate)
                      : '---',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday ? AppColors.error : AppColors.healthPurple,
                  ),
                ),
                Text(
                  appointmentDate != null
                      ? DateFormat('d').format(appointmentDate)
                      : '--',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isToday ? AppColors.error : AppColors.healthPurple,
                  ),
                ),
                if (appointmentTime != null)
                  Text(
                    appointmentTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: isToday ? AppColors.error : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Appointment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (isTomorrow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TOMORROW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Dr. $doctorName',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appointmentType,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Arrow icon
          Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
            size: 24,
          ),
        ],
      ),
    );
  }
}
