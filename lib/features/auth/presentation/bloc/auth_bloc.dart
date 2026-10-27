import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/rate_limiter/rate_limiter.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LogoutUseCase logoutUseCase;
  final RateLimiter rateLimiter;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.getCurrentUserUseCase,
    required this.logoutUseCase,
    required this.rateLimiter,
  }) : super(AuthInitial()) {
    on<CheckAuthSessionEvent>(_onCheckSession);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<RegisterSubmittedEvent>(_onRegisterSubmitted);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onCheckSession(
    CheckAuthSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking session...'));
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Rate limit: max 4 attempts per 5s to prevent brute-force abuse
    try {
      rateLimiter.acquire('auth_attempt');
    } catch (e) {
      emit(const AuthError('Too many login attempts. Please wait 3 seconds.'));
      return;
    }

    emit(const AuthLoading(message: 'Authenticating securely...'));
    try {
      final user = await loginUseCase(
        mobile: event.mobile.trim(),
        rawPassword: event.password,
      );
      emit(Authenticated(user));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    } catch (e) {
      emit(AuthError('Authentication error: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      rateLimiter.acquire('auth_attempt');
    } catch (e) {
      emit(const AuthError('Too many attempts. Please slow down.'));
      return;
    }

    emit(const AuthLoading(message: 'Creating your account...'));
    try {
      final user = await registerUseCase(
        fullName: event.fullName.trim(),
        mobile: event.mobile.trim(),
        rawPassword: event.password,
        email: event.email.trim(),
      );
      emit(Authenticated(user));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    } catch (e) {
      emit(AuthError('Registration error: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Logging out...'));
    await logoutUseCase();
    emit(Unauthenticated());
  }
}
