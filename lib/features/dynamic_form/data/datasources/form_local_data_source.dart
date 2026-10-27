import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/form_config_model.dart';

abstract class FormLocalDataSource {
  Future<FormConfigModel> getDefaultFormConfig();
  FormConfigModel parseCustomJsonConfig(String jsonString);
  Future<void> saveFormSubmission(Map<String, dynamic> submission);
  Future<List<Map<String, dynamic>>> getSubmissionHistory();
}

class FormLocalDataSourceImpl implements FormLocalDataSource {
  final SharedPreferences sharedPreferences;

  FormLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<FormConfigModel> getDefaultFormConfig() async {
    String jsonString;
    final file = File('assets/json/form_config.json');
    if (file.existsSync()) {
      jsonString = file.readAsStringSync();
    } else {
      jsonString = await rootBundle.loadString('assets/json/form_config.json');
    }
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return FormConfigModel.fromJson(jsonMap);
  }

  @override
  FormConfigModel parseCustomJsonConfig(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return FormConfigModel.fromJson(jsonMap);
  }

  @override
  Future<void> saveFormSubmission(Map<String, dynamic> submission) async {
    final history = await getSubmissionHistory();
    history.insert(0, submission);
    await sharedPreferences.setString(AppConstants.keySavedForms, jsonEncode(history));
  }

  @override
  Future<List<Map<String, dynamic>>> getSubmissionHistory() async {
    final raw = sharedPreferences.getString(AppConstants.keySavedForms);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
