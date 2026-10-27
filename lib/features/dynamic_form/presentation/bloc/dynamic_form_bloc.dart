import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/form_config_entity.dart';
import '../../domain/entities/form_field_config_entity.dart';
import '../../domain/usecases/form_usecases.dart';
import 'dynamic_form_event.dart';
import 'dynamic_form_state.dart';

class DynamicFormBloc extends Bloc<DynamicFormEvent, DynamicFormState> {
  final GetDefaultFormConfigUseCase getDefaultFormConfigUseCase;
  final ParseCustomConfigUseCase parseCustomConfigUseCase;
  final SubmitFormUseCase submitFormUseCase;

  DynamicFormBloc({
    required this.getDefaultFormConfigUseCase,
    required this.parseCustomConfigUseCase,
    required this.submitFormUseCase,
  }) : super(DynamicFormState.initial()) {
    on<LoadDefaultFormConfigEvent>(_onLoadDefaultConfig);
    on<LoadCustomJsonConfigEvent>(_onLoadCustomJson);
    on<FormFieldValueChangedEvent>(_onFieldValueChanged);
    on<SubmitDynamicFormEvent>(_onSubmitForm);
    on<ResetFormEvent>(_onResetForm);
  }

  Future<void> _onLoadDefaultConfig(
    LoadDefaultFormConfigEvent event,
    Emitter<DynamicFormState> emit,
  ) async {
    emit(state.copyWith(status: FormStatus.loading));
    try {
      final config = await getDefaultFormConfigUseCase();
      final initialValues = _extractDefaultValues(config);
      emit(state.copyWith(
        status: FormStatus.loaded,
        config: config,
        formValues: initialValues,
        fieldErrors: {},
        clearSubmission: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: 'Failed to load form configuration: ${e.toString()}',
      ));
    }
  }

  void _onLoadCustomJson(
    LoadCustomJsonConfigEvent event,
    Emitter<DynamicFormState> emit,
  ) {
    try {
      final config = parseCustomConfigUseCase(event.jsonString);
      final initialValues = _extractDefaultValues(config);
      emit(state.copyWith(
        status: FormStatus.loaded,
        config: config,
        formValues: initialValues,
        fieldErrors: {},
        clearSubmission: true,
        toastMessage: 'Custom schema applied successfully!',
      ));
    } on Failure catch (f) {
      emit(state.copyWith(toastMessage: f.message));
    } catch (e) {
      emit(state.copyWith(toastMessage: 'Invalid JSON configuration: ${e.toString()}'));
    }
  }

  void _onFieldValueChanged(
    FormFieldValueChangedEvent event,
    Emitter<DynamicFormState> emit,
  ) {
    final updatedValues = Map<String, dynamic>.from(state.formValues);
    updatedValues[event.fieldId] = event.value;

    final updatedErrors = Map<String, String>.from(state.fieldErrors);

    // Validate changed field in real time
    final fieldConfig = state.config?.getFieldById(event.fieldId);
    if (fieldConfig != null) {
      final error = fieldConfig.validate(event.value);
      if (error != null) {
        updatedErrors[event.fieldId] = error;
      } else {
        updatedErrors.remove(event.fieldId);
      }
    }

    // Dependent fields logic:
    // If a parent field (e.g., country) changed, reset child dependent fields (e.g. state)
    if (state.config != null) {
      for (final field in state.config!.fields) {
        if (field.dependsOn == event.fieldId) {
          updatedValues[field.id] = null;
          updatedErrors.remove(field.id);
        }
        // If conditional field became hidden, clear its value & errors
        if (field.visibleIf != null && !field.isVisible(updatedValues)) {
          updatedValues[field.id] = null;
          updatedErrors.remove(field.id);
        }
      }
    }

    emit(state.copyWith(
      formValues: updatedValues,
      fieldErrors: updatedErrors,
      toastMessage: null,
    ));
  }

  Future<void> _onSubmitForm(
    SubmitDynamicFormEvent event,
    Emitter<DynamicFormState> emit,
  ) async {
    final config = state.config;
    if (config == null) return;

    // 1. Validate all currently visible fields
    final errors = <String, String>{};
    for (final field in config.fields) {
      // Only validate if field is visible under conditional rules
      if (field.isVisible(state.formValues)) {
        final val = state.formValues[field.id];
        final err = field.validate(val);
        if (err != null) {
          errors[field.id] = err;
        }
      }
    }

    if (errors.isNotEmpty) {
      emit(state.copyWith(
        fieldErrors: errors,
        toastMessage: 'Please fix the highlighted errors before submitting',
      ));
      return;
    }

    // 2. Submit form with rate limit handling
    emit(state.copyWith(status: FormStatus.submitting));
    try {
      // Filter out values of hidden fields
      final sanitizedValues = <String, dynamic>{};
      for (final entry in state.formValues.entries) {
        final field = config.getFieldById(entry.key);
        if (field != null && field.isVisible(state.formValues)) {
          sanitizedValues[entry.key] = entry.value;
        }
      }

      final result = await submitFormUseCase(
        formTitle: config.title,
        formValues: sanitizedValues,
      );

      emit(state.copyWith(
        status: FormStatus.success,
        submissionResult: result,
        toastMessage: 'Form submitted successfully!',
      ));
    } on RateLimitFailure catch (r) {
      emit(state.copyWith(
        status: FormStatus.loaded,
        toastMessage: r.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FormStatus.loaded,
        toastMessage: 'Submission failed: ${e.toString()}',
      ));
    }
  }

  void _onResetForm(
    ResetFormEvent event,
    Emitter<DynamicFormState> emit,
  ) {
    if (state.config != null) {
      final defaultVals = _extractDefaultValues(state.config!);
      emit(state.copyWith(
        status: FormStatus.loaded,
        formValues: defaultVals,
        fieldErrors: {},
        clearSubmission: true,
      ));
    }
  }

  Map<String, dynamic> _extractDefaultValues(FormConfigEntity config) {
    final values = <String, dynamic>{};
    for (final field in config.fields) {
      switch (field.type) {
        case FormFieldType.switchType:
          values[field.id] = false;
          break;
        case FormFieldType.checkboxSingle:
          values[field.id] = false;
          break;
        case FormFieldType.checkbox:
          values[field.id] = <String>[];
          break;
        case FormFieldType.slider:
          values[field.id] = field.min ?? 0.0;
          break;
        default:
          values[field.id] = null;
      }
    }
    return values;
  }
}
