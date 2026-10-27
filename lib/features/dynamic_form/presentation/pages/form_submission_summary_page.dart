import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/tactile_bounce.dart';
import '../../domain/entities/form_submission_entity.dart';

class FormSubmissionSummaryPage extends StatelessWidget {
  final FormSubmissionEntity submission;

  const FormSubmissionSummaryPage({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Submission Summary', style: AppTypography.headlineLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 54),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Data Collected Successfully',
                style: AppTypography.displayLarge.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Captured for "${submission.formTitle}" at ${DateFormat.yMMMd().add_jm().format(submission.submittedAt)}',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Collected key-value pairs in Taste Skill card
              GlassContainer(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Submitted Fields Payload', style: AppTypography.headlineMedium.copyWith(fontSize: 16)),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    ...submission.submittedValues.entries.map((entry) {
                      final keyLabel = entry.key.replaceAll('_', ' ').toUpperCase();
                      final valStr = entry.value == null
                          ? 'Not provided'
                          : entry.value is List
                              ? (entry.value as List).join(', ')
                              : entry.value.toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                keyLabel,
                                style: AppTypography.tagCaps.copyWith(color: AppColors.secondaryLight),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                valStr,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: entry.value == null ? AppColors.textMuted : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Done button
              TactileBounce(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('Back to Form', style: AppTypography.labelLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
