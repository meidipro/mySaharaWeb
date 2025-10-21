import 'package:flutter/material.dart';
import 'package:my_sahara_app/models/progress_summary.dart';
import 'package:my_sahara_app/services/log_service.dart';

class ProgressProvider with ChangeNotifier {
  final LogService _logService = LogService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ProgressSummary? _summary;
  ProgressSummary? get summary => _summary;

  Future<void> fetchProgressSummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      _summary = await _logService.getProgressSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> saveDailyLog(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _logService.logDailyHealth(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
