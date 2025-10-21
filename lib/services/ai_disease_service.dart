import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI-powered disease verification and information service
/// Uses Groq API for intelligent disease detection
class AIDiseaseService {
  static final String _groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Verify disease name and get information
  static Future<DiseaseVerificationResult> verifyDisease(String diseaseName) async {
    if (diseaseName.isEmpty) {
      return DiseaseVerificationResult(
        isValid: false,
        originalName: diseaseName,
        correctedName: null,
        isChronic: false,
        information: null,
        suggestions: [],
      );
    }

    try {
      final prompt = '''
You are a medical disease verification assistant. Analyze the disease name and provide structured information.

Disease Name: "$diseaseName"

Provide a JSON response with this exact structure:
{
  "is_valid": true/false,
  "corrected_name": "proper disease name" or null if invalid,
  "is_chronic": true/false,
  "category": "category name" (e.g., Cardiovascular, Respiratory, etc.),
  "information": "Brief 2-3 sentence description of the disease",
  "symptoms": ["symptom1", "symptom2", "symptom3"],
  "suggestions": ["alternative spelling 1", "alternative spelling 2"] (if misspelled),
  "severity": "Mild/Moderate/Severe/Critical"
}

Rules:
- If the name is misspelled, provide the correct name in "corrected_name"
- If it's a valid disease, is_valid = true
- Chronic diseases are long-term conditions (diabetes, hypertension, etc.)
- Acute diseases are temporary (flu, cold, infection, etc.)
- Keep information concise and patient-friendly
- Return ONLY valid JSON, no extra text
''';

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a medical AI assistant. Always respond with valid JSON only.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Clean the response to extract JSON
        String jsonStr = content.trim();
        if (jsonStr.contains('```json')) {
          jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
        } else if (jsonStr.contains('```')) {
          jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
        }

        final diseaseData = jsonDecode(jsonStr);

        return DiseaseVerificationResult(
          isValid: diseaseData['is_valid'] ?? false,
          originalName: diseaseName,
          correctedName: diseaseData['corrected_name'],
          isChronic: diseaseData['is_chronic'] ?? false,
          category: diseaseData['category'],
          information: diseaseData['information'],
          symptoms: diseaseData['symptoms'] != null
              ? List<String>.from(diseaseData['symptoms'])
              : [],
          suggestions: diseaseData['suggestions'] != null
              ? List<String>.from(diseaseData['suggestions'])
              : [],
          severity: diseaseData['severity'],
        );
      } else {
        throw Exception('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error verifying disease with AI: $e');
      // Return basic result on error
      return DiseaseVerificationResult(
        isValid: true,
        originalName: diseaseName,
        correctedName: diseaseName,
        isChronic: false,
        information: 'Unable to verify disease information at this time.',
        suggestions: [],
      );
    }
  }

  /// Get detailed disease information
  static Future<String> getDiseaseInformation(String diseaseName) async {
    try {
      final prompt = '''
Provide concise, patient-friendly information about: $diseaseName

Include:
1. What it is (1-2 sentences)
2. Common symptoms (3-4 items)
3. Is it chronic or acute?
4. Basic management tips (2-3 items)

Keep it simple and under 150 words.
''';

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful medical information assistant. Provide clear, accurate, patient-friendly information.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.5,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      }
    } catch (e) {
      print('Error getting disease information: $e');
    }
    return 'Information not available';
  }

  /// Batch verify multiple diseases
  static Future<List<DiseaseVerificationResult>> verifyMultipleDiseases(
    List<String> diseases,
  ) async {
    final results = <DiseaseVerificationResult>[];

    for (final disease in diseases) {
      if (disease.trim().isNotEmpty) {
        final result = await verifyDisease(disease);
        results.add(result);
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return results;
  }
}

/// Disease verification result model
class DiseaseVerificationResult {
  final bool isValid;
  final String originalName;
  final String? correctedName;
  final bool isChronic;
  final String? category;
  final String? information;
  final List<String> symptoms;
  final List<String> suggestions;
  final String? severity;

  DiseaseVerificationResult({
    required this.isValid,
    required this.originalName,
    this.correctedName,
    required this.isChronic,
    this.category,
    this.information,
    this.symptoms = const [],
    this.suggestions = const [],
    this.severity,
  });

  String get displayName => correctedName ?? originalName;

  bool get hasCorrection => correctedName != null && correctedName != originalName;

  bool get hasSuggestions => suggestions.isNotEmpty;
}
