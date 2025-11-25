import 'package:shared/shared.dart';

class RouterLogger {
  static void info(String message) {
    LogUtils.i('[Router INFO] $message');
  }

  static void error(String message) {
    LogUtils.e('[Router ERROR] $message');
  }

  static void debug(String message) {
    LogUtils.d('[Router DEBUG] $message');
  }

  static void warning(String message) {
    LogUtils.w('[Router WARNING] $message');
  }
}
