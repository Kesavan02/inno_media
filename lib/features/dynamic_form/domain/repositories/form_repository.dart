import '../entities/form_config_entity.dart';
import '../entities/form_submission_entity.dart';

abstract class FormRepository {
  Future<FormConfigEntity> getDefaultFormConfig();
  FormConfigEntity parseCustomConfig(String jsonString);
  Future<FormSubmissionEntity> submitForm({
    required String formTitle,
    required Map<String, dynamic> formValues,
  });
  Future<List<Map<String, dynamic>>> getSubmissionHistory();
}
