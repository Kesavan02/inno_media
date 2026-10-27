import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource? remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  @override
  Future<UserEntity> register({
    required String fullName,
    required String mobile,
    required String rawPassword,
    required String email,
  }) async {
    try {
      final userModel = await localDataSource.register(
        fullName: fullName,
        mobile: mobile,
        rawPassword: rawPassword,
        email: email,
      );

      // Asynchronously sync user profile document to Firestore
      if (remoteDataSource != null) {
        remoteDataSource!.syncUserToFirestore(userModel).catchError((_) {});
      }

      return userModel.toEntity();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> login({
    required String mobile,
    required String rawPassword,
  }) async {
    try {
      final userModel = await localDataSource.login(
        mobile: mobile,
        rawPassword: rawPassword,
      );

      // Keep user's Firestore profile up to date on login
      if (remoteDataSource != null) {
        remoteDataSource!.syncUserToFirestore(userModel).catchError((_) {});
      }

      return userModel.toEntity();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final userModel = await localDataSource.getCurrentUser();
      return userModel?.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await localDataSource.logout();
  }
}
