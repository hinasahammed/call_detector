import 'package:call_detector/data/local/base_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService implements BaseStorageService {
  LocalStorageService({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferences _sharedPreferences;
  @override
  Future<bool> addData({required String key, required String data}) async {
    final value = await _sharedPreferences.setString(key, data);
    return value;
  }

  @override
  String getLocalData({required String key}) {
    final value = _sharedPreferences.getString(key) ?? "";
    return value;
  }

  @override
  Future<bool> clearData({required String key}) async {
    final value = await _sharedPreferences.remove(key);
    return value;
  }
}
