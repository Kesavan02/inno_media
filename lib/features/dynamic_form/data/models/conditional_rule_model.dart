import '../../domain/entities/conditional_rule_entity.dart';

class ConditionalRuleModel extends ConditionalRuleEntity {
  const ConditionalRuleModel({
    required super.field,
    super.equals,
    super.notEquals,
    super.inList,
  });

  factory ConditionalRuleModel.fromJson(Map<String, dynamic> json) {
    return ConditionalRuleModel(
      field: json['field'] as String,
      equals: json['equals'],
      notEquals: json['notEquals'],
      inList: json['in'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      if (equals != null) 'equals': equals,
      if (notEquals != null) 'notEquals': notEquals,
      if (inList != null) 'in': inList,
    };
  }
}
