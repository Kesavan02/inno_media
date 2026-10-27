import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<UserEntity> call({required String mobile, required String rawPassword}) {
    return repository.login(mobile: mobile, rawPassword: rawPassword);
  }
}
