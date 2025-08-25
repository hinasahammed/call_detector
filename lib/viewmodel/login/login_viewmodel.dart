
import 'package:call_detector/data/response/status.dart';
import 'package:call_detector/repository/loginRepsoitory/login_repository.dart';
import 'package:call_detector/res/utils/toast_service.dart';
import 'package:call_detector/viewmodel/providers/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_viewmodel.g.dart';

class LoginState {
  LoginState({this.loginStatus = Status.initial});
  final Status loginStatus;

  LoginState copyWith({Status? loginStatus}) {
    return LoginState(loginStatus: loginStatus ?? this.loginStatus);
  }
}

@riverpod
class LoginViewmodel extends _$LoginViewmodel {
  late LoginRepository _repo;
  @override
  LoginState build() {
    _repo = ref.watch(loginRepositoryProvider);
    return LoginState();
  }

  void setLoginStatus(Status status) {
    state = state.copyWith(loginStatus: status);
  }

  Future<bool> login({required String pin}) async {
    setLoginStatus(Status.loading);
    final value = await _repo.login(pin: pin);

    if (value != null) {
      setLoginStatus(Status.completed);
      ToastService.showToast(message: "Login Successfull");
      return true;
    } else {
      setLoginStatus(Status.error);
      ToastService.showToast(message: "Login Failed");
      return false;
    }
  }
}
