import 'package:equatable/equatable.dart';

abstract class DynamicFormEvent extends Equatable {
  const DynamicFormEvent();
  @override
  List<Object?> get props => [];
}

class LoadDefaultFormConfigEvent extends DynamicFormEvent {}

class LoadCustomJsonConfigEvent extends DynamicFormEvent {
  final String jsonString;
  const LoadCustomJsonConfigEvent(this.jsonString);
  @override
  List<Object?> get props => [jsonString];
}

class FormFieldValueChangedEvent extends DynamicFormEvent {
  final String fieldId;
  final dynamic value;

  const FormFieldValueChangedEvent({
    required this.fieldId,
    required this.value,
  });

  @override
  List<Object?> get props => [fieldId, value];
}

class SubmitDynamicFormEvent extends DynamicFormEvent {}

class ResetFormEvent extends DynamicFormEvent {}
