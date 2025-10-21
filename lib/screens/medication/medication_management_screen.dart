import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/medication_service.dart';
import 'add_medication_screen_simple.dart';
import 'add_vaccine_screen.dart';
import 'medication_detail_screen.dart';
import 'vaccine_management_screen.dart';

/// Main Medication Management Screen with tabs for Medications and Vaccines
class MedicationManagementScreen extends StatefulWidget {
  const MedicationManagementScreen({super.key});

  @override
  State<MedicationManagementScreen> createState() => _MedicationManagementScreenState();
}

class _MedicationManagementScreenState extends State<MedicationManagementScreen> with SingleTickerProviderStateMixin {
  final MedicationService _medicationService = MedicationService();
  late TabController _tabController;

  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _vaccines = [];
  bool _isLoading = true;
  Map<String, dynamic>? _adherenceStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      final medications = await _medicationService.getMedications(user.id);
      final vaccines = await _medicationService.getVaccines(user.id);
      final stats = await _medicationService.getAdherenceStats(userId: user.id);

      setState(() {
        _medications = medications;
        _vaccines = vaccines;
        _adherenceStats = stats;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textWhite,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Medications', icon: Icon(Icons.medication)),
            Tab(text: 'Vaccines', icon: Icon(Icons.vaccines)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicationsTab(),
          VaccineManagementScreen(vaccines: _vaccines, onRefresh: _loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_tabController.index == 0) {
            // Add medication
            final result = await Get.to(() => const AddMedicationScreenSimple());
            if (result == true) _loadData();
          } else {
            // Add vaccine
            final result = await Get.to(() => const AddVaccineScreen());
            if (result == true) _loadData();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Add Medication' : 'Add Vaccine'),
      ),
    );
  }

  Widget _buildMedicationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Adherence Stats Card
          if (_adherenceStats != null)
            SliverToBoxAdapter(
              child: _buildAdherenceCard(),
            ),

          // Medications List
          if (_medications.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final medication = _medications[index];
                    return _buildMedicationCard(medication);
                  },
                  childCount: _medications.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard() {
    final adherenceRate = (_adherenceStats!['adherence_rate'] as num?)?.toInt() ?? 0;
    final taken = (_adherenceStats!['taken'] as num?)?.toInt() ?? 0;
    final total = (_adherenceStats!['total'] as num?)?.toInt() ?? 0;

    Color getAdherenceColor() {
      if (adherenceRate >= 90) return AppColors.success;
      if (adherenceRate >= 70) return AppColors.healthOrange;
      return AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [getAdherenceColor().withOpacity(0.1), getAdherenceColor().withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: getAdherenceColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medication Adherence',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last 30 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: getAdherenceColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$adherenceRate%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: adherenceRate / 100,
              backgroundColor: Colors.grey.shade200,
              color: getAdherenceColor(),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Taken', taken.toString(), AppColors.success),
              _buildStatItem('Missed', ((_adherenceStats!['missed'] as num?)?.toInt() ?? 0).toString(), AppColors.error),
              _buildStatItem('Skipped', ((_adherenceStats!['skipped'] as num?)?.toInt() ?? 0).toString(), AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final name = medication['name'] as String;
    final dosageAmount = medication['dosage_amount'];
    final dosageUnit = medication['dosage_unit'] as String;
    final form = medication['form'] as String;
    final instructions = medication['instructions'] as String?;
    final remainingQty = (medication['quantity_remaining'] as num?)?.toInt();
    final totalQty = (medication['total_quantity'] as num?)?.toInt();

    // Check if running low
    final isLowStock = remainingQty != null && totalQty != null && remainingQty < (totalQty * 0.2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Get.to(() => MedicationDetailScreen(medication: medication));
          if (result == true) _loadData();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getMedicationIcon(form),
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
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dosageAmount $dosageUnit • $form',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            'Low Stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (instructions != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.healthBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.healthBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          instructions,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.healthBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (remainingQty != null && totalQty != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Stock: $remainingQty/$totalQty remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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

  IconData _getMedicationIcon(String form) {
    switch (form.toLowerCase()) {
      case 'tablet':
      case 'pill':
      case 'capsule':
        return Icons.medication;
      case 'syrup':
      case 'liquid':
        return Icons.local_drink;
      case 'injection':
        return Icons.vaccines;
      case 'inhaler':
        return Icons.air;
      case 'cream':
      case 'ointment':
        return Icons.healing;
      default:
        return Icons.medication;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Medications Yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first medication to start tracking',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Get.to(() => const AddMedicationScreenSimple());
              if (result == true) _loadData();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Medication'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
