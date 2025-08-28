import 'package:get_it/get_it.dart';
import 'core/services/storage_service.dart';
import 'app/app_provider.dart';
import 'features/wallet/wallet_provider.dart';

/// Service locator instance
final GetIt getIt = GetIt.instance;

/// Configure all dependencies for the app
Future<void> configureDependencies() async {
  // Core Services
  getIt.registerLazySingleton<IStorageService>(() => StorageService());

  // Initialize storage service
  final storageService = getIt<IStorageService>();
  if (storageService is StorageService) {
    await storageService.init();
  }

  // Feature Providers
  getIt.registerLazySingleton<WalletProvider>(() => WalletProvider());

  getIt.registerLazySingleton<AppProvider>(
    () => AppProvider(getIt<IStorageService>()),
  );
}

/// Reset dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
