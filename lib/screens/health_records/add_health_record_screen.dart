import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:file_picker/file_picker.dart';

import '../../constants/app_colors.dart';
import '../../models/medical_document.dart';
import '../../providers/health_record_provider.dart';

/// Screen for adding new health records
class AddHealthRecordScreen extends StatefulWidget {
  final String? familyMemberId; // Optional: for family member's documents
  final String? familyMemberName; // Optional: for display

  const AddHealthRecordScreen({
    super.key,
    this.familyMemberId,
    this.familyMemberName,
  });

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _diseaseController = TextEditingController();

  String _selectedDocumentType = 'other';
  DateTime _selectedDate = DateTime.now();
  File? _selectedFile;
  Uint8List? _webImage; // For web image preview
  bool _isLoading = false;

  final List<String> _documentTypes = [
    'prescription',
    'test_report',
    'mri_report',
    'xray_report',
    'blood_report',
    'ct_scan',
    'ultrasound',
    'doctor_notes',
    'other',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _doctorNameController.dispose();
    _hospitalController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  /// Format document type for display
  String _formatDocumentType(String type) {
    return type
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Validate required fields
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to capture image: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedFile = File(image.path);
            _webImage = bytes;
          });
        } else {
          setState(() {
            _selectedFile = File(image.path);
          });
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Pick file from device
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        if (kIsWeb) {
          // For web, get bytes
          setState(() {
            _selectedFile = File(result.files.single.name);
            _webImage = result.files.single.bytes;
          });
        } else {
          setState(() {
            _selectedFile = File(result.files.single.path!);
          });
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick file: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Source',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: AppColors.primary),
              title: const Text('Files'),
              subtitle: const Text('Select a file'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Handle form submission
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      Get.snackbar(
        'No File Selected',
        'Please select a document to upload',
        backgroundColor: AppColors.warning,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final healthRecordProvider = context.read<HealthRecordProvider>();

      final document = MedicalDocument(
        userId: '', // Will be set by the service
        familyMemberId: widget.familyMemberId, // Include family member ID if provided
        documentType: _selectedDocumentType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        disease: _diseaseController.text.trim(),
        doctorName: _doctorNameController.text.trim(),
        hospital: _hospitalController.text.trim(),
        documentDate: _selectedDate,
        fileUrl: '', // Will be set after upload
        ocrData: null, // OCR disabled for MVP
        createdAt: DateTime.now(),
      );

      // Pass bytes for web, file for mobile
      final fileData = kIsWeb ? _webImage! : _selectedFile!;
      final fileName = _selectedFile!.path.split('/').last.split('\\').last;

      final success = await healthRecordProvider.addHealthRecord(document, fileData, fileName);

      if (mounted) {
        if (success && healthRecordProvider.healthRecords.isNotEmpty) {
          // Return the newly created document (it's at index 0 - most recent)
          final newDocument = healthRecordProvider.healthRecords.first;
          Get.back(result: newDocument);
        } else {
          Get.back();
        }
        Get.snackbar(
          'Success',
          'Document uploaded successfully',
          backgroundColor: AppColors.success,
          colorText: AppColors.textWhite,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to upload document: $e',
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

  /// Select date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Health Record'),
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
                // File upload section
                _buildFileUploadSection(),
                const SizedBox(height: 24),

                // Form fields
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
                      : const Text(
                          'Add Record',
                          style: TextStyle(
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

  /// Build file upload section
  Widget _buildFileUploadSection() {
    return Card(
      child: InkWell(
        onTap: _showImageSourceDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.border,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedFile == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to upload document',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera, Gallery, or Files',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (_selectedFile!.path.toLowerCase().endsWith('.pdf'))
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 64,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'PDF Document',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                            )
                          : kIsWeb
                              ? (_webImage != null
                                  ? Image.memory(
                                      _webImage!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox())
                              : Image.file(
                                  _selectedFile!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _webImage = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
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
        // Title field
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.words,
          validator: (value) => _validateRequired(value, 'title'),
          decoration: const InputDecoration(
            labelText: 'Title *',
            hintText: 'Enter document title',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 16),

        // Document type dropdown
        DropdownButtonFormField<String>(
          value: _selectedDocumentType,
          decoration: const InputDecoration(
            labelText: 'Document Type *',
            prefixIcon: Icon(Icons.category),
          ),
          items: _documentTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_formatDocumentType(type)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDocumentType = value!;
            });
          },
        ),
        const SizedBox(height: 16),

        // Date field
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Document Date *',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Doctor name field
        TextFormField(
          controller: _doctorNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Doctor Name',
            hintText: 'Enter doctor name (optional)',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),

        // Hospital field
        TextFormField(
          controller: _hospitalController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Hospital/Clinic',
            hintText: 'Enter hospital name (optional)',
            prefixIcon: Icon(Icons.local_hospital),
          ),
        ),
        const SizedBox(height: 16),

        // Disease field
        TextFormField(
          controller: _diseaseController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Disease/Condition',
            hintText: 'Enter disease or condition (optional)',
            prefixIcon: Icon(Icons.medical_information),
          ),
        ),
        const SizedBox(height: 16),

        // Description field
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Enter description (optional)',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
