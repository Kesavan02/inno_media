import '../../domain/entities/form_field_config_entity.dart';
import 'conditional_rule_model.dart';

class FormFieldConfigModel extends FormFieldConfigEntity {
  const FormFieldConfigModel({
    required super.id,
    required super.type,
    required super.label,
    super.placeholder,
    super.required,
    super.minLength,
    super.maxLength,
    super.min,
    super.max,
    super.divisions,
    super.options,
    super.allowedExtensions,
    super.visibleIf,
    super.dependsOn,
    super.optionsMap,
  });

  factory FormFieldConfigModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'text';
    final formType = _mapStringToType(typeStr);

    ConditionalRuleModel? rule;
    if (json['visibleIf'] != null && json['visibleIf'] is Map<String, dynamic>) {
      rule = ConditionalRuleModel.fromJson(json['visibleIf'] as Map<String, dynamic>);
    }

    // Parse optionsMap
    final optionsMap = <String, List<String>>{};
    if (json['optionsMap'] != null && json['optionsMap'] is Map) {
      final rawMap = json['optionsMap'] as Map;
      for (final key in rawMap.keys) {
        if (rawMap[key] is List) {
          optionsMap[key.toString()] = (rawMap[key] as List).map((e) => e.toString()).toList();
        }
      }
    }

    return FormFieldConfigModel(
      id: json['id'] as String,
      type: formType,
      label: json['label'] as String? ?? '',
      placeholder: json['placeholder'] as String? ?? '',
      required: json['required'] as bool? ?? false,
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      divisions: json['divisions'] as int?,
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      allowedExtensions: (json['allowedExtensions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      visibleIf: rule,
      dependsOn: json['dependsOn'] as String?,
      optionsMap: optionsMap,
    );
  }

  static FormFieldType _mapStringToType(String str) {
    switch (str.toLowerCase()) {
      case 'text':
        return FormFieldType.text;
      case 'email':
        return FormFieldType.email;
      case 'phone':
        return FormFieldType.phone;
      case 'password':
        return FormFieldType.password;
      case 'number':
        return FormFieldType.number;
      case 'date':
        return FormFieldType.date;
      case 'time':
        return FormFieldType.time;
      case 'radio':
        return FormFieldType.radio;
      case 'dropdown':
        return FormFieldType.dropdown;
      case 'checkbox':
        return FormFieldType.checkbox;
      case 'checkbox_single':
        return FormFieldType.checkboxSingle;
      case 'slider':
        return FormFieldType.slider;
      case 'file':
        return FormFieldType.file;
      case 'image':
        return FormFieldType.image;
      case 'textarea':
        return FormFieldType.textarea;
      case 'switch':
        return FormFieldType.switchType;
      default:
        return FormFieldType.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'placeholder': placeholder,
      'required': required,
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (divisions != null) 'divisions': divisions,
      if (options.isNotEmpty) 'options': options,
      if (allowedExtensions.isNotEmpty) 'allowedExtensions': allowedExtensions,
      if (visibleIf != null) 'visibleIf': (visibleIf as ConditionalRuleModel).toJson(),
      if (dependsOn != null) 'dependsOn': dependsOn,
      if (optionsMap.isNotEmpty) 'optionsMap': optionsMap,
    };
  }
}
