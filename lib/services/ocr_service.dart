import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for OCR (Optical Character Recognition) using Google ML Kit
class OCRService {
  late final TextRecognizer _textRecognizer;

  OCRService() {
    // Initialize text recognizer with default script (Latin)
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Extract text from image file
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      // Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);

      // Process image and recognize text
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Extract all text blocks
      final StringBuffer extractedText = StringBuffer();

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText.writeln(line.text);
        }
      }

      return extractedText.toString().trim();
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Extract structured data from medical document
  /// Returns a map with extracted medical information
  Future<Map<String, dynamic>> extractMedicalData(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      Map<String, dynamic> extractedData = {
        'fullText': '',
        'doctorName': null,
        'hospitalName': null,
        'date': null,
        'medications': <String>[],
        'diagnosis': null,
        'patientName': null,
      };

      // Extract all text
      final StringBuffer fullText = StringBuffer();
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          fullText.writeln(line.text);
        }
      }
      extractedData['fullText'] = fullText.toString().trim();

      // Parse the text for structured data
      final text = extractedData['fullText'] as String;
      final textLower = text.toLowerCase();

      // Extract doctor name
      extractedData['doctorName'] = _extractDoctorName(text);

      // Extract hospital/clinic name
      extractedData['hospitalName'] = _extractHospitalName(text);

      // Extract date
      extractedData['date'] = _extractDate(text);

      // Extract medications
      extractedData['medications'] = _extractMedications(text);

      // Extract diagnosis/disease
      extractedData['diagnosis'] = _extractDiagnosis(text);

      // Extract patient name
      extractedData['patientName'] = _extractPatientName(text);

      return extractedData;
    } catch (e) {
      throw Exception('Failed to extract medical data: $e');
    }
  }

  /// Extract doctor name from text
  String? _extractDoctorName(String text) {
    // Common patterns for doctor names
    final patterns = [
      RegExp(r'Dr\.?\s+([A-Z][a-zA-Z\s\.]+)', caseSensitive: false),
      RegExp(r'Doctor[:\s]+([A-Z][a-zA-Z\s\.]+)', caseSensitive: false),
      RegExp(r'Physician[:\s]+([A-Z][a-zA-Z\s\.]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.length > 3 && name.length < 50) {
          return name;
        }
      }
    }

    return null;
  }

  /// Extract hospital/clinic name from text
  String? _extractHospitalName(String text) {
    final patterns = [
      RegExp(r'([\w\s]+Hospital)', caseSensitive: false),
      RegExp(r'([\w\s]+Clinic)', caseSensitive: false),
      RegExp(r'([\w\s]+Medical\s+Center)', caseSensitive: false),
      RegExp(r'([\w\s]+Healthcare)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.length > 5 && name.length < 100) {
          return name;
        }
      }
    }

    return null;
  }

  /// Extract date from text
  String? _extractDate(String text) {
    final patterns = [
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b'),
      // YYYY-MM-DD
      RegExp(r'\b(\d{4}[/-]\d{1,2}[/-]\d{1,2})\b'),
      // Month DD, YYYY
      RegExp(
          r'\b(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(\d{1,2}),?\s+(\d{4})\b',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }

  /// Extract medications from text
  List<String> _extractMedications(String text) {
    final medications = <String>[];
    final lines = text.split('\n');

    // Look for common medication patterns
    final medicationPattern = RegExp(
      r'\b([A-Z][a-zA-Z]+(?:ine|ol|cin|xin|pril|sartan|tide|mab))\b',
      caseSensitive: false,
    );

    // Look for lines that might contain medication information
    final rxPattern = RegExp(r'Rx|Medication|Medicine', caseSensitive: false);

    bool inMedicationSection = false;
    for (final line in lines) {
      if (rxPattern.hasMatch(line)) {
        inMedicationSection = true;
        continue;
      }

      if (inMedicationSection) {
        final matches = medicationPattern.allMatches(line);
        for (final match in matches) {
          final medication = match.group(1);
          if (medication != null && !medications.contains(medication)) {
            medications.add(medication);
          }
        }

        // Stop if we hit an empty line or new section
        if (line.trim().isEmpty) {
          inMedicationSection = false;
        }
      }
    }

    return medications;
  }

  /// Extract diagnosis/disease from text
  String? _extractDiagnosis(String text) {
    final patterns = [
      RegExp(r'Diagnosis[:\s]+([^\n]+)', caseSensitive: false),
      RegExp(r'Disease[:\s]+([^\n]+)', caseSensitive: false),
      RegExp(r'Condition[:\s]+([^\n]+)', caseSensitive: false),
      RegExp(r'Impression[:\s]+([^\n]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final diagnosis = match.group(1)?.trim();
        if (diagnosis != null && diagnosis.length > 3 && diagnosis.length < 200) {
          return diagnosis;
        }
      }
    }

    return null;
  }

  /// Extract patient name from text
  String? _extractPatientName(String text) {
    final patterns = [
      RegExp(r'Patient[:\s]+([A-Z][a-zA-Z\s\.]+)', caseSensitive: false),
      RegExp(r'Name[:\s]+([A-Z][a-zA-Z\s\.]+)', caseSensitive: false),
      RegExp(r'Mr\.|Mrs\.|Ms\.\s+([A-Z][a-zA-Z\s\.]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.length > 3 && name.length < 50) {
          return name;
        }
      }
    }

    return null;
  }

  /// Extract text from specific regions of interest
  Future<Map<String, String>> extractTextByRegions(
    File imageFile,
    List<Rect> regions,
  ) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final Map<String, String> extractedRegions = {};

      for (int i = 0; i < regions.length; i++) {
        final region = regions[i];
        final StringBuffer regionText = StringBuffer();

        for (TextBlock block in recognizedText.blocks) {
          // Check if block intersects with region
          if (_isIntersecting(block.boundingBox, region)) {
            for (TextLine line in block.lines) {
              regionText.writeln(line.text);
            }
          }
        }

        extractedRegions['region_$i'] = regionText.toString().trim();
      }

      return extractedRegions;
    } catch (e) {
      throw Exception('Failed to extract text by regions: $e');
    }
  }

  /// Check if two rectangles intersect
  bool _isIntersecting(Rect rect1, Rect rect2) {
    return rect1.left < rect2.right &&
        rect1.right > rect2.left &&
        rect1.top < rect2.bottom &&
        rect1.bottom > rect2.top;
  }

  /// Get text recognition confidence
  Future<double> getConfidence(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        return 0.0;
      }

      // Calculate average confidence across all text elements
      double totalConfidence = 0.0;
      int elementCount = 0;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            // Note: confidence might not be available in all versions
            // This is a placeholder implementation
            totalConfidence += 1.0;
            elementCount++;
          }
        }
      }

      return elementCount > 0 ? totalConfidence / elementCount : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
