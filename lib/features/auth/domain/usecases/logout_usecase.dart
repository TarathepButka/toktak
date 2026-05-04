// features/auth/domain/usecases/logout_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/auth/domain/repositories/auth_repository.dart';

/// Clears session and social sign-in state.
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.logout();
}
