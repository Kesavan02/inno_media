import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tactile_bounce.dart';
import '../bloc/dynamic_form_bloc.dart';
import '../bloc/dynamic_form_event.dart';

class LiveJsonEditorPage extends StatefulWidget {
  const LiveJsonEditorPage({super.key});

  @override
  State<LiveJsonEditorPage> createState() => _LiveJsonEditorPageState();
}

class _LiveJsonEditorPageState extends State<LiveJsonEditorPage> {
  late final TextEditingController _jsonController;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<DynamicFormBloc>().state;
    String initialJson = '';
    if (currentState.config != null) {
      final configMap = {
        'title': currentState.config!.title,
        'submitButton': currentState.config!.submitButton,
        'fields': currentState.config!.fields.map((f) => {
          'id': f.id,
          'type': f.type.name,
          'label': f.label,
          'placeholder': f.placeholder,
          'required': f.required,
          if (f.minLength != null) 'minLength': f.minLength,
          if (f.maxLength != null) 'maxLength': f.maxLength,
          if (f.min != null) 'min': f.min,
          if (f.max != null) 'max': f.max,
          if (f.divisions != null) 'divisions': f.divisions,
          if (f.options.isNotEmpty) 'options': f.options,
          if (f.allowedExtensions.isNotEmpty) 'allowedExtensions': f.allowedExtensions,
          if (f.dependsOn != null) 'dependsOn': f.dependsOn,
          if (f.optionsMap.isNotEmpty) 'optionsMap': f.optionsMap,
        }).toList(),
      };
      const encoder = JsonEncoder.withIndent('  ');
      initialJson = encoder.convert(configMap);
    }
    _jsonController = TextEditingController(text: initialJson);
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _applyJson() {
    final raw = _jsonController.text.trim();
    try {
      jsonDecode(raw); // Check valid syntax
      setState(() => _parseError = null);
      context.read<DynamicFormBloc>().add(LoadCustomJsonConfigEvent(raw));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _parseError = 'Invalid JSON: ${e.toString()}');
    }
  }

  void _resetToDefault() {
    context.read<DynamicFormBloc>().add(LoadDefaultFormConfigEvent());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('JSON Schema Editor', style: AppTypography.headlineLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _resetToDefault,
            child: Text(
              'Reset Default',
              style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit or paste any form configuration JSON to test runtime generation:',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 10),
              if (_parseError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Text(
                    _parseError!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _jsonController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TactileBounce(
                onTap: _applyJson,
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.secondaryLight]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('Apply Runtime Schema', style: AppTypography.labelLarge.copyWith(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
