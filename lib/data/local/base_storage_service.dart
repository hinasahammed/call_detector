abstract class BaseStorageService {
  Future addData({required String key, required String data});
  dynamic getLocalData({required String key});
  Future<bool> clearData({required String key});
}
