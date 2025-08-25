import 'package:call_detector/repository/splashRepository/splash_repository.dart';
import 'package:call_detector/viewmodel/providers/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_viewmodel.g.dart';

class SplashState {
  SplashState({this.userCode = ""});
  final String userCode;
}

@riverpod
class SplashViewmodel extends _$SplashViewmodel {
  late SplashRepository _repo;
  @override
  SplashState build() {
    _repo = ref.watch(splashRepositoryProvider);
    return SplashState();
  }

  bool isLogedIn() {
    final userCode = _repo.getUserCode().toString();
    if (userCode.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }
}
