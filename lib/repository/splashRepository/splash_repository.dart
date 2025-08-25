import 'package:call_detector/data/local/local_storage_service.dart';
import 'package:call_detector/data/local/storage_keys.dart';

class SplashRepository {
  SplashRepository({required LocalStorageService localStorageService})
    : _localStorageService = localStorageService;
  final LocalStorageService _localStorageService;

  dynamic getUserCode() {
    return _localStorageService.getLocalData(key: StorageKeys.userInfo);
  }
}
