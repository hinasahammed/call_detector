abstract class BaseApiService {
  Future getApiCall({required String url});
  Future postApiCall({required String url, required dynamic data});
  Future uploadFile({required String url, required Map<String, dynamic> data});
}
