// features/profile/data/repositories/profile_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/exceptions.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:toktak/features/profile/data/models/profile_model.dart';
import 'package:toktak/features/profile/domain/entities/profile.dart';
import 'package:toktak/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  const ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    try {
      final model = await _remoteDataSource.getProfile(userId);
      return right(model.toDomain());
    } on ServerException catch (e) {
      return left(Failure.server(message: e.message, code: e.statusCode));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }
}
