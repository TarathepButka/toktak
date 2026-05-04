// features/auth/domain/usecases/login_with_line_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/auth/data/models/user_model.dart';
import 'package:toktak/features/auth/domain/repositories/auth_repository.dart';

/// Encapsulates the LINE login business action.
class LoginWithLineUseCase {
  final AuthRepository _repository;

  const LoginWithLineUseCase(this._repository);

  Future<Either<Failure, AuthResponse>> call() =>
      _repository.loginWithLine();
}
