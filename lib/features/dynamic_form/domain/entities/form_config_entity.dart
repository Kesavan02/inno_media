import 'package:equatable/equatable.dart';
import 'form_field_config_entity.dart';

class FormConfigEntity extends Equatable {
  final String title;
  final String submitButton;
  final List<FormFieldConfigEntity> fields;
  final Map<String, FormFieldConfigEntity> fieldIndex;

  FormConfigEntity({
    required this.title,
    required this.submitButton,
    required this.fields,
  }) : fieldIndex = {for (final f in fields) f.id: f};

  /// Returns field by ID in O(1) time.
  FormFieldConfigEntity? getFieldById(String id) => fieldIndex[id];

  @override
  List<Object?> get props => [title, submitButton, fields];
}
