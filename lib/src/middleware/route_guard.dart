import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:router/src/interfaces/app_navigator.dart';
import 'package:router/src/middleware/app_navigator_impl.dart';
import 'package:router/src/services/auth_service.dart';
import 'package:router/src/services/router_service.dart';
import 'package:router/src/utils/router_logger.dart';

import '../di/di.dart';

@LazySingleton()
class RouterGuard {
  /// Lưu toàn bộ state của route bị chặn để khôi phục sau khi đăng nhập
  static GoRouterState? _savedRouteState;

  /// Flag để track xem có đang trong quá trình auto-restore không
  static bool _isAutoRestoring = false;

  /// Stream controller để listen auth state changes
  static StreamController<bool>? _authStateController;

  /// Timer để debounce auth state changes
  static Timer? _debounceTimer;

  /// Timer để cleanup saved route sau timeout
  static Timer? _cleanupTimer;

  /// Configuration
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _savedRouteTimeout = Duration(
    minutes: 30,
  ); // Auto cleanup sau 30 phút

  static String? lastAttemptedRoute;

  static String? loginSuccessAttemptedRoute;

  /// Enable/disable auto-restore (để test performance impact)
  static bool _autoRestoreEnabled = true;

  /// Initialize auto-restore listener
  static void initializeAutoRestore() {
    // Dispose existing resources first
    dispose();

    _authStateController = StreamController<bool>.broadcast();

    _authStateController!.stream.listen((isLoggedIn) {
      _handleAuthStateChange(isLoggedIn);
    });
  }

  /// Handle auth state change với debouncing và optimization
  static void _handleAuthStateChange(bool isLoggedIn) {
    if (!_autoRestoreEnabled) return;

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Debounce multiple rapid auth state changes
    _debounceTimer = Timer(_debounceDelay, () {
      if (isLoggedIn && _savedRouteState != null && !_isAutoRestoring) {
        _performAutoRestore();
      } else if (!isLoggedIn) {
        // Clear saved route khi logout để tiết kiệm memory
        clearSavedRoute();
      }
    });
  }

  /// Perform auto-restore với error handling và timeout
  static void _performAutoRestore() {
    if (_isAutoRestoring) return; // Prevent multiple concurrent restores
    _isAutoRestoring = true;

    // Set timeout để tự động cleanup nếu restore bị stuck
    _cleanupTimer = Timer(_savedRouteTimeout, () {
      _isAutoRestoring = false;
      clearSavedRoute();
    });

    // Sử dụng microtask để tối ưu hơn Future.delayed
    // Future.microtask(() {
    //
    // });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _restoreSavedRouteViaMainIfNeeded(canPushToPage: true);
        RouterService.notifyOnAuthStateChanged();
      } catch (e, st) {
        RouterLogger.error('Auto-restore error: $e\n$st');
      } finally {
        _isAutoRestoring = false;
        _cleanupTimer?.cancel();
      }
    });
  }

  /// Notify auth state change - gọi từ AuthService
  static void notifyAuthStateChanged(bool isLoggedIn) {
    _authStateController?.add(isLoggedIn);
  }

  /// Cleanup resources và timers
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    _authStateController?.close();
    _authStateController = null;

    _savedRouteState = null;
    _isAutoRestoring = false;
  }

  Future<String?> guard(BuildContext context, GoRouterState state) async {
    final authService = getIt<AuthService>();

    final isLoggedIn = authService.isLoggedIn;

    // location hiện tại : Bỏ query params
    final String location = state.matchedLocation.split('?').first;

    // location cuối cùng
    lastAttemptedRoute = location;

    if (!RouterService.protectedRoutes.contains(location)) {
      if (!RouterService.protectedRoutes.contains(lastAttemptedRoute)) {
        loginSuccessAttemptedRoute = null;
        _savedRouteState = state; // Lưu saved state khi không cần bảo vệ
      }

      return null;
    } else {
      if (isLoggedIn) {
        return null;
      } else {
        // Lưu toàn bộ route state (bao gồm cả data) để khôi phục sau
        _savedRouteState = state;
        loginSuccessAttemptedRoute = location;
        RouterLogger.info(
          'Route protected, redirect to login, saved: $location',
        );
        return AuthService.loginPath;
      }
    }
  }

  /// Manual restore (call from UI if needed)
  static void restoreRouteWithData({bool canPushToPage = true}) {
    _restoreSavedRouteViaMainIfNeeded(canPushToPage: canPushToPage);
  }

  /// Khôi phục route với toàn bộ data sau khi đăng nhập thành công
  static void _restoreSavedRouteViaMainIfNeeded({bool canPushToPage = true}) {
    final state = _savedRouteState;
    if (state == null) return;

    // Clear saved state early to avoid double-restore
    _savedRouteState = null;

    // Then navigate to saved route
    String fullPath = state.matchedLocation;
    if (state.uri.queryParameters.isNotEmpty) {
      final queryString = state.uri.queryParameters.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      fullPath += '?$queryString';
    }

    final navigator = getIt.get<AppNavigator>();

    navigator.pop(true);
    if (canPushToPage) {
      navigator.pushTo(fullPath, extra: state.extra);
    }
  }

  /// Lưu route hiện tại
  static void saveRoute(GoRouterState state) {
    _savedRouteState = state;
  }

  /// Xóa route đã lưu
  static void clearSavedRoute() {
    _savedRouteState = null;
    _cleanupTimer?.cancel();
  }

  /// Lấy thông tin về route đã lưu
  static Map<String, dynamic>? getSavedRouteInfo() {
    final s = _savedRouteState;

    if (s == null) return null;

    return {
      'path': s.matchedLocation,
      'pathParameters': s.pathParameters,
      'queryParameters': s.uri.queryParameters,
      'extra': s.extra,
      'fullPath': s.fullPath,
    };
  }

  /// Performance monitoring
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'hasStreamController': _authStateController != null,
      'hasSavedRoute': _savedRouteState != null,
      'isAutoRestoring': _isAutoRestoring,
      'hasDebounceTimer': _debounceTimer != null && _debounceTimer!.isActive,
      'hasCleanupTimer': _cleanupTimer != null && _cleanupTimer!.isActive,
      'memoryUsage': {
        'savedRouteState': _savedRouteState != null ? 'allocated' : 'null',
        'streamController': _authStateController != null ? 'allocated' : 'null',
      },
    };
  }

  static void setAutoRestoreEnabled(bool enabled) {
    _autoRestoreEnabled = enabled;
    if (!enabled) {
      dispose(); // Clean up nếu disable
    }
  }

  static bool get isAutoRestoreEnabled => _autoRestoreEnabled;
}
