import '../models/login_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository authRepository;

  LoginUseCase(this.authRepository);

  Future<LoginResponse> execute(String username, String password) {
    return authRepository.login(username, password);
  }
}
