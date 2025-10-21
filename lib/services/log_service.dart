import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_sahara_app/models/progress_summary.dart';
import 'package:my_sahara_app/services/auth_service.dart'; // To get the token

class LogService {
  final String _baseUrl = 'http://localhost:8000/api/logs';
  final String _progressUrl = 'http://localhost:8000/api/progress';
  final AuthService _authService = AuthService();

  Future<void> logDailyHealth(Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/daily'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save daily log');
    }
  }

  Future<void> logExercise(Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/exercise'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save exercise log');
    }
  }

  Future<ProgressSummary> getProgressSummary() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$_progressUrl/summary'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ProgressSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load progress summary');
    }
  }
}
