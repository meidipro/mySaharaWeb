import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import 'add_appointment_screen.dart';
import 'appointment_detail_screen.dart';

/// Main Appointment Management Screen with list view and tabs
class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen> with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  late TabController _tabController;

  List<Map<String, dynamic>> _allAppointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    _filterAppointmentsByTab();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      final appointments = await _appointmentService.getAppointments(user.id);
      final stats = await _appointmentService.getAppointmentStats(user.id);

      setState(() {
        _allAppointments = appointments;
        _stats = stats;
        _isLoading = false;
      });

      _filterAppointmentsByTab();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _filterAppointmentsByTab() {
    final now = DateTime.now();

    setState(() {
      switch (_tabController.index) {
        case 0: // All
          _filteredAppointments = _allAppointments;
          break;
        case 1: // Upcoming
          _filteredAppointments = _allAppointments.where((a) {
            final date = DateTime.parse(a['appointment_date']);
            return date.isAfter(now) &&
                (a['status'] == 'scheduled' || a['status'] == 'rescheduled');
          }).toList();
          break;
        case 2: // Past
          _filteredAppointments = _allAppointments.where((a) {
            final date = DateTime.parse(a['appointment_date']);
            return date.isBefore(now);
          }).toList();
          break;
        case 3: // Completed
          _filteredAppointments = _allAppointments
              .where((a) => a['status'] == 'completed')
              .toList();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textWhite,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.7),
          tabs: [
            Tab(text: 'All (${_stats?['total'] ?? 0})'),
            Tab(text: 'Upcoming (${_stats?['upcoming'] ?? 0})'),
            Tab(text: 'Past'),
            Tab(text: 'Completed (${_stats?['completed'] ?? 0})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Card
                _buildStatsCard(),
                // List View
                Expanded(child: _buildListView()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to(() => const AddAppointmentScreen());
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Appointment'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Appointments Yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first appointment',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.healthBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Upcoming', _stats!['upcoming'], Icons.event),
          _buildStatItem('Completed', _stats!['completed'], Icons.check_circle),
          _buildStatItem('Cancelled', _stats!['cancelled'], Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    if (_filteredAppointments.isEmpty) {
      return Center(
        child: Text(
          'No appointments found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(_filteredAppointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final appointmentDate = DateTime.parse(appointment['appointment_date']);
    final status = appointment['status'] as String;
    final doctorName = appointment['doctor_name'] as String;
    final specialty = appointment['specialty'] as String?;
    final location = appointment['location'] as String?;
    final visitType = appointment['visit_type'] as String;

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Get.to(
            () => AppointmentDetailScreen(appointment: appointment),
          );
          if (result == true) _loadData();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (specialty != null)
                          Text(
                            specialty,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date and time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(appointmentDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('h:mm a').format(appointmentDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Visit type and location
              Row(
                children: [
                  Icon(_getVisitTypeIcon(visitType),
                      size: 16, color: AppColors.healthBlue),
                  const SizedBox(width: 8),
                  Text(
                    _getVisitTypeLabel(visitType),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              if (location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
        return 'In-Person';
    }
  }
}
