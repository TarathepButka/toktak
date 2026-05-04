// features/auth/domain/usecases/get_current_user_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/auth/data/models/user_model.dart';
import 'package:toktak/features/auth/domain/repositories/auth_repository.dart';

/// Retrieves the currently authenticated user from local cache.
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<Either<Failure, UserModel>> call() =>
      _repository.getCurrentUser();
}
