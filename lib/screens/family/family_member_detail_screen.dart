import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/family_member.dart';
import '../../models/medical_history.dart';
import '../../models/medical_document.dart';
import '../../models/medication.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_timeline_provider.dart';
import '../../providers/health_record_provider.dart';
import '../../services/medication_service.dart';
import '../../services/appointment_service.dart';
import 'add_family_member_screen.dart';
import '../timeline/add_medical_event_screen.dart';
import '../health_records/add_health_record_screen.dart';
import '../health_records/health_record_detail_screen.dart';
import '../medication/add_medication_screen_simple.dart';
import '../appointment/add_appointment_screen.dart';

class FamilyMemberDetailScreen extends StatefulWidget {
  final String memberId;
  final FamilyMemberWithProfile? memberProfile;

  const FamilyMemberDetailScreen({
    super.key,
    required this.memberId,
    this.memberProfile,
  });

  @override
  State<FamilyMemberDetailScreen> createState() => _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState extends State<FamilyMemberDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MedicationService _medicationService = MedicationService();
  final AppointmentService _appointmentService = AppointmentService();

  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoadingMedications = false;
  bool _isLoadingAppointments = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB
    });
    _loadFamilyMemberData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyMemberData() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      // Load medical history for this family member
      final timelineProvider = context.read<MedicalTimelineProvider>();
      await timelineProvider.loadMedicalHistory(
        userId: authProvider.user!.id,
        familyMemberId: widget.memberId,
      );

      // Load documents for this family member
      final healthRecordProvider = context.read<HealthRecordProvider>();
      await healthRecordProvider.loadDocuments(
        userId: authProvider.user!.id,
        familyMemberId: widget.memberId,
      );

      // Load medications
      setState(() => _isLoadingMedications = true);
      final allMedications = await _medicationService.getMedications(authProvider.user!.id);
      setState(() {
        _medications = allMedications.where((m) => m['family_member_id'] == widget.memberId).toList();
        _isLoadingMedications = false;
      });

      // Load appointments
      setState(() => _isLoadingAppointments = true);
      final allAppointments = await _appointmentService.getAppointments(authProvider.user!.id);
      setState(() {
        _appointments = allAppointments.where((a) => a['family_member_id'] == widget.memberId).toList();
        _isLoadingAppointments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.memberProfile?.member;
    final isLinked = member?.linkedUserId != null && member!.linkedUserId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(member?.fullName ?? 'Family Member'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (member != null) {
                Get.to(() => AddFamilyMemberScreen(member: member));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.textWhite,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.timeline), text: 'History'),
            Tab(icon: Icon(Icons.folder), text: 'Documents'),
            Tab(icon: Icon(Icons.medication), text: 'Medications'),
            Tab(icon: Icon(Icons.event), text: 'Appointments'),
          ],
        ),
      ),
      body: member == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(member, isLinked),
                _buildHistoryTab(member),
                _buildDocumentsTab(member),
                _buildMedicationsTab(member),
                _buildAppointmentsTab(member),
              ],
            ),
      floatingActionButton: member != null && _tabController.index > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                switch (_tabController.index) {
                  case 1: // History
                    _addMedicalHistory(member);
                    break;
                  case 2: // Documents
                    _uploadDocument(member);
                    break;
                  case 3: // Medications
                    _addMedication(member);
                    break;
                  case 4: // Appointments
                    _addAppointment(member);
                    break;
                }
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: Text(_getTabActionLabel()),
            )
          : null,
    );
  }

  String _getTabActionLabel() {
    switch (_tabController.index) {
      case 1:
        return 'Add Event';
      case 2:
        return 'Upload Doc';
      case 3:
        return 'Add Medication';
      case 4:
        return 'Add Appointment';
      default:
        return 'Add';
    }
  }

  // TAB 1: Overview
  Widget _buildOverviewTab(FamilyMember member, bool isLinked) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          _buildHeaderCard(context, member, isLinked),

          // Quick Stats
          _buildQuickStats(member),

          // Basic Information
          _buildSection(
            context,
            title: 'Basic Information',
            children: [
              if (member.dateOfBirth != null)
                _buildInfoTile(
                  context,
                  icon: Icons.cake,
                  label: 'Date of Birth',
                  value: DateFormat('MMM dd, yyyy')
                      .format(DateTime.parse(member.dateOfBirth!)),
                ),
              if (member.gender != null)
                _buildInfoTile(
                  context,
                  icon: Icons.wc,
                  label: 'Gender',
                  value: member.gender!,
                ),
              if (member.bloodGroup != null)
                _buildInfoTile(
                  context,
                  icon: Icons.bloodtype,
                  label: 'Blood Group',
                  value: member.bloodGroup!,
                ),
              _buildInfoTile(
                context,
                icon: Icons.family_restroom,
                label: 'Relationship',
                value: member.relationship,
              ),
              if (widget.memberProfile?.email != null)
                _buildInfoTile(
                  context,
                  icon: Icons.email,
                  label: 'Email',
                  value: widget.memberProfile!.email!,
                ),
            ],
          ),

          // Medical Information Summary
          if (member.chronicDiseases != null ||
              member.medications != null ||
              member.allergies != null)
            _buildSection(
              context,
              title: 'Medical Information Summary',
              children: [
                if (member.chronicDiseases != null)
                  _buildInfoTile(
                    context,
                    icon: Icons.medical_services,
                    label: 'Diseases',
                    value: member.chronicDiseases!,
                    isMultiline: true,
                  ),
                if (member.medications != null)
                  _buildInfoTile(
                    context,
                    icon: Icons.medication,
                    label: 'Current Medications',
                    value: member.medications!,
                    isMultiline: true,
                  ),
                if (member.allergies != null)
                  _buildInfoTile(
                    context,
                    icon: Icons.warning_amber,
                    label: 'Allergies',
                    value: member.allergies!,
                    isMultiline: true,
                    color: AppColors.error,
                  ),
              ],
            ),

          // Notes
          if (member.notes != null)
            _buildSection(
              context,
              title: 'Additional Notes',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    member.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // TAB 2: Medical History
  Widget _buildHistoryTab(FamilyMember member) {
    return Consumer<MedicalTimelineProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter medical history for this family member
        final memberHistory = provider.medicalHistory
            .where((h) => h.familyMemberId == widget.memberId)
            .toList();

        if (memberHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timeline, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No medical history yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add medical events to track their health timeline',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _addMedicalHistory(member),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Medical Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: memberHistory.length,
          itemBuilder: (context, index) {
            final event = memberHistory[index];
            return _buildMedicalHistoryCard(event);
          },
        );
      },
    );
  }

  // TAB 3: Documents
  Widget _buildDocumentsTab(FamilyMember member) {
    return Consumer<HealthRecordProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter documents for this family member
        final memberDocs = provider.documents
            .where((d) => d.familyMemberId == widget.memberId)
            .toList();

        if (memberDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No documents yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload medical documents and records',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _uploadDocument(member),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: memberDocs.length,
          itemBuilder: (context, index) {
            final doc = memberDocs[index];
            return _buildDocumentCard(doc);
          },
        );
      },
    );
  }

  // TAB 4: Medications
  Widget _buildMedicationsTab(FamilyMember member) {
    if (_isLoadingMedications) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No medications yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add medications to track their prescriptions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _addMedication(member),
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        return _buildMedicationCard(med);
      },
    );
  }

  // TAB 5: Appointments
  Widget _buildAppointmentsTab(FamilyMember member) {
    if (_isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No appointments yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule appointments to manage their healthcare',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _addAppointment(member),
              icon: const Icon(Icons.add),
              label: const Text('Add Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final apt = _appointments[index];
        return _buildAppointmentCard(apt);
      },
    );
  }

  Widget _buildQuickStats(FamilyMember member) {
    return Consumer2<MedicalTimelineProvider, HealthRecordProvider>(
      builder: (context, timelineProvider, healthRecordProvider, child) {
        final historyCount = timelineProvider.medicalHistory
            .where((h) => h.familyMemberId == widget.memberId)
            .length;
        final docCount = healthRecordProvider.documents
            .where((d) => d.familyMemberId == widget.memberId)
            .length;
        final medicationCount = _medications.length;
        final appointmentCount = _appointments.length;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.timeline,
                      label: 'History Events',
                      value: '$historyCount',
                      color: AppColors.healthGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.folder,
                      label: 'Documents',
                      value: '$docCount',
                      color: AppColors.healthBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.medication,
                      label: 'Medications',
                      value: '$medicationCount',
                      color: AppColors.healthOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.event,
                      label: 'Appointments',
                      value: '$appointmentCount',
                      color: AppColors.healthPurple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicalHistoryCard(MedicalHistory event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showMedicalHistoryDetails(event),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.medical_services, color: AppColors.primary),
        ),
        title: Text(
          event.disease ?? event.eventType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(DateFormat('MMM dd, yyyy').format(event.eventDate)),
            if (event.doctorName != null) ...[
              const SizedBox(height: 2),
              Text('Dr. ${event.doctorName}'),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final result = await Get.to(() => AddMedicalEventScreen(
              event: event,
              familyMemberId: widget.memberId,
              familyMemberName: widget.memberProfile?.member.fullName,
            ));
            if (result == true) _loadFamilyMemberData();
          },
        ),
      ),
    );
  }

  void _showMedicalHistoryDetails(MedicalHistory event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                event.disease ?? event.eventType,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Event Type', event.eventType),
              _buildDetailRow('Date', DateFormat('MMMM dd, yyyy').format(event.eventDate)),
              if (event.disease != null) _buildDetailRow('Disease/Condition', event.disease!),
              if (event.symptoms != null) _buildDetailRow('Symptoms', event.symptoms!),
              if (event.doctorName != null) _buildDetailRow('Doctor', 'Dr. ${event.doctorName}'),
              if (event.doctorSpecialty != null) _buildDetailRow('Specialty', event.doctorSpecialty!),
              if (event.hospital != null) _buildDetailRow('Hospital', event.hospital!),
              if (event.treatment != null) _buildDetailRow('Treatment', event.treatment!),
              if (event.medications != null) _buildDetailRow('Medications', event.medications!),
              if (event.notes != null) _buildDetailRow('Notes', event.notes!),

              // Attached Documents Section
              if (event.documentIds != null && event.documentIds!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Attached Documents (${event.documentIds!.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildAttachedDocumentsList(event.documentIds!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Get.to(() => AddMedicalEventScreen(
                event: event,
                familyMemberId: widget.memberId,
                familyMemberName: widget.memberProfile?.member.fullName,
              ));
              if (result == true) _loadFamilyMemberData();
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAttachedDocumentsList(List<String> documentIds) {
    final healthRecordProvider = context.read<HealthRecordProvider>();
    final documents = healthRecordProvider.documents
        .where((doc) => documentIds.contains(doc.id))
        .toList();

    if (documents.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Documents not found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    return documents.map((doc) {
      return InkWell(
        onTap: () => _viewDocument(doc),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Document thumbnail/icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getDocumentIcon(doc.documentType),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc.documentType,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _viewDocument(MedicalDocument document) {
    Get.to(() => HealthRecordDetailScreen(document: document));
  }

  Widget _buildDocumentCard(MedicalDocument doc) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _viewDocument(doc),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: AppColors.healthBlue.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    _getDocumentIcon(doc.documentType),
                    size: 48,
                    color: AppColors.healthBlue,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(doc.documentDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return Icons.medication;
      case 'testreport':
      case 'test_report':
        return Icons.science;
      case 'xrayreport':
      case 'xray_report':
        return Icons.medical_services;
      default:
        return Icons.description;
    }
  }

  Widget _buildHeaderCard(BuildContext context, FamilyMember member, bool isLinked) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.textWhite.withOpacity(0.2),
            backgroundImage: member.profileImageUrl != null
                ? NetworkImage(member.profileImageUrl!)
                : null,
            child: member.profileImageUrl == null
                ? Text(
                    member.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            member.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.textWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              member.relationship,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isLinked) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.link, size: 16, color: AppColors.textWhite),
                  SizedBox(width: 4),
                  Text(
                    'Linked Account',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
      isThreeLine: isMultiline,
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _addMedicalHistory(FamilyMember member) async {
    final result = await Get.to(() => AddMedicalEventScreen(
      familyMemberId: widget.memberId,
      familyMemberName: member.fullName,
    ));

    if (result == true) {
      // Reload medical history
      _loadFamilyMemberData();
    }
  }

  void _uploadDocument(FamilyMember member) async {
    final result = await Get.to(() => AddHealthRecordScreen(
      familyMemberId: widget.memberId,
      familyMemberName: member.fullName,
    ));

    if (result == true) {
      // Reload documents
      _loadFamilyMemberData();
    }
  }

  void _addMedication(FamilyMember member) async {
    final result = await Get.to(() => AddMedicationScreenSimple(
      familyMemberId: widget.memberId,
      familyMemberName: member.fullName,
    ));

    if (result == true) {
      // Reload data
      _loadFamilyMemberData();
    }
  }

  void _addAppointment(FamilyMember member) async {
    final result = await Get.to(() => AddAppointmentScreen(
      familyMemberId: widget.memberId,
      familyMemberName: member.fullName,
    ));

    if (result == true) {
      // Reload data
      _loadFamilyMemberData();
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family Member'),
        content: Text(
          'Are you sure you want to delete ${widget.memberProfile?.member.fullName ?? 'this family member'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              final familyProvider = context.read<FamilyProvider>();
              final success = await familyProvider.deleteFamilyMember(widget.memberId);

              Get.back(); // Close loading

              if (success) {
                Get.back(); // Close detail screen
                Get.snackbar(
                  'Deleted',
                  'Family member deleted successfully',
                  backgroundColor: AppColors.success,
                  colorText: AppColors.textWhite,
                  snackPosition: SnackPosition.BOTTOM,
                );
                familyProvider.loadFamilyMembersWithProfile();
              } else {
                Get.snackbar(
                  'Error',
                  familyProvider.errorMessage ?? 'Failed to delete family member',
                  backgroundColor: AppColors.error,
                  colorText: AppColors.textWhite,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> med) {
    final isOngoing = med['is_ongoing'] ?? true;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.healthOrange.withOpacity(0.1),
          child: const Icon(Icons.medication, color: AppColors.healthOrange),
        ),
        title: Text(
          med['name'] ?? 'Medication',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${med['dosage_amount']} ${med['dosage_unit']} - ${med['form']}'),
            if (!isOngoing && med['end_date'] != null) ...[
              const SizedBox(height: 2),
              Text('Until ${DateFormat('MMM dd, yyyy').format(DateTime.parse(med['end_date']))}'),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOngoing ? AppColors.success.withOpacity(0.1) : AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isOngoing ? 'Ongoing' : 'Completed',
            style: TextStyle(
              fontSize: 12,
              color: isOngoing ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt) {
    final aptDate = DateTime.parse(apt['appointment_date']);
    final isPast = aptDate.isBefore(DateTime.now());
    final status = apt['status'] ?? 'scheduled';

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      case 'missed':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.healthPurple;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.event, color: statusColor),
        ),
        title: Text(
          apt['doctor_name'] ?? 'Appointment',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(DateFormat('MMM dd, yyyy - hh:mm a').format(aptDate)),
            if (apt['specialty'] != null) ...[
              const SizedBox(height: 2),
              Text(apt['specialty']),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.substring(0, 1).toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
