import 'package:fluttertoast/fluttertoast.dart';

class ToastService {
  static void showToast({required String message}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(msg: message);
  }
}
