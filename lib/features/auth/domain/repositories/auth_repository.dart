// features/auth/domain/repositories/auth_repository.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> loginWithGoogle();

  Future<Either<Failure, AuthResponse>> loginWithLine();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserModel>> getCurrentUser();
  bool get isLoggedIn;
}
