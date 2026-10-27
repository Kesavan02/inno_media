import 'package:equatable/equatable.dart';
import 'conditional_rule_entity.dart';

enum FormFieldType {
  text,
  email,
  phone,
  password,
  number,
  date,
  time,
  radio,
  dropdown,
  checkbox,
  checkboxSingle,
  slider,
  file,
  image,
  textarea,
  switchType,
  unknown,
}

class FormFieldConfigEntity extends Equatable {
  final String id;
  final FormFieldType type;
  final String label;
  final String placeholder;
  final bool required;
  final int? minLength;
  final int? maxLength;
  final double? min;
  final double? max;
  final int? divisions;
  final List<String> options;
  final List<String> allowedExtensions;
  final ConditionalRuleEntity? visibleIf;
  final String? dependsOn;
  final Map<String, List<String>> optionsMap;

  const FormFieldConfigEntity({
    required this.id,
    required this.type,
    required this.label,
    this.placeholder = '',
    this.required = false,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.divisions,
    this.options = const [],
    this.allowedExtensions = const [],
    this.visibleIf,
    this.dependsOn,
    this.optionsMap = const {},
  });

  /// Evaluates whether this field should be rendered based on form values.
  bool isVisible(Map<String, dynamic> formValues) {
    if (visibleIf == null) return true;
    return visibleIf!.evaluate(formValues);
  }

  /// Resolves the available options for dropdowns/radios based on dependency if any.
  List<String> getDynamicOptions(Map<String, dynamic> formValues) {
    if (dependsOn != null && optionsMap.isNotEmpty) {
      final parentValue = formValues[dependsOn];
      if (parentValue != null && optionsMap.containsKey(parentValue.toString())) {
        return optionsMap[parentValue.toString()]!;
      }
      return const [];
    }
    return options;
  }

  /// Validates a single value for this field. Returns error message or null if valid.
  String? validate(dynamic value) {
    // 1. Check Required
    if (required) {
      if (value == null) {
        return '$label is required';
      }
      if (value is String && value.trim().isEmpty) {
        return '$label is required';
      }
      if (value is List && value.isEmpty) {
        return 'Please select at least one $label';
      }
      if (type == FormFieldType.checkboxSingle && value != true) {
        return 'You must accept to proceed';
      }
    }

    // If empty and not required, skip further checks
    if (value == null || (value is String && value.trim().isEmpty)) {
      return null;
    }

    final strValue = value.toString().trim();

    // 2. Length Constraints
    if (minLength != null && strValue.length < minLength!) {
      return '$label must be at least $minLength characters';
    }
    if (maxLength != null && strValue.length > maxLength!) {
      return '$label cannot exceed $maxLength characters';
    }

    // 3. Numeric & Slider Range Constraints
    if (type == FormFieldType.number || type == FormFieldType.slider) {
      final numValue = value is num ? value.toDouble() : double.tryParse(strValue);
      if (numValue == null) {
        return 'Please enter a valid number';
      }
      if (min != null && numValue < min!) {
        return '$label must be at least ${min!.toInt()}';
      }
      if (max != null && numValue > max!) {
        return '$label cannot exceed ${max!.toInt()}';
      }
    }

    // 4. Email Format Check
    if (type == FormFieldType.email) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(strValue)) {
        return 'Please enter a valid email address';
      }
    }

    // 5. Phone Format Check
    if (type == FormFieldType.phone) {
      final digitsOnly = strValue.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length < (maxLength ?? 10)) {
        return 'Please enter a valid 10-digit mobile number';
      }
    }

    return null;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        label,
        placeholder,
        required,
        minLength,
        maxLength,
        min,
        max,
        divisions,
        options,
        allowedExtensions,
        visibleIf,
        dependsOn,
        optionsMap,
      ];
}
