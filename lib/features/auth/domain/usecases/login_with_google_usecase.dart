// features/auth/domain/usecases/login_with_google_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/auth/data/models/user_model.dart';
import 'package:toktak/features/auth/domain/repositories/auth_repository.dart';

/// Encapsulates the Google login business action.
/// BLoC calls this instead of talking to the repository directly.
class LoginWithGoogleUseCase {
  final AuthRepository _repository;

  const LoginWithGoogleUseCase(this._repository);

  Future<Either<Failure, AuthResponse>> call() =>
      _repository.loginWithGoogle();
}
