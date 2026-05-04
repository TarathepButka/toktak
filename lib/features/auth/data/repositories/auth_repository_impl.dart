// features/auth/data/repositories/auth_repository_impl.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:toktak/core/constants/api_endpoints.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/core/network/api_client.dart';
import 'package:toktak/core/storage/local_storage_service.dart';
import 'package:toktak/features/auth/data/models/user_model.dart';
import 'package:toktak/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final LocalStorageService _storage;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required LocalStorageService storage,
    required GoogleSignIn googleSignIn,
  })  : _apiClient = apiClient,
        _storage = storage,
        _googleSignIn = googleSignIn;

  @override
  bool get isLoggedIn => _storage.isLoggedIn;

  @override
  Future<Either<Failure, AuthResponse>> loginWithGoogle() async {
    try {
      print('[AUTH] Starting Google Sign-In...');
      final googleUser = await _googleSignIn.signIn();
      print('[AUTH] Google Sign-In result: $googleUser');

      if (googleUser == null) {
        print('[AUTH] Google sign-in cancelled by user');
        return left(const Failure.auth(message: 'Google sign-in cancelled'));
      }

      print('[AUTH] Getting Google authentication...');
      final googleAuth = await googleUser.authentication;
      print('[AUTH] Google auth obtained');

      final idToken = googleAuth.idToken;
      print(
          '[AUTH] ID Token: ${idToken != null ? '${idToken.substring(0, 20)}...' : 'null'}');

      if (idToken == null) {
        print('[AUTH] Failed to get Google ID token');
        return left(
            const Failure.auth(message: 'Failed to get Google ID token'));
      }

      // Send token to backend for verification
      print('[AUTH] Sending token to backend: ${ApiEndpoints.authGoogle}');
      final response = await _apiClient.dio.post(
        ApiEndpoints.authGoogle,
        data: {'id_token': idToken},
      );
      print('[AUTH] Backend response status: ${response.statusCode}');

      final authResponse = AuthResponse.fromJson(response.data);

      // Save tokens locally
      await _storage.saveAuthToken(authResponse.accessToken);
      await _storage.saveRefreshToken(authResponse.refreshToken);
      await _storage.saveUserProfile(authResponse.user.toJson());

      print('[AUTH] Google login successful, user: ${authResponse.user.id}');

      return right(authResponse);
    } on DioException catch (e) {
      print(
          '[AUTH] DioException: ${e.message}, code: ${e.response?.statusCode}');
      return left(Failure.server(
        message: e.response?.data?['message'] ?? 'Server error',
        code: e.response?.statusCode ?? 500,
      ));
    } catch (e) {
      print('[AUTH] Exception: $e');
      return left(Failure.auth(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> loginWithLine() async {
    try {
      print('[AUTH] Starting LINE login...');

      // Add timeout to prevent hanging
      final result = await LineSDK.instance.login(
        scopes: ['profile', 'openid', 'email'],
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('[AUTH] LINE login timed out after 60 seconds');
          throw TimeoutException('LINE login timeout');
        },
      );

      print('[AUTH] LINE login dialog closed by user');
      print('[AUTH] Result object received successfully');

      // Check if user profile exists
      if (result.userProfile == null) {
        print('[AUTH] LINE userProfile is null');
        return left(
            const Failure.auth(message: 'Failed to get LINE user profile'));
      }

      print(
          '[AUTH] LINE login success — userID: ${result.userProfile?.userId}');

      final accessToken = result.accessToken.value;
      if (accessToken.isEmpty) {
        print('[AUTH] LINE accessToken is empty');
        return left(const Failure.auth(message: 'LINE access token is empty'));
      }

      final tokenPreview = accessToken.length > 20
          ? '${accessToken.substring(0, 20)}...'
          : accessToken;
      print('[AUTH] LINE Access Token obtained: $tokenPreview');

      // Send token to backend for verification
      print('[AUTH] Posting to backend: ${ApiEndpoints.authLine}');
      final response = await _apiClient.dio.post(
        ApiEndpoints.authLine,
        data: {'access_token': accessToken},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('[AUTH] Backend request timed out');
          throw TimeoutException('Backend request timeout');
        },
      );

      print('[AUTH] Backend response status: ${response.statusCode}');

      final authResponse = AuthResponse.fromJson(response.data);

      // Save tokens locally
      await _storage.saveAuthToken(authResponse.accessToken);
      await _storage.saveRefreshToken(authResponse.refreshToken);
      await _storage.saveUserProfile(authResponse.user.toJson());

      print('[AUTH] LINE login successful — user: ${authResponse.user.id}');

      return right(authResponse);
    } on TimeoutException catch (e) {
      print('[AUTH] TimeoutException: ${e.message}');

      return left(Failure.auth(message: 'Login timeout: ${e.message}'));
    } on PlatformException catch (e) {
      // LINE SDK specific errors
      // Code 3003 = user cancelled login
      print(
          '[AUTH] LINE PlatformException — code: ${e.code}, msg: ${e.message}');
      if (e.code == '3003') {
        // User cancelled — treat as a soft cancel, not a hard error
        print('[AUTH] User cancelled LINE login');
        return left(const Failure.auth(message: 'LINE login was cancelled'));
      }
      return left(Failure.auth(
        message:
            'LINE login failed (${e.code}): ${e.message ?? 'Unknown error'}',
      ));
    } on DioException catch (e) {
      print(
          '[AUTH] DioException: ${e.message}, status: ${e.response?.statusCode}');
      print('[AUTH] DioException response body: ${e.response?.data}');
      return left(Failure.server(
        message: e.response?.data?['message'] as String? ?? 'Server error',
        code: e.response?.statusCode ?? 500,
      ));
    } catch (e, st) {
      print('[AUTH] Unexpected LINE error: $e');
      print('[AUTH] Stack trace: $st');
      return left(Failure.auth(message: 'LINE login failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _googleSignIn.signOut();
      await _storage.clearAll();
      return right(null);
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> getCurrentUser() async {
    try {
      // Try local first
      final cached = _storage.getUserProfile();
      if (cached != null) {
        return right(UserModel.fromJson(cached));
      }
      return left(const Failure.auth(message: 'No user found'));
    } catch (e) {
      return left(Failure.cache(message: e.toString()));
    }
  }
}
