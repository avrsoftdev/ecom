import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/admin/data/datasources/admin_firestore_datasource.dart';
import '../../features/admin/data/datasources/admin_storage_datasource.dart';
import '../../features/admin/data/datasources/product_admin_remote_datasource.dart';
import '../../features/admin/data/datasources/remote_config_datasource.dart';
import '../../features/admin/data/repositories/admin_banner_repository_impl.dart';
import '../../features/admin/data/repositories/admin_category_repository_impl.dart';
import '../../features/admin/data/repositories/admin_customer_repository_impl.dart';
import '../../features/admin/data/repositories/admin_dashboard_repository_impl.dart';
import '../../features/admin/data/repositories/admin_order_repository_impl.dart';
import '../../features/admin/data/repositories/admin_product_repository_impl.dart';
import '../../features/admin/data/repositories/admin_settings_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_banner_repository.dart';
import '../../features/admin/domain/repositories/admin_category_repository.dart';
import '../../features/admin/domain/repositories/admin_customer_repository.dart';
import '../../features/admin/domain/repositories/admin_dashboard_repository.dart';
import '../../features/admin/domain/repositories/admin_order_repository.dart';
import '../../features/admin/domain/repositories/admin_product_repository.dart';
import '../../features/admin/domain/repositories/admin_settings_repository.dart';
import '../../features/admin/presentation/cubits/dashboard_cubit.dart';
import '../../features/admin/presentation/cubits/product_admin_cubit.dart';
import '../../features/admin/presentation/cubits/settings_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/usecases/get_user_role_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_data_usecase.dart';
import '../../features/home/presentation/cubits/home_cubit.dart';
import '../../features/product/data/datasources/product_remote_datasource.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/get_products_usecase.dart';
import '../../features/product/presentation/cubits/product_cubit.dart';
import '../network/network_info.dart';
import '../theme/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    clientId: 'temp-development-client-id',
  );

  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(getIt()));

  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  getIt.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);
  getIt.registerSingleton<GoogleSignIn>(googleSignIn);

  getIt.registerSingleton<Dio>(Dio());
  getIt.registerSingleton<Connectivity>(Connectivity());

  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt()),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: getIt(),
      firestore: getIt(),
      googleSignIn: getIt(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt(),
      sharedPreferences: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => SignInUseCase(getIt()));
  getIt.registerLazySingleton(() => SignUpUseCase(getIt()));
  getIt.registerLazySingleton(() => SignInWithGoogleUseCase(getIt()));
  getIt.registerLazySingleton(() => SignOutUseCase(getIt()));
  getIt.registerLazySingleton(() => CheckAuthStatusUseCase(getIt()));
  getIt.registerLazySingleton(() => GetUserRoleUseCase(getIt()));

  getIt.registerFactory(
    () => AuthCubit(
      signInUseCase: getIt(),
      signUpUseCase: getIt(),
      signInWithGoogleUseCase: getIt(),
      signOutUseCase: getIt(),
      checkAuthStatusUseCase: getIt(),
      getUserRoleUseCase: getIt(),
    ),
  );

  getIt.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(firestore: getIt()),
  );

  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => GetHomeDataUseCase(getIt()));

  getIt.registerFactory(
    () => HomeCubit(getHomeDataUseCase: getIt()),
  );

  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(firestore: getIt()),
  );

  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => GetProductsUseCase(getIt()));

  getIt.registerFactory(
    () => ProductCubit(getProductsUseCase: getIt()),
  );

  getIt.registerLazySingleton(
    () => AdminFirestoreDataSource(firestore: getIt()),
  );
  getIt.registerLazySingleton<RemoteConfigDataSource>(
    () => RemoteConfigDataSource(),
  );
  getIt.registerLazySingleton<AdminStorageDataSource>(
    () => AdminStorageDataSourceImpl(storage: getIt()),
  );
  getIt.registerLazySingleton(
    () => ProductAdminRemoteDataSource(firestore: getIt()),
  );

  getIt.registerLazySingleton<AdminDashboardRepository>(
    () => AdminDashboardRepositoryImpl(remote: getIt(), networkInfo: getIt()),
  );
  getIt.registerLazySingleton<AdminProductRepository>(
    () => AdminProductRepositoryImpl(
      remote: getIt(),
      storage: getIt(),
      networkInfo: getIt(),
    ),
  );
  getIt.registerLazySingleton<AdminOrderRepository>(
    () => AdminOrderRepositoryImpl(remote: getIt(), networkInfo: getIt()),
  );
  getIt.registerLazySingleton<AdminCategoryRepository>(
    () => AdminCategoryRepositoryImpl(remote: getIt(), networkInfo: getIt()),
  );
  getIt.registerLazySingleton<AdminBannerRepository>(
    () => AdminBannerRepositoryImpl(
      remote: getIt(),
      storage: getIt(),
      networkInfo: getIt(),
    ),
  );
  getIt.registerLazySingleton<AdminCustomerRepository>(
    () => AdminCustomerRepositoryImpl(remote: getIt(), networkInfo: getIt()),
  );
  getIt.registerLazySingleton<AdminSettingsRepository>(
    () => AdminSettingsRepositoryImpl(
      remote: getIt(),
      remoteConfig: getIt(),
      networkInfo: getIt(),
    ),
  );

  getIt.registerFactory(() => DashboardCubit(getIt()));
  getIt.registerFactory(() => ProductAdminCubit(getIt()));
  getIt.registerFactory(() => SettingsCubit(getIt()));
}
