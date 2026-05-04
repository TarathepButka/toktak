// features/profile/data/datasources/profile_remote_datasource.dart
import 'package:toktak/features/profile/data/models/profile_model.dart';

/// Contract for all remote profile operations.
abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile(String userId);
}
