import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/medical_history.dart';
import '../../models/family_member.dart';
import '../../providers/medical_timeline_provider.dart';
import '../../providers/family_provider.dart';
import 'qr_code_display_screen.dart';

class SelectHistoryToShareScreen extends StatefulWidget {
  const SelectHistoryToShareScreen({super.key});

  @override
  State<SelectHistoryToShareScreen> createState() =>
      _SelectHistoryToShareScreenState();
}

class _SelectHistoryToShareScreenState
    extends State<SelectHistoryToShareScreen> {
  final Set<String> _selectedHistoryIds = {};
  bool _isGenerating = false;
  String? _selectedFamilyMemberId; // null means "Self"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicalTimelineProvider>().loadTimelineEvents();
      context.read<FamilyProvider>().loadFamilyMembers();
    });
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'diagnosis':
        return AppColors.healthRed;
      case 'treatment':
        return AppColors.healthGreen;
      case 'surgery':
        return AppColors.healthOrange;
      case 'consultation':
        return AppColors.healthBlue;
      case 'emergency':
        return AppColors.error;
      case 'checkup':
        return AppColors.success;
      case 'vaccination':
        return AppColors.healthPurple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'diagnosis':
        return Icons.medical_services;
      case 'treatment':
        return Icons.healing;
      case 'surgery':
        return Icons.cut;
      case 'consultation':
        return Icons.chat;
      case 'emergency':
        return Icons.emergency;
      case 'checkup':
        return Icons.check_circle;
      case 'vaccination':
        return Icons.vaccines;
      default:
        return Icons.event;
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedHistoryIds.contains(id)) {
        _selectedHistoryIds.remove(id);
      } else {
        _selectedHistoryIds.add(id);
      }
    });
  }

  void _selectAll(List<MedicalHistory> histories) {
    setState(() {
      _selectedHistoryIds.clear();
      _selectedHistoryIds.addAll(histories.map((h) => h.id!));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedHistoryIds.clear();
    });
  }

  Future<void> _generateQRCode() async {
    if (_selectedHistoryIds.isEmpty) {
      Get.snackbar(
        'No Selection',
        'Please select at least one medical history to share',
        backgroundColor: AppColors.warning,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Navigate to QR code display screen with selected IDs
      await Get.to(() => QRCodeDisplayScreen(
            medicalHistoryIds: _selectedHistoryIds.toList(),
          ));

      // Reset selection after returning
      setState(() {
        _selectedHistoryIds.clear();
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate QR code: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MedicalTimelineProvider, FamilyProvider>(
      builder: (context, timelineProvider, familyProvider, child) {
        // Filter histories based on selected family member
        final allHistories = timelineProvider.timelineEvents;
        final histories = allHistories.where((h) {
          if (_selectedFamilyMemberId == null) {
            // Show only user's own history (familyMemberId is null)
            return h.familyMemberId == null;
          } else {
            // Show selected family member's history
            return h.familyMemberId == _selectedFamilyMemberId;
          }
        }).toList();

        final familyMembers = familyProvider.familyMembers;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Select History to Share'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            actions: [
              if (histories.isNotEmpty)
                TextButton(
                  onPressed: _selectedHistoryIds.length == histories.length
                      ? _deselectAll
                      : () => _selectAll(histories),
                  child: Text(
                    _selectedHistoryIds.length == histories.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(color: AppColors.textWhite),
                  ),
                ),
            ],
          ),
          body: timelineProvider.isLoading || familyProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Family Member Selector
                    _buildFamilyMemberSelector(familyMembers),

                    // Selection counter
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: AppColors.primary.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedHistoryIds.isEmpty
                                  ? 'Select medical histories to share'
                                  : '${_selectedHistoryIds.length} ${_selectedHistoryIds.length == 1 ? 'history' : 'histories'} selected',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // List of medical histories
                    Expanded(
                      child: histories.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () =>
                                  timelineProvider.loadTimelineEvents(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: histories.length,
                                itemBuilder: (context, index) {
                                  final history = histories[index];
                                  final isSelected =
                                      _selectedHistoryIds.contains(history.id);
                                  return _buildHistoryCard(history, isSelected);
                                },
                              ),
                          ),
                        ),
                      ],
                    ),
          bottomNavigationBar: _selectedHistoryIds.isNotEmpty
              ? SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateQRCode,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.qr_code),
                      label: Text(
                        _isGenerating
                            ? 'Generating...'
                            : 'Generate QR Code',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHistoryCard(MedicalHistory history, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleSelection(history.id!),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Event icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getEventColor(history.eventType).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getEventIcon(history.eventType),
                  color: _getEventColor(history.eventType),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.disease ?? 'Medical Event',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            history.eventType,
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor:
                              _getEventColor(history.eventType).withOpacity(0.2),
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(history.eventDate),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                    if (history.doctorName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Dr. ${history.doctorName}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                    // Document count badge
                    if (history.documentIds != null &&
                        history.documentIds!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${history.documentIds!.length} ${history.documentIds!.length == 1 ? 'document' : 'documents'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyMemberSelector(List<FamilyMember> familyMembers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Whose medical history do you want to share?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Self option
                _buildMemberChip(
                  label: 'My History',
                  icon: Icons.person,
                  isSelected: _selectedFamilyMemberId == null,
                  onTap: () {
                    setState(() {
                      _selectedFamilyMemberId = null;
                      _selectedHistoryIds.clear();
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Family members
                ...familyMembers.map((member) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildMemberChip(
                      label: member.fullName,
                      icon: Icons.family_restroom,
                      isSelected: _selectedFamilyMemberId == member.id,
                      onTap: () {
                        setState(() {
                          _selectedFamilyMemberId = member.id;
                          _selectedHistoryIds.clear();
                        });
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No Medical History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFamilyMemberId == null
                ? 'Add medical events to your timeline first'
                : 'No medical history for this family member yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}
