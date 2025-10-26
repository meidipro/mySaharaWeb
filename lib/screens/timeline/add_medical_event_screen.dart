import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_colors.dart';
import '../../models/medical_history.dart';
import '../../models/medical_document.dart';
import '../../providers/medical_timeline_provider.dart';
import '../../providers/health_record_provider.dart';
import '../../providers/language_provider.dart';
import '../health_records/add_health_record_screen.dart';

/// Screen for adding new medical timeline events
class AddMedicalEventScreen extends StatefulWidget {
  final MedicalHistory? event; // For editing existing event
  final String? familyMemberId; // Optional: for family member's medical history
  final String? familyMemberName; // Optional: for display

  const AddMedicalEventScreen({
    super.key,
    this.event,
    this.familyMemberId,
    this.familyMemberName,
  });

  @override
  State<AddMedicalEventScreen> createState() => _AddMedicalEventScreenState();
}

class _AddMedicalEventScreenState extends State<AddMedicalEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diseaseController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorSpecialtyController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedEventType = 'consultation';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<String> _selectedDocumentIds = [];
  List<MedicalDocument> _attachedDocuments = [];

  final List<String> _eventTypes = [
    'consultation',
    'diagnosis',
    'treatment',
    'surgery',
    'emergency',
    'checkup',
    'vaccination',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _loadExistingEvent();
    }
  }

  void _loadExistingEvent() async {
    final event = widget.event!;
    _diseaseController.text = event.disease ?? '';
    _symptomsController.text = event.symptoms ?? '';
    _doctorNameController.text = event.doctorName ?? '';
    _doctorSpecialtyController.text = event.doctorSpecialty ?? '';
    _hospitalController.text = event.hospital ?? '';
    _treatmentController.text = event.treatment ?? '';
    _medicationsController.text = event.medications ?? '';
    _notesController.text = event.notes ?? '';
    _selectedEventType = event.eventType;
    _selectedDate = event.eventDate;

    // Load attached documents if any
    if (event.documentIds != null && event.documentIds!.isNotEmpty) {
      _selectedDocumentIds = List.from(event.documentIds!);
      // Load document details from HealthRecordProvider
      final healthRecordProvider = context.read<HealthRecordProvider>();
      _attachedDocuments = healthRecordProvider.healthRecords
          .where((doc) => _selectedDocumentIds.contains(doc.id))
          .toList();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _diseaseController.dispose();
    _symptomsController.dispose();
    _doctorNameController.dispose();
    _doctorSpecialtyController.dispose();
    _hospitalController.dispose();
    _treatmentController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Format event type for display
  String _formatEventType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  /// Select date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Handle form submission
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final timelineProvider = context.read<MedicalTimelineProvider>();

      final event = MedicalHistory(
        id: widget.event?.id,
        userId: '', // Will be set by the service
        familyMemberId: widget.familyMemberId, // Include family member ID if provided
        eventType: _selectedEventType,
        eventDate: _selectedDate,
        disease: _diseaseController.text.trim().isEmpty
            ? null
            : _diseaseController.text.trim(),
        symptoms: _symptomsController.text.trim().isEmpty
            ? null
            : _symptomsController.text.trim(),
        doctorName: _doctorNameController.text.trim().isEmpty
            ? null
            : _doctorNameController.text.trim(),
        doctorSpecialty: _doctorSpecialtyController.text.trim().isEmpty
            ? null
            : _doctorSpecialtyController.text.trim(),
        hospital: _hospitalController.text.trim().isEmpty
            ? null
            : _hospitalController.text.trim(),
        treatment: _treatmentController.text.trim().isEmpty
            ? null
            : _treatmentController.text.trim(),
        medications: _medicationsController.text.trim().isEmpty
            ? null
            : _medicationsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        documentIds: _selectedDocumentIds.isEmpty ? null : _selectedDocumentIds,
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        updatedAt: widget.event != null ? DateTime.now() : null,
      );

      bool success;
      if (widget.event != null) {
        // Update existing event
        success = await timelineProvider.updateTimelineEvent(
          widget.event!.id!,
          event,
        );
      } else {
        // Add new event
        success = await timelineProvider.addTimelineEvent(event);
      }

      if (mounted) {
        if (success) {
          Get.back();
          Get.snackbar(
            'Success',
            widget.event != null
                ? 'Event updated successfully'
                : 'Event added successfully',
            backgroundColor: AppColors.success,
            colorText: AppColors.textWhite,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            'Error',
            widget.event != null
                ? 'Failed to update event'
                : 'Failed to add event',
            backgroundColor: AppColors.error,
            colorText: AppColors.textWhite,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'An error occurred: $e',
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event != null ? 'Edit Medical History' : languageProvider.tr('add_medical_history')),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormFields(),
                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          languageProvider.tr('save'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build form fields
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Event type dropdown
        DropdownButtonFormField<String>(
          value: _selectedEventType,
          decoration: const InputDecoration(
            labelText: 'Event Type *',
            prefixIcon: Icon(Icons.category),
          ),
          items: _eventTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_formatEventType(type)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedEventType = value!;
            });
          },
        ),
        const SizedBox(height: 16),

        // Date field
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Event Date *',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Disease/Condition field
        TextFormField(
          controller: _diseaseController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Disease/Condition',
            hintText: 'Enter disease or condition',
            prefixIcon: Icon(Icons.medical_information),
          ),
        ),
        const SizedBox(height: 16),

        // Symptoms field
        TextFormField(
          controller: _symptomsController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Symptoms',
            hintText: 'Describe symptoms',
            prefixIcon: Icon(Icons.healing),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),

        // Doctor name field
        TextFormField(
          controller: _doctorNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Doctor Name',
            hintText: 'Enter doctor name',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),

        // Doctor specialty field
        TextFormField(
          controller: _doctorSpecialtyController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Doctor Specialty',
            hintText: 'Enter doctor specialty',
            prefixIcon: Icon(Icons.medical_services),
          ),
        ),
        const SizedBox(height: 16),

        // Hospital field
        TextFormField(
          controller: _hospitalController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Hospital/Clinic',
            hintText: 'Enter hospital name',
            prefixIcon: Icon(Icons.local_hospital),
          ),
        ),
        const SizedBox(height: 16),

        // Treatment field
        TextFormField(
          controller: _treatmentController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Treatment',
            hintText: 'Describe treatment received',
            prefixIcon: Icon(Icons.health_and_safety),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),

        // Medications field
        TextFormField(
          controller: _medicationsController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Medications',
            hintText: 'List medications prescribed',
            prefixIcon: Icon(Icons.medication),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),

        // Notes field
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Additional Notes',
            hintText: 'Any additional notes or observations',
            prefixIcon: Icon(Icons.note),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),

        // Document Attachment Section
        _buildDocumentAttachmentSection(),
      ],
    );
  }

  /// Build document attachment section
  Widget _buildDocumentAttachmentSection() {
    final languageProvider = context.watch<LanguageProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.tr('attach_documents'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Attached documents list
        if (_attachedDocuments.isNotEmpty) ...[
          ..._attachedDocuments.map((doc) => _buildAttachedDocumentCard(doc)),
          const SizedBox(height: 12),
        ],

        // Buttons to attach documents
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectExistingRecords,
                icon: const Icon(Icons.folder_outlined),
                label: Text(languageProvider.tr('select_existing_records')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Get.to(() => AddHealthRecordScreen(
                    familyMemberId: widget.familyMemberId,
                    familyMemberName: widget.familyMemberName,
                  ));
                  // If a document was uploaded, automatically attach it
                  if (result != null && mounted) {
                    await context.read<HealthRecordProvider>().loadHealthRecords();

                    // Auto-attach the newly uploaded document
                    if (result is MedicalDocument && result.id != null) {
                      if (!_selectedDocumentIds.contains(result.id)) {
                        setState(() {
                          _selectedDocumentIds.add(result.id!);
                          _attachedDocuments.add(result);
                        });
                      }
                    }
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: Text(languageProvider.tr('upload_new_document')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        if (_attachedDocuments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              languageProvider.tr('no_documents_attached'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  /// Build attached document card
  Widget _buildAttachedDocumentCard(MedicalDocument doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: doc.thumbnailUrl != null && doc.thumbnailUrl!.isNotEmpty
                ? Image.network(
                    doc.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Show fileUrl if thumbnail fails
                      if (doc.fileUrl.isNotEmpty) {
                        return Image.network(
                          doc.fileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.description, color: AppColors.primary);
                          },
                        );
                      }
                      return const Icon(Icons.description, color: AppColors.primary);
                    },
                  )
                : (doc.fileUrl.isNotEmpty
                    ? Image.network(
                        doc.fileUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.description, color: AppColors.primary);
                        },
                      )
                    : const Icon(Icons.description, color: AppColors.primary)),
          ),
        ),
        title: Text(doc.title),
        subtitle: Text(doc.documentType),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: AppColors.error),
          onPressed: () {
            setState(() {
              _attachedDocuments.removeWhere((d) => d.id == doc.id);
              _selectedDocumentIds.remove(doc.id);
            });
          },
        ),
      ),
    );
  }

  /// Select existing health records
  void _selectExistingRecords() {
    final healthRecordProvider = context.read<HealthRecordProvider>();
    final availableRecords = healthRecordProvider.healthRecords;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final languageProvider = context.watch<LanguageProvider>();

            return AlertDialog(
              title: Text(languageProvider.tr('select_existing_records')),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: availableRecords.isEmpty
                    ? Center(
                        child: Text(languageProvider.tr('no_documents_yet')),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableRecords.length,
                        itemBuilder: (context, index) {
                          final record = availableRecords[index];
                          final isSelected = _selectedDocumentIds.contains(record.id);

                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(record.title),
                            subtitle: Text(record.documentType),
                            secondary: const Icon(Icons.description),
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true && record.id != null) {
                                  if (!_selectedDocumentIds.contains(record.id)) {
                                    _selectedDocumentIds.add(record.id!);
                                    _attachedDocuments.add(record);
                                  }
                                } else {
                                  _selectedDocumentIds.remove(record.id);
                                  _attachedDocuments.removeWhere((d) => d.id == record.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(languageProvider.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Update parent widget
                    Navigator.pop(context);
                  },
                  child: Text(languageProvider.tr('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
