import 'dart:convert';
import 'dart:developer';

import 'package:call_detector/data/local/local_storage_service.dart';
import 'package:call_detector/data/local/storage_keys.dart';
import 'package:call_detector/data/network/network_api_service.dart';
import 'package:call_detector/res/appUrl/app_url.dart';

class LoginRepository {
  LoginRepository({
    required this.networkApiService,
    required this.localStorageService,
  });

  final NetworkApiService networkApiService;
  final LocalStorageService localStorageService;

  Future login({required String pin}) async {
    final data = {"otp": pin};

    final value = await networkApiService.postApiCall(
      url: AppUrl.loginUrl,
      data: data,
    );
    if (value != null) {
      final userData = {'code': value['Data']['Code']};
      log("Storing userData $userData");
      await localStorageService.addData(
        key: StorageKeys.userInfo,
        data: jsonEncode(userData),
      );
    }
    return value;
  }
}
