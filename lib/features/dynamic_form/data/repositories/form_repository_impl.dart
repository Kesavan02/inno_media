import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/rate_limiter/rate_limiter.dart';
import '../../domain/entities/form_config_entity.dart';
import '../../domain/entities/form_submission_entity.dart';
import '../../domain/repositories/form_repository.dart';
import '../datasources/form_local_data_source.dart';
import '../datasources/form_remote_data_source.dart';

class FormRepositoryImpl implements FormRepository {
  final FormLocalDataSource localDataSource;
  final FormRemoteDataSource? remoteDataSource;
  final RateLimiter rateLimiter;

  FormRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
    required this.rateLimiter,
  });

  @override
  Future<FormConfigEntity> getDefaultFormConfig() async {
    try {
      return await localDataSource.getDefaultFormConfig();
    } catch (e) {
      throw ServerFailure('Failed to load form configuration: ${e.toString()}');
    }
  }

  @override
  FormConfigEntity parseCustomConfig(String jsonString) {
    try {
      return localDataSource.parseCustomJsonConfig(jsonString);
    } catch (e) {
      throw ValidationFailure('Invalid JSON configuration syntax: ${e.toString()}');
    }
  }

  @override
  Future<FormSubmissionEntity> submitForm({
    required String formTitle,
    required Map<String, dynamic> formValues,
  }) async {
    try {
      // Enforce rate limiter on data flow (max 1 submission per window)
      rateLimiter.acquire('form_submission');

      final submission = FormSubmissionEntity(
        formTitle: formTitle,
        submittedValues: formValues,
        submittedAt: DateTime.now(),
      );

      final submissionPayload = {
        'id': 'sub_${submission.submittedAt.millisecondsSinceEpoch}',
        'formTitle': formTitle,
        'values': formValues,
        'submittedAt': submission.submittedAt.toIso8601String(),
      };

      await localDataSource.saveFormSubmission(submissionPayload);

      // Asynchronously sync to Cloud Firestore in structural format
      if (remoteDataSource != null) {
        // Fire and catch errors so local flow is never interrupted
        remoteDataSource!.submitFormToFirestore(submissionPayload).catchError((_) {});
      }

      return submission;
    } on RateLimitException catch (e) {
      throw RateLimitFailure(e.message, e.retryAfter);
    } catch (e) {
      throw ServerFailure('Form submission failed: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSubmissionHistory() {
    return localDataSource.getSubmissionHistory();
  }
}
