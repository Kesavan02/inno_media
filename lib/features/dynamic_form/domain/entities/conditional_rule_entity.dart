import 'package:equatable/equatable.dart';

/// Represents a conditional visibility rule (e.g. visibleIf: {"field": "is_married", "equals": true})
class ConditionalRuleEntity extends Equatable {
  final String field;
  final dynamic equals;
  final dynamic notEquals;
  final List<dynamic>? inList;

  const ConditionalRuleEntity({
    required this.field,
    this.equals,
    this.notEquals,
    this.inList,
  });

  /// Evaluates whether the condition is met against current form state values.
  bool evaluate(Map<String, dynamic> formValues) {
    final targetValue = formValues[field];

    if (equals != null) {
      return targetValue == equals;
    }

    if (notEquals != null) {
      return targetValue != notEquals;
    }

    if (inList != null) {
      return inList!.contains(targetValue);
    }

    return true;
  }

  @override
  List<Object?> get props => [field, equals, notEquals, inList];
}
