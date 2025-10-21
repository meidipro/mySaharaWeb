import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/chronic_disease_detector.dart';
import '../services/ai_disease_service.dart';

/// Widget for managing multiple disease inputs with chronic detection and AI verification
class DiseaseInputWidget extends StatefulWidget {
  final List<String> initialDiseases;
  final Function(List<String>) onDiseasesChanged;
  final String title;
  final String hint;

  const DiseaseInputWidget({
    super.key,
    required this.initialDiseases,
    required this.onDiseasesChanged,
    this.title = 'Diseases',
    this.hint = 'e.g., Diabetes, Hypertension',
  });

  @override
  State<DiseaseInputWidget> createState() => _DiseaseInputWidgetState();
}

class _DiseaseInputWidgetState extends State<DiseaseInputWidget> {
  late List<TextEditingController> _controllers;
  late List<bool> _isChronicList;
  late List<DiseaseVerificationResult?> _verificationResults;
  late List<bool> _isVerifyingList;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.initialDiseases.isEmpty) {
      _controllers = [TextEditingController()];
      _isChronicList = [false];
      _verificationResults = [null];
      _isVerifyingList = [false];
    } else {
      _controllers = widget.initialDiseases
          .map((disease) => TextEditingController(text: disease))
          .toList();
      _isChronicList = widget.initialDiseases
          .map((disease) => ChronicDiseaseDetector.isChronic(disease))
          .toList();
      _verificationResults = List.filled(widget.initialDiseases.length, null);
      _isVerifyingList = List.filled(widget.initialDiseases.length, false);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addDiseaseField() {
    setState(() {
      _controllers.add(TextEditingController());
      _isChronicList.add(false);
      _verificationResults.add(null);
      _isVerifyingList.add(false);
    });
  }

  void _removeDiseaseField(int index) {
    if (_controllers.length > 1) {
      setState(() {
        _controllers[index].dispose();
        _controllers.removeAt(index);
        _isChronicList.removeAt(index);
        _verificationResults.removeAt(index);
        _isVerifyingList.removeAt(index);
        _notifyParent();
      });
    }
  }

  Future<void> _verifyDiseaseWithAI(int index) async {
    final diseaseName = _controllers[index].text.trim();
    if (diseaseName.isEmpty) return;

    setState(() {
      _isVerifyingList[index] = true;
    });

    try {
      final result = await AIDiseaseService.verifyDisease(diseaseName);

      setState(() {
        _verificationResults[index] = result;
        _isChronicList[index] = result.isChronic;
        _isVerifyingList[index] = false;

        // Auto-update with corrected name if available
        if (result.hasCorrection) {
          _controllers[index].text = result.correctedName!;
        }
      });

      _notifyParent();
    } catch (e) {
      setState(() {
        _isVerifyingList[index] = false;
      });

      // Show error in a non-blocking way
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not verify disease: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onDiseaseChanged(int index, String value) {
    setState(() {
      _isChronicList[index] = ChronicDiseaseDetector.isChronic(value);
    });
    _notifyParent();
  }

  void _notifyParent() {
    final diseases = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    widget.onDiseasesChanged(diseases);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.yellow.shade100;
      case 'moderate':
        return Colors.orange.shade100;
      case 'severe':
        return Colors.red.shade100;
      case 'critical':
        return Colors.red.shade300;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _addDiseaseField,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Add More'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Disease input fields
        ..._controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          final isChronic = _isChronicList[index];
          final verificationResult = _verificationResults[index];
          final isVerifying = _isVerifyingList[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          prefixIcon: Icon(
                            verificationResult != null && verificationResult.isValid
                                ? Icons.check_circle
                                : Icons.medical_services,
                            color: verificationResult != null && verificationResult.isValid
                                ? AppColors.success
                                : (isChronic ? AppColors.error : AppColors.textSecondary),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_controllers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _removeDiseaseField(index),
                                  color: AppColors.error,
                                ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isChronic
                                  ? AppColors.error.withOpacity(0.5)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isChronic
                                  ? AppColors.error.withOpacity(0.3)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isChronic ? AppColors.error : AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isChronic
                              ? AppColors.error.withOpacity(0.05)
                              : Colors.grey[50],
                        ),
                        onChanged: (value) => _onDiseaseChanged(index, value),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AI Verify Button
                    ElevatedButton.icon(
                      onPressed: isVerifying || controller.text.trim().isEmpty
                          ? null
                          : () => _verifyDiseaseWithAI(index),
                      icon: isVerifying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),

                // Chronic disease indicator (basic detection)
                if (controller.text.isNotEmpty && isChronic && verificationResult == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 50, top: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chronic disease detected - long-term condition',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // AI Verification Results
                if (verificationResult != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: verificationResult.isValid
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: verificationResult.isValid
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Verification Status
                          Row(
                            children: [
                              Icon(
                                verificationResult.isValid ? Icons.check_circle : Icons.warning,
                                size: 18,
                                color: verificationResult.isValid ? AppColors.success : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  verificationResult.isValid
                                      ? 'Verified: ${verificationResult.displayName}'
                                      : 'Invalid disease name',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: verificationResult.isValid
                                        ? Colors.green.shade900
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Spelling Correction
                          if (verificationResult.hasCorrection)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Corrected spelling from: ${verificationResult.originalName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                          // Category & Severity
                          if (verificationResult.category != null || verificationResult.severity != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  if (verificationResult.category != null)
                                    Chip(
                                      label: Text(
                                        verificationResult.category!,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Colors.blue.shade100,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (verificationResult.severity != null)
                                    Chip(
                                      label: Text(
                                        verificationResult.severity!,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: _getSeverityColor(verificationResult.severity!),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  Chip(
                                    label: Text(
                                      verificationResult.isChronic ? 'Chronic' : 'Acute',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: verificationResult.isChronic
                                        ? Colors.red.shade100
                                        : Colors.green.shade100,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ),

                          // Information
                          if (verificationResult.information != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                verificationResult.information!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),

                          // Symptoms
                          if (verificationResult.symptoms.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Common symptoms:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: verificationResult.symptoms
                                        .take(4)
                                        .map((symptom) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                symptom,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),

                          // Suggestions
                          if (verificationResult.hasSuggestions)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Did you mean:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...verificationResult.suggestions.map((suggestion) => Text(
                                        '• $suggestion',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue.shade700,
                                        ),
                                      )),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),

        // Help text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add all diseases (both chronic and temporary). System will automatically detect chronic conditions.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
