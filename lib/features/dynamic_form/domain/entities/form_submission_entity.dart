import 'package:equatable/equatable.dart';

class FormSubmissionEntity extends Equatable {
  final String formTitle;
  final Map<String, dynamic> submittedValues;
  final DateTime submittedAt;

  const FormSubmissionEntity({
    required this.formTitle,
    required this.submittedValues,
    required this.submittedAt,
  });

  @override
  List<Object?> get props => [formTitle, submittedValues, submittedAt];
}
