import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../rate_limiter/rate_limiter.dart';

// Auth feature
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Feed feature
import '../../features/feed/data/datasources/feed_local_data_source.dart';
import '../../features/feed/data/repositories/feed_repository_impl.dart';
import '../../features/feed/domain/repositories/feed_repository.dart';
import '../../features/feed/domain/usecases/feed_interaction_usecases.dart';
import '../../features/feed/domain/usecases/get_feed_posts_usecase.dart';
import '../../features/feed/domain/usecases/get_stories_usecase.dart';
import '../../features/feed/presentation/bloc/feed_bloc.dart';

// Reels feature
import '../../features/reels/data/datasources/reels_local_data_source.dart';
import '../../features/reels/data/datasources/reels_remote_data_source.dart';
import '../../features/reels/data/repositories/reels_repository_impl.dart';
import '../../features/reels/domain/repositories/reels_repository.dart';
import '../../features/reels/domain/usecases/reels_usecases.dart';
import '../../features/reels/presentation/bloc/reels_bloc.dart';

// Dynamic Form feature
import '../../features/dynamic_form/data/datasources/form_local_data_source.dart';
import '../../features/dynamic_form/data/datasources/form_remote_data_source.dart';
import '../../features/dynamic_form/data/repositories/form_repository_impl.dart';
import '../../features/dynamic_form/domain/repositories/form_repository.dart';
import '../../features/dynamic_form/domain/usecases/form_usecases.dart';
import '../../features/dynamic_form/presentation/bloc/dynamic_form_bloc.dart';

// Auth remote datasource
import '../../features/auth/data/datasources/auth_remote_data_source.dart';

// Feed remote datasource
import '../../features/feed/data/datasources/feed_remote_data_source.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ----------------------------------------------------
  // External & Core Singletons
  // ----------------------------------------------------
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Data Flow Rate Limiter
  sl.registerLazySingleton<RateLimiter>(() => RateLimiter(
        maxRequests: 5,
        window: const Duration(seconds: 3),
      ));

  // ----------------------------------------------------
  // Auth Feature
  // ----------------------------------------------------
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        registerUseCase: sl(),
        getCurrentUserUseCase: sl(),
        logoutUseCase: sl(),
        rateLimiter: sl(),
      ));

  // ----------------------------------------------------
  // Feed Feature
  // ----------------------------------------------------
  sl.registerLazySingleton<FeedLocalDataSource>(
    () => FeedLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<FeedRemoteDataSource>(
    () => FeedRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<FeedRepository>(
    () => FeedRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      authLocalDataSource: sl(),
      rateLimiter: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetStoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetFeedPostsUseCase(sl()));
  sl.registerLazySingleton(() => ToggleLikePostUseCase(sl()));
  sl.registerLazySingleton(() => ToggleBookmarkPostUseCase(sl()));
  sl.registerLazySingleton(() => AddCommentUseCase(sl()));

  sl.registerFactory(() => FeedBloc(
        getStoriesUseCase: sl(),
        getFeedPostsUseCase: sl(),
        toggleLikePostUseCase: sl(),
        toggleBookmarkPostUseCase: sl(),
        addCommentUseCase: sl(),
      ));

  // ----------------------------------------------------
  // Reels Feature
  // ----------------------------------------------------
  sl.registerLazySingleton<ReelsLocalDataSource>(
    () => ReelsLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<ReelsRemoteDataSource>(
    () => ReelsRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ReelsRepository>(
    () => ReelsRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      authLocalDataSource: sl(),
      rateLimiter: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetReelsUseCase(sl()));
  sl.registerLazySingleton(() => ToggleLikeReelUseCase(sl()));
  sl.registerLazySingleton(() => AddReelCommentUseCase(sl()));
  sl.registerLazySingleton(() => ShareReelUseCase(sl()));

  sl.registerFactory(() => ReelsBloc(
        getReelsUseCase: sl(),
        toggleLikeReelUseCase: sl(),
        addReelCommentUseCase: sl(),
        shareReelUseCase: sl(),
      ));

  // ----------------------------------------------------
  // Dynamic Form Feature
  // ----------------------------------------------------
  sl.registerLazySingleton<FormLocalDataSource>(
    () => FormLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<FormRemoteDataSource>(
    () => FormRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<FormRepository>(
    () => FormRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      rateLimiter: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetDefaultFormConfigUseCase(sl()));
  sl.registerLazySingleton(() => ParseCustomConfigUseCase(sl()));
  sl.registerLazySingleton(() => SubmitFormUseCase(sl()));

  sl.registerFactory(() => DynamicFormBloc(
        getDefaultFormConfigUseCase: sl(),
        parseCustomConfigUseCase: sl(),
        submitFormUseCase: sl(),
      ));
}
