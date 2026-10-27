import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<UserEntity> call({
    required String fullName,
    required String mobile,
    required String rawPassword,
    required String email,
  }) {
    return repository.register(
      fullName: fullName,
      mobile: mobile,
      rawPassword: rawPassword,
      email: email,
    );
  }
}
