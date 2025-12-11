import 'dart:async';

import 'package:domain/domain.dart';
import 'package:injectable/injectable.dart';
import 'package:router/router.dart';
import 'package:router/src/di/di.dart';
import 'package:shared/shared.dart';

@LazySingleton()
class AuthService {
  static String loginPath = '/login';

  final Repository _repository;

  /// Stream để theo dõi auth state changes
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  Stream<bool> get authStateStream => _authStateController.stream;

  AuthService(this._repository) {
    /// Listen for auth state changes and notify router
    authStateStream.listen((isLoggedIn) {
      RouterGuard.notifyAuthStateChanged(isLoggedIn);
    });
  }

  /// Kiểm tra trạng thái đăng nhập
  bool get isLoggedIn => _repository.isLoggedIn;

  void changeLoginPath(String path) {
    if (loginPath != path) {
      loginPath = path;
    }
  }

  /// Optional manual restore call (not recommended, prefer auto-restore)
  Future<bool> restoreRoute({bool canPushToPage = true}) async {
    RouterGuard.restoreRouteWithData(canPushToPage: canPushToPage);
    _authStateController.add(true);
    LogUtils.d('✅ Login thành công! Đã manual restore route.');
    return true;
  }

  /// Thực thi [action] khi user đã đăng nhập.
  /// Nếu chưa login thì điều hướng đến [loginPath], chờ login thành công rồi mới chạy [action].
  Future<void> runAfterLogin({
    required FutureOr<void> Function() action,
  }) async {
    Future<void> runAction() => Future.sync(action);

    if (isLoggedIn) {
      await runAction();
      return;
    }

    final navigator = getIt.get<BaseNavigator>();
    final completer = Completer<void>();

    Future<void> triggerActionOnce() async {
      if (completer.isCompleted) return;

      try {
        await runAction();
        LogUtils.d("hihi chay ham action xong roi ne");

        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }

    LogUtils.d(
      '🔒 User chưa login, chuyển tới $loginPath để chạy action bảo vệ.',
    );

    final didLogin = await navigator.pushTo(loginPath);
    LogUtils.d("didLogin: $didLogin");

    // Tạo listener nhưng chưa trigger vội
    final sub = authStateStream.listen((loggedIn) {
      if (loggedIn) {
        triggerActionOnce();
      }
    });

    // Nếu user BACK mà không đăng nhập:
    if (didLogin != true) {
      LogUtils.d("User back mà chưa login → cancel listener.");
      await sub.cancel();
      return;
    }

    // Nếu login thành công
    triggerActionOnce();
    completer.future.whenComplete(() => sub.cancel());
    return completer.future;
  }

  /// Đăng xuất
  Future<void> logout({bool canNavigateLogin = false}) async {
    RouterGuard.clearSavedRoute();

    _authStateController.add(false);
    if (canNavigateLogin) {
      getIt.get<BaseNavigator>().navigateTo(loginPath);
    }

    LogUtils.d('✅ Đã đăng xuất thành công.');
  }

  /// Get thông tin về route sẽ được restore
  Map<String, dynamic>? getRestorePreview() {
    return RouterGuard.getSavedRouteInfo();
  }

  void dispose() {
    _authStateController.close();
  }
}
