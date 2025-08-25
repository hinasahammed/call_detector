import 'package:call_detector/data/local/local_storage_service.dart';
import 'package:call_detector/data/network/network_api_service.dart';
import 'package:call_detector/repository/homeRepository/home_repository.dart';
import 'package:call_detector/repository/loginRepsoitory/login_repository.dart';
import 'package:call_detector/repository/splashRepository/splash_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Should be initialized in main.dart');
});

final networkApiServiceProvider = Provider((ref) {
  return NetworkApiService();
});
final localStorageServiceProvider = Provider((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(sharedPreferences: sharedPreferences);
});

final homeRepositoryProvider = Provider((ref) {
  final networkApiService = ref.watch(networkApiServiceProvider);
  return HomeRepository(networkApiService: networkApiService);
});

final loginRepositoryProvider = Provider((ref) {
  final networkApiService = ref.watch(networkApiServiceProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);
  return LoginRepository(
    networkApiService: networkApiService,
    localStorageService: localStorageService,
  );
});

final splashRepositoryProvider = Provider((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return SplashRepository(localStorageService: localStorageService);
});
