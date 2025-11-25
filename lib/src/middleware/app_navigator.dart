import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:router/src/utils/router_logger.dart';

class AppNavigator {
  /// GlobalKey để truy cập NavigatorState từ bất kỳ đâu trong app
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Lấy NavigatorState hiện tại từ GlobalKey
  static NavigatorState? get currentNavigator => navigatorKey.currentState;

  /// Lấy BuildContext hiện tại từ NavigatorState
  static BuildContext? get currentContext => navigatorKey.currentContext;

  static GoRouter? get _router {
    final ctx = currentContext;

    if (ctx == null) return null;

    try {
      return GoRouter.of(ctx);
    } catch (_) {
      return null;
    }
  }

  /// Navigate đến route mới mà không cần BuildContext
  static void navigateTo(String path, {Object? extra}) {
    _router?.go(path, extra: extra);
  }

  /// Push route mới mà không cần BuildContext
  static Future<void> pushTo(String path, {Object? extra}) async {
    await _router?.push(path, extra: extra);
  }

  /// Pop route hiện tại mà không cần BuildContext
  static Future<void> pop([Object? result]) async {
    currentNavigator?.pop(result);
  }

  /// Push và replace route hiện tại mà không cần BuildContext
  static Future<void> pushReplacement(String path, {Object? extra}) async {
    if (currentContext != null) {
      await _router?.pushReplacement(path, extra: extra);
    }
  }

  static Future<void> replace(String path, {Object? extra}) async {
    if (currentContext != null) {
      await _router?.replace(path, extra: extra);
    }
  }

  static bool canPop() {
    return currentNavigator?.canPop() ?? false;
  }

  static String getCurrentPath() {
    final ctx = currentContext;
    if (ctx == null) return '';
    final router = GoRouter.of(ctx);
    return router.state.path ?? ""; // full location with query
  }

  static void popUntilRoot() {
    //Cách 1:
    // if (currentContext != null) {
    //   while (currentContext!.canPop()) {
    //     currentContext!.pop();
    //   }
    // }

    //Cách 2: Nên dùng
    currentNavigator?.popUntil((route) => route.isFirst);
  }

  static void popUntilRouteName(String routeName) {
    currentNavigator?.popUntil((route) {
      return route.settings.name == routeName;
    });
  }
}
