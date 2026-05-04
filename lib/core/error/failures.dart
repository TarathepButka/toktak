// core/error/failures.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.server({
    required String message,
    @Default(500) int code,
  }) = ServerFailure;

  const factory Failure.network({
    @Default('No internet connection') String message,
  }) = NetworkFailure;

  const factory Failure.cache({
    @Default('Cache error') String message,
  }) = CacheFailure;

  const factory Failure.auth({
    @Default('Authentication failed') String message,
  }) = AuthFailure;

  const factory Failure.unknown({
    @Default('An unexpected error occurred') String message,
  }) = UnknownFailure;
}
