import 'dart:developer';

import 'package:call_detector/data/response/status.dart';
import 'package:call_detector/model/call_log_model/call_log_model.dart';
import 'package:call_detector/repository/homeRepository/home_repository.dart';
import 'package:call_detector/res/utils/toast_service.dart';
import 'package:call_detector/viewmodel/providers/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_viewmodel.g.dart';

class HomeState {
  HomeState({this.callLogStatus = Status.initial, required this.callLogs});
  final Status callLogStatus;
  final List<CallLogModel> callLogs;

  HomeState copyWith({Status? callLogStatus, List<CallLogModel>? callLogs}) {
    return HomeState(
      callLogStatus: callLogStatus ?? this.callLogStatus,
      callLogs: callLogs ?? this.callLogs,
    );
  }
}

@riverpod
class HomeViewmodel extends _$HomeViewmodel {
  late HomeRepository _repo;
  @override
  HomeState build() {
    _repo = ref.watch(homeRepositoryProvider);
    return HomeState(callLogs: []);
  }

  void fetchingCallLogs(Status status) {
    state = state.copyWith(callLogStatus: status);
  }

  Future fetchCalllogs({bool isRefresh = false}) async {
    if (!isRefresh) {
      fetchingCallLogs(Status.loading);
    }
    final value = await _repo.fetchCallLogs();
    if (value != null) {
      state = state.copyWith(callLogs: []);
      for (var i in value['Data']) {
        state = state.copyWith(
          callLogs: [...state.callLogs, CallLogModel.fromJson(i)],
        );
      }
      log(state.callLogs.length.toString());
      fetchingCallLogs(Status.completed);
      log(state.callLogStatus.toString());
    } else {
      fetchingCallLogs(Status.error);
    }
  }

  Future updateAction({required String id, required String action}) async {
    final value = await _repo.updateAction(id: id, action: action);
    if (value != null) {
      await fetchCalllogs(isRefresh: true);
      ToastService.showToast(message: "Updated");
    } else {
      ToastService.showToast(message: "Failed to update");
    }
  }

  Future updateAttented({required String id, required String attented}) async {
    final value = await _repo.updateAttented(id: id, attented: attented);
    if (value != null) {
      await fetchCalllogs(isRefresh: true);
      ToastService.showToast(message: "Updated");
    } else {
      ToastService.showToast(message: "Failed to update");
    }
  }
}
