// core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:toktak/core/constants/api_endpoints.dart';
import 'package:toktak/core/network/auth_interceptor.dart';
import 'package:toktak/core/storage/local_storage_service.dart';

class ApiClient {
  late final Dio dio;
  final LocalStorageService _storage;

  ApiClient(this._storage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(_storage, dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('🌐 $obj'),
      ),
    ]);
  }
}
