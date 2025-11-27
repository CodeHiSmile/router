import 'dart:async';

import 'package:domain/domain.dart';
import 'package:injectable/injectable.dart';
import 'package:router/router.dart';
import 'package:router/src/di/di.dart';
import 'package:shared/shared.dart';

@LazySingleton()
class AuthService {
  static String loginPath = '/login';

  static String mainPagePath = '/';

  bool _isLoggedIn = false;

  /// Stream để theo dõi auth state changes
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  Stream<bool> get authStateStream => _authStateController.stream;

  AuthService() {
    // Listen to auth state changes và notify router
    authStateStream.listen((isLoggedIn) {
      RouterGuard.notifyAuthStateChanged(isLoggedIn);
    });
  }

  /// Kiểm tra trạng thái đăng nhập
  bool get isLoggedIn => _isLoggedIn;

  void changeLoginPath(String path) {
    if (loginPath != path) {
      loginPath = path;
    }
  }

  void changeMainPagePath(String path) {
    if (mainPagePath != path) {
      mainPagePath = path;
    }
  }

  /// Login + trigger auto-restore via RouterGuard
  Future<bool> loginWithAutoRestore() async {
    LogUtils.d('🔐 Đang đăng nhập với auto-restore...');
    _isLoggedIn = true;

    _authStateController.add(true);
    LogUtils.d('✅ Login thành công! Router sẽ tự động restore...');
    return true;
  }

  /// Optional manual restore call (not recommended, prefer auto-restore)
  Future<bool> loginWithManualRestore({bool canPushToPage = true}) async {
    LogUtils.d('🔐 Đăng nhập với manual restore...');
    _isLoggedIn = true;

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
    LogUtils.d('🚪 Đang đăng xuất...');
    _isLoggedIn = false;

    // Clear saved route khi logout
    RouterGuard.clearSavedRoute();

    // Notify auth state changed
    _authStateController.add(false);
    if (canNavigateLogin) {
      getIt.get<BaseNavigator>().navigateTo(loginPath);
    }

    LogUtils.d('✅ Đã đăng xuất và clear saved route.');
  }

  /// Login với custom behavior
  Future<bool> loginWithCustomRestore({
    bool shouldAutoRestore = true,
    void Function()? onRestoreComplete,
  }) async {
    _isLoggedIn = true;

    // Configure callback trước khi restore
    if (onRestoreComplete != null) {
      RouterService.configureAutoRestore(onAuthStateChanged: onRestoreComplete);
    }

    loginWithManualRestore(canPushToPage: false);

    return true;
  }

  /// Get thông tin về route sẽ được restore
  Map<String, dynamic>? getRestorePreview() {
    return RouterGuard.getSavedRouteInfo();
  }

  void dispose() {
    _authStateController.close();
  }
}
