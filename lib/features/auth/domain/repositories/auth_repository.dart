import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> register({
    required String fullName,
    required String mobile,
    required String rawPassword,
    required String email,
  });

  Future<UserEntity> login({
    required String mobile,
    required String rawPassword,
  });

  Future<UserEntity?> getCurrentUser();

  Future<void> logout();
}
