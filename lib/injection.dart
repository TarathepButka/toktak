// injection.dart — Dependency Injection setup
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:toktak/core/network/api_client.dart';
import 'package:toktak/core/storage/local_storage_service.dart';

// ─── Auth ────────────────────────────────────────────────────
import 'package:toktak/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:toktak/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:toktak/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:toktak/features/auth/domain/repositories/auth_repository.dart';
import 'package:toktak/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:toktak/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:toktak/features/auth/domain/usecases/login_with_line_usecase.dart';
import 'package:toktak/features/auth/domain/usecases/logout_usecase.dart';
import 'package:toktak/features/auth/presentation/bloc/auth_bloc.dart';

// ─── Feed ────────────────────────────────────────────────────
import 'package:toktak/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:toktak/features/feed/data/datasources/feed_remote_datasource_impl.dart';
import 'package:toktak/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:toktak/features/feed/domain/repositories/feed_repository.dart';
import 'package:toktak/features/feed/domain/usecases/get_feed_videos_usecase.dart';
import 'package:toktak/features/feed/domain/usecases/like_video_usecase.dart';
import 'package:toktak/features/feed/presentation/bloc/feed_bloc.dart';

// ─── Search ──────────────────────────────────────────────────
import 'package:toktak/features/search/data/datasources/search_remote_datasource.dart';
import 'package:toktak/features/search/data/datasources/search_remote_datasource_impl.dart';
import 'package:toktak/features/search/data/repositories/search_repository_impl.dart';
import 'package:toktak/features/search/domain/repositories/search_repository.dart';
import 'package:toktak/features/search/domain/usecases/search_videos_usecase.dart';
import 'package:toktak/features/search/presentation/bloc/search_bloc.dart';

// ─── Profile ─────────────────────────────────────────────────
import 'package:toktak/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:toktak/features/profile/data/datasources/profile_remote_datasource_impl.dart';
import 'package:toktak/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:toktak/features/profile/domain/repositories/profile_repository.dart';
import 'package:toktak/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:toktak/features/profile/presentation/bloc/profile_bloc.dart';

// ─── Upload ──────────────────────────────────────────────────
import 'package:toktak/features/upload/data/datasources/upload_remote_datasource.dart';
import 'package:toktak/features/upload/data/datasources/upload_remote_datasource_impl.dart';
import 'package:toktak/features/upload/data/repositories/upload_repository_impl.dart';
import 'package:toktak/features/upload/domain/repositories/upload_repository.dart';
import 'package:toktak/features/upload/domain/usecases/upload_video_usecase.dart';
import 'package:toktak/features/upload/presentation/bloc/upload_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ─── Core ───────────────────────────────────────────────────
  getIt.registerLazySingleton<LocalStorageService>(() => LocalStorageService());
  getIt.registerLazySingleton<ApiClient>(
      () => ApiClient(getIt<LocalStorageService>()));
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
      ));

  // ─── Auth — DataSources ─────────────────────────────────────
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  // ─── Auth — Repositories ────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      storage: getIt<LocalStorageService>(),
      googleSignIn: getIt<GoogleSignIn>(),
    ),
  );

  // ─── Auth — UseCases ────────────────────────────────────────
  getIt.registerLazySingleton(() => LoginWithGoogleUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LoginWithLineUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt<AuthRepository>()));

  // ─── Auth — BLoC ────────────────────────────────────────────
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  // ─── Feed — DataSources ─────────────────────────────────────
  getIt.registerLazySingleton<FeedRemoteDataSource>(
    () => FeedRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  // ─── Feed — Repositories ────────────────────────────────────
  getIt.registerLazySingleton<FeedRepository>(
    () => FeedRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      storage: getIt<LocalStorageService>(),
    ),
  );

  // ─── Feed — UseCases ────────────────────────────────────────
  getIt.registerLazySingleton(() => GetFeedVideosUseCase(getIt<FeedRepository>()));
  getIt.registerLazySingleton(() => LikeVideoUseCase(getIt<FeedRepository>()));
  getIt.registerLazySingleton(() => UnlikeVideoUseCase(getIt<FeedRepository>()));

  // ─── Feed — BLoC ────────────────────────────────────────────
  getIt.registerFactory<FeedBloc>(
    () => FeedBloc(
      feedRepository: getIt<FeedRepository>(),
      storage: getIt<LocalStorageService>(),
    ),
  );

  // ─── Search — DataSources ───────────────────────────────────
  getIt.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  // ─── Search — Repositories ──────────────────────────────────
  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(getIt<SearchRemoteDataSource>()),
  );

  // ─── Search — UseCases ──────────────────────────────────────
  getIt.registerLazySingleton(() => SearchVideosUseCase(getIt<SearchRepository>()));

  // ─── Search — BLoC ──────────────────────────────────────────
  getIt.registerFactory<SearchBloc>(
    () => SearchBloc(repository: getIt<SearchRepository>()),
  );

  // ─── Profile — DataSources ──────────────────────────────────
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  // ─── Profile — Repositories ─────────────────────────────────
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ProfileRemoteDataSource>()),
  );

  // ─── Profile — UseCases ─────────────────────────────────────
  getIt.registerLazySingleton(() => GetProfileUseCase(getIt<ProfileRepository>()));

  // ─── Profile — BLoC ─────────────────────────────────────────
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(getProfileUseCase: getIt<GetProfileUseCase>()),
  );

  // ─── Upload — DataSources ────────────────────────────────────
  getIt.registerLazySingleton<UploadRemoteDataSource>(
    () => UploadRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  // ─── Upload — Repositories ───────────────────────────────────
  getIt.registerLazySingleton<UploadRepository>(
    () => UploadRepositoryImpl(getIt<UploadRemoteDataSource>()),
  );

  // ─── Upload — UseCases ───────────────────────────────────────
  getIt.registerLazySingleton(() => UploadVideoUseCase(getIt<UploadRepository>()));

  // ─── Upload — BLoC ───────────────────────────────────────────
  getIt.registerFactory<UploadBloc>(
    () => UploadBloc(uploadVideoUseCase: getIt<UploadVideoUseCase>()),
  );
}
