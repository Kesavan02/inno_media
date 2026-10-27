import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/app_navigation_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tactile_bounce.dart';
import '../bloc/dynamic_form_bloc.dart';
import '../bloc/dynamic_form_event.dart';
import '../bloc/dynamic_form_state.dart';
import '../widgets/field_renderer_factory.dart';
import 'form_submission_summary_page.dart';
import 'live_json_editor_page.dart';

class DynamicFormPage extends StatelessWidget {
  const DynamicFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = AppNavigationScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: nav != null && nav.canBacktrack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: () => nav.backtrack(),
              )
            : null,
        title: Text('Dynamic Form', style: AppTypography.displayLarge.copyWith(fontSize: 22)),
        actions: [
          // Live JSON Schema viewer/editor
          TactileBounce(
            key: const Key('btn_open_schema_editor'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LiveJsonEditorPage()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondaryLight.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code_rounded, size: 16, color: AppColors.secondaryLight),
                  const SizedBox(width: 6),
                  Text(
                    'JSON Schema',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            key: const Key('btn_reset_form'),
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Reset Form',
            onPressed: () {
              context.read<DynamicFormBloc>().add(ResetFormEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<DynamicFormBloc, DynamicFormState>(
        listener: (context, state) {
          if (state.toastMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.toastMessage!, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                backgroundColor: state.fieldErrors.isNotEmpty ? AppColors.error : AppColors.surfaceElevated,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 3),
              ),
            );
          }

          if (state.status == FormStatus.success && state.submissionResult != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FormSubmissionSummaryPage(submission: state.submissionResult!),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == FormStatus.loading && state.config == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state.status == FormStatus.error && state.config == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load form', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.read<DynamicFormBloc>().add(LoadDefaultFormConfigEvent()),
                    child: const Text('Reload'),
                  ),
                ],
              ),
            );
          }

          final config = state.config;
          if (config == null) return const SizedBox.shrink();

          // Filter fields dynamically based on conditional rules (visibleIf)
          final visibleFields = config.fields.where((f) => f.isVisible(state.formValues)).toList();

          return Column(
            children: [
                // Scrollable Form Fields
                Expanded(
                  child: ListView(

                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Form Title & Subtitle Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dynamic_form_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(config.title, style: AppTypography.displayMedium.copyWith(fontSize: 20)),
                              Text('JSON-Driven Runtime Schema Engine', style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Render each visible field
                    ...visibleFields.map((field) {
                      final val = state.formValues[field.id];
                      final err = state.fieldErrors[field.id];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: FieldRendererFactory(
                            key: Key('field_${field.id}'),
                            field: field,
                            value: val,
                            errorText: err,
                            allFormValues: state.formValues,
                            onChanged: (newVal) {
                              context.read<DynamicFormBloc>().add(
                                    FormFieldValueChangedEvent(
                                      fieldId: field.id,
                                      value: newVal,
                                    ),
                                  );
                            },
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Bottom Sticky Submit Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
                ),
                child: SafeArea(
                  top: false,
                  child: TactileBounce(
                    key: const Key('btn_submit_form'),
                    onTap: state.status == FormStatus.submitting
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            context.read<DynamicFormBloc>().add(SubmitDynamicFormEvent());
                          },
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: state.status == FormStatus.submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  config.submitButton,
                                  style: AppTypography.labelLarge.copyWith(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

