import 'dart:developer';

import 'package:call_detector/data/network/base_api_service.dart';
import 'package:call_detector/res/appUrl/app_url.dart';
import 'package:call_detector/res/utils/toast_service.dart';
import 'package:dio/dio.dart';

class NetworkApiService implements BaseApiService {
  NetworkApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppUrl.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.json,
        validateStatus: (status) {
          return true;
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // if (!options.path.contains(AppUrl.loginUrl)) {
          //   try {
          //     final value = localStorageService.getLocalData(
          //       key: StorageKeys.userInfo,
          //     );
          //     final userData = jsonDecode(value);
          //     if (userData != null) {
          //       final token = userData['token'] ?? "";
          //       options.headers['Authorization'] = 'Bearer $token';
          //     }
          //   } catch (e) {
          //     log("Error retrieving token: $e");
          //   }
          // } else {
          //   log("Login request detected - skipping Authorization header");
          // }
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          log('DIO ERROR: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }
  late final Dio _dio;

  Future<T?> _handleApiCall<T>({required Future<T> Function() apiCall}) async {
    try {
      return await apiCall();
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        ToastService.showToast(
          message: "Connection timed out. Please try again.",
        );
      } else if (e.type == DioExceptionType.connectionError) {
        ToastService.showToast(
          message:
              "It looks like you're offline. Please check your internet and retry.",
        );
      } else {
        ToastService.showToast(
          message: "Oops! Something went wrong. Please try again.",
        );
      }
      log("DIO ERROR: ${e.message}");
      return null;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }
      log("ERROR: $errorMessage");
      return null;
    }
  }

  dynamic _handleResponse(Response response) {
    final data = response.data;
    switch (data['ResponseCode']) {
      case 200:
      case 201:
        if (data != null) {
          return data;
        } else {
          throw Exception('Unable to fetch the required data.');
        }
      case 204:
      case 400:
        if (data != null && data.containsKey("Message")) {
          throw Exception(data['Message']);
        } else {
          throw Exception('Invalid input or missing parameters');
        }
      case 401:
        throw Exception('Check your credentials and try again');
      case 404:
        if (data != null && data.containsKey("Message")) {
          throw Exception(data['Message']);
        } else {
          throw Exception('Not Found: The requested resource does not exist.');
        }
      case 500:
        throw Exception(
          'Something went wrong on our end. Please try again later.',
        );
      default:
        throw Exception('Oops! Something went wrong. Please try again.');
    }
  }

  // _handleUnauthorized() async {
  //   final isRemoved = await localStorageService.clearData(
  //     key: StorageKeys.userInfo,
  //   );
  //   if (isRemoved) {
  //     ToastService.showToast(
  //       message: "Session expired. Please log in again.",
  //     );
  //     navigatorKey.currentState?.pushAndRemoveUntil(
  //       MaterialPageRoute(builder: (context) => LoginView()),
  //       (route) => false,
  //     );
  //   }
  // }

  @override
  Future getApiCall({required String url}) async {
    return _handleApiCall(
      apiCall: () async {
        final response = await _dio.get(url);
        log("Response status: ${response.statusCode}");
        log("Response data: ${response.data}");
        return _handleResponse(response);
      },
    );
  }

  @override
  Future postApiCall({required String url, required data}) async {
    return _handleApiCall(
      apiCall: () async {
        final response = await _dio.post(url, data: data);
        log("Response status: ${response.statusCode}");
        log("Response data: ${response.data}");
        return _handleResponse(response);
      },
    );
  }

  @override
  Future uploadFile({
    required String url,
    required Map<String, dynamic> data,
  }) async {
    return _handleApiCall(
      apiCall: () async {
        final formData = FormData.fromMap(data);

        final response = await _dio.post(
          url,
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        );

        log("Image upload response code: ${response.statusCode}");
        log("Image upload response: ${response.data}");

        return _handleResponse(response);
      },
    );
  }
}
