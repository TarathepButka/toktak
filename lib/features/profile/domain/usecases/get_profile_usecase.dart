// features/profile/domain/usecases/get_profile_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/profile/domain/entities/profile.dart';
import 'package:toktak/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository _repository;

  const GetProfileUseCase(this._repository);

  Future<Either<Failure, Profile>> call(String userId) =>
      _repository.getProfile(userId);
}
