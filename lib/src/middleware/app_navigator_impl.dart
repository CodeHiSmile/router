import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:domain/domain.dart';

@LazySingleton(as: BaseNavigator)
class NavigatorImpl extends BaseNavigator {
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  /// GlobalKey để truy cập NavigatorState từ bất kỳ đâu trong app
  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Lấy NavigatorState hiện tại từ GlobalKey
  @override
  NavigatorState? get currentNavigator => navigatorKey.currentState;

  /// Lấy BuildContext hiện tại từ NavigatorState
  @override
  BuildContext? get currentContext => navigatorKey.currentContext;

  static GoRouter? get _router {
    final ctx = _navigatorKey.currentContext;

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
