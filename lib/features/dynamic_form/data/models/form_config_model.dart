import '../../domain/entities/form_config_entity.dart';
import 'form_field_config_model.dart';

class FormConfigModel extends FormConfigEntity {
  FormConfigModel({
    required super.title,
    required super.submitButton,
    required super.fields,
  });

  factory FormConfigModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? 'Dynamic Form';
    final submitButton = json['submitButton'] as String? ?? 'Submit';
    final fieldsRaw = json['fields'] as List<dynamic>? ?? [];

    final fields = fieldsRaw
        .map((f) => FormFieldConfigModel.fromJson(f as Map<String, dynamic>))
        .toList();

    return FormConfigModel(
      title: title,
      submitButton: submitButton,
      fields: fields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'submitButton': submitButton,
      'fields': fields.map((f) => (f as FormFieldConfigModel).toJson()).toList(),
    };
  }
}
