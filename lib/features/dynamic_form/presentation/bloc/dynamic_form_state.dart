import 'package:equatable/equatable.dart';
import '../../domain/entities/form_config_entity.dart';
import '../../domain/entities/form_submission_entity.dart';

enum FormStatus { initial, loading, loaded, submitting, success, error }

class DynamicFormState extends Equatable {
  final FormStatus status;
  final FormConfigEntity? config;
  final Map<String, dynamic> formValues;
  final Map<String, String> fieldErrors;
  final FormSubmissionEntity? submissionResult;
  final String? errorMessage;
  final String? toastMessage;

  const DynamicFormState({
    required this.status,
    this.config,
    required this.formValues,
    required this.fieldErrors,
    this.submissionResult,
    this.errorMessage,
    this.toastMessage,
  });

  factory DynamicFormState.initial() {
    return const DynamicFormState(
      status: FormStatus.initial,
      config: null,
      formValues: {},
      fieldErrors: {},
    );
  }

  DynamicFormState copyWith({
    FormStatus? status,
    FormConfigEntity? config,
    Map<String, dynamic>? formValues,
    Map<String, String>? fieldErrors,
    FormSubmissionEntity? submissionResult,
    String? errorMessage,
    String? toastMessage,
    bool clearSubmission = false,
  }) {
    return DynamicFormState(
      status: status ?? this.status,
      config: config ?? this.config,
      formValues: formValues ?? this.formValues,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      submissionResult: clearSubmission ? null : (submissionResult ?? this.submissionResult),
      errorMessage: errorMessage,
      toastMessage: toastMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        config,
        formValues,
        fieldErrors,
        submissionResult,
        errorMessage,
        toastMessage,
      ];
}
