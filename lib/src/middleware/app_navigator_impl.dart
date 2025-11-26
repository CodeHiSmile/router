import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:router/src/interfaces/app_navigator.dart';

@LazySingleton(as: AppNavigator)
class AppNavigatorImpl extends AppNavigator {
  /// GlobalKey để truy cập NavigatorState từ bất kỳ đâu trong app
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Lấy NavigatorState hiện tại từ GlobalKey
  @override
  NavigatorState? get currentNavigator => navigatorKey.currentState;

  /// Lấy BuildContext hiện tại từ NavigatorState
  @override
  BuildContext? get currentContext => navigatorKey.currentContext;

  static GoRouter? get _router {
    final ctx = navigatorKey.currentContext;

    if (ctx == null) return null;

    try {
      return GoRouter.of(ctx);
    } catch (_) {
      return null;
    }
  }

  /// Navigate đến route mới mà không cần BuildContext
  @override
  void navigateTo(String path, {Object? extra}) {
    _router?.go(path, extra: extra);
  }

  /// Push route mới mà không cần BuildContext
  @override
  Future<dynamic> pushTo(String path, {Object? extra}) async {
    return await _router?.push(path, extra: extra);
  }

  /// Pop route hiện tại mà không cần BuildContext
  @override
  Future<void> pop([Object? result]) async {
    currentNavigator?.pop(result);
  }

  /// Push và replace route hiện tại mà không cần BuildContext
  @override
  Future<void> pushReplacement(String path, {Object? extra}) async {
    if (currentContext != null) {
      await _router?.pushReplacement(path, extra: extra);
    }
  }

  @override
  Future<void> replace(String path, {Object? extra}) async {
    if (currentContext != null) {
      await _router?.replace(path, extra: extra);
    }
  }

  @override
  bool canPop() {
    return currentNavigator?.canPop() ?? false;
  }

  @override
  String getCurrentPath() {
    final ctx = currentContext;
    if (ctx == null) return '';
    final router = GoRouter.of(ctx);
    return router.state.path ?? ""; // full location with query
  }

  @override
  void popUntilRoot() {
    //Cách 1:
    // if (currentContext != null) {
    //   while (currentContext!.canPop()) {
    //     currentContext!.pop();
    //   }
    // }

    //Cách 2: Nên dùng
    currentNavigator?.popUntil((route) => route.isFirst);
  }

  @override
  void popUntilRouteName(String routeName) {
    currentNavigator?.popUntil((route) {
      return route.settings.name == routeName;
    });
  }
}
