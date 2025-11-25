import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:router/src/middleware/app_navigator.dart';
import 'package:router/src/middleware/route_guard.dart';
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
  Future<bool> isLoggedIn() async {
    return _isLoggedIn;
  }

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
    print('🔐 Đăng nhập với manual restore...');
    _isLoggedIn = true;

    RouterGuard.restoreRouteWithData(canPushToPage: canPushToPage);
    _authStateController.add(true);
    print('✅ Login thành công! Đã manual restore route.');
    return true;
  }

  /// Đăng xuất
  Future<void> logout({bool canNavigateLogin = false}) async {
    print('🚪 Đang đăng xuất...');
    _isLoggedIn = false;

    // Clear saved route khi logout
    RouterGuard.clearSavedRoute();

    // Notify auth state changed
    _authStateController.add(false);
    if (canNavigateLogin) {
      AppNavigator.navigateTo(loginPath);
    }

    print('✅ Đã đăng xuất và clear saved route.');
  }

  /// Login với custom behavior
  Future<bool> loginWithCustomRestore({
    bool shouldAutoRestore = true,
    void Function()? onRestoreComplete,
  }) async {
    _isLoggedIn = true;

    if (shouldAutoRestore) {
      // Configure callback trước khi restore
      if (onRestoreComplete != null) {
        // RouterService.configureAutoRestore(
        //   onAuthStateChanged: onRestoreComplete,
        // );
      }
      // Trigger auto-restore
      _authStateController.add(true);
    } else {
      // Skip auto-restore
      print('⏭️ Skip auto-restore theo yêu cầu');
    }

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
