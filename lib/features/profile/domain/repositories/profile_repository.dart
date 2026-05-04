// features/profile/domain/repositories/profile_repository.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/profile/domain/entities/profile.dart';

/// Domain contract for profile data operations.
abstract class ProfileRepository {
  /// Fetch the profile for [userId].
  /// If [userId] is null, returns the current authenticated user's profile.
  Future<Either<Failure, Profile>> getProfile(String userId);
}
