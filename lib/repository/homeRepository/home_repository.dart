import 'dart:convert';
import 'dart:developer';

import 'package:call_detector/data/local/storage_keys.dart';
import 'package:call_detector/data/network/network_api_service.dart';
import 'package:call_detector/model/customerStatus/customer_status_model.dart';
import 'package:call_detector/res/appUrl/app_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeRepository {
  HomeRepository({required NetworkApiService networkApiService})
    : _networkApiService = networkApiService;

  final NetworkApiService _networkApiService;

  Future fetchCallLogs() async {
    final pref = await SharedPreferences.getInstance();
    final userCode = pref.getString(StorageKeys.userInfo) ?? "{}";
    log(userCode);
    if (userCode.isNotEmpty) {
      final value = jsonDecode(userCode);
      final data = {"Staff_Id": value['code']};
      return await _networkApiService.postApiCall(
        url: AppUrl.callLogs,
        data: data,
      );
    } else {
      log("Usercode is empty");
    }
  }

  Future<CustomerStatusModel> isCustomerCall({required String number}) async {
    final data = {"RegistredMobileNumber": number};
    log("repository $data");
    final value = await _networkApiService.postApiCall(
      url: AppUrl.existCustomerUrl,
      data: data,
    );
    if (value != null && value['Data'] != null) {
      final data = value['Data'];
      return CustomerStatusModel(
        billingName: data['BillingName'],
        customerCode: data['code'],
        isCustomer: true,
      );
    }
    return CustomerStatusModel(isCustomer: false);
  }

  Future updateAction({required String id, required String action}) async {
    final data = {"CallLogID": id, "action_needed": action};
    return await _networkApiService.postApiCall(
      url: AppUrl.updateActionUrl,
      data: data,
    );
  }

  Future updateAttented({required String id, required String attented}) async {
    final data = {"CallLogID": id, "attended": attented};
    return await _networkApiService.postApiCall(
      url: AppUrl.updateAttentedUrl,
      data: data,
    );
  }

  Future syncCallLog({
    required String customerCode,
    required String date,
    required String time,
  }) async {
    final pref = await SharedPreferences.getInstance();
    final userCode = pref.getString(StorageKeys.userInfo) ?? "{}";
    log(userCode);
    if (userCode.isNotEmpty) {
      final value = jsonDecode(userCode);
      final data = {
        "customerCode": customerCode,
        "staffCode": value['code'],
        "date": date,
        "time": time,
      };
      await _networkApiService.postApiCall(
        url: AppUrl.syncCallLogUrl,
        data: data,
      );
    } else {
      log("Usercode is empty");
    }
  }
}
