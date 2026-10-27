import '../entities/form_config_entity.dart';
import '../entities/form_submission_entity.dart';
import '../repositories/form_repository.dart';

class GetDefaultFormConfigUseCase {
  final FormRepository repository;
  GetDefaultFormConfigUseCase(this.repository);

  Future<FormConfigEntity> call() => repository.getDefaultFormConfig();
}

class ParseCustomConfigUseCase {
  final FormRepository repository;
  ParseCustomConfigUseCase(this.repository);

  FormConfigEntity call(String jsonString) => repository.parseCustomConfig(jsonString);
}

class SubmitFormUseCase {
  final FormRepository repository;
  SubmitFormUseCase(this.repository);

  Future<FormSubmissionEntity> call({
    required String formTitle,
    required Map<String, dynamic> formValues,
  }) {
    return repository.submitForm(
      formTitle: formTitle,
      formValues: formValues,
    );
  }
}
