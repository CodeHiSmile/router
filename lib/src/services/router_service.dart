import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:router/src/config/router_path.dart';
import 'package:router/src/middleware/route_entry.dart';
import 'package:router/src/middleware/route_guard.dart';
import 'package:router/src/observers/app_navigator_observer.dart';

import '../di/di.dart';

/// Router Service quản lý toàn bộ navigation trong app
@LazySingleton()
class RouterService {
  final List<RouteEntry> _routes = [];

  late GoRouter _router;

  /// Callback được gọi khi cần restore route sau khi login
  static void Function()? onAuthStateChangedCallback;

  static Set<String> protectedRoutes = {};

  RouterService() {
    _updateRouter();
  }

  // void changeInitialPath(String path) {
  //   if (initialPath != path) {
  //     initialPath = path;
  //   }
  // }

  void registerRoute(RouteEntry entry) {
    _routes.add(entry);
    _updateRouter();
  }

  void registerRoutes(List<RouteEntry> entries) {
    _routes.addAll(entries);
    _updateRouter();
  }

  void _updateRouter() {
    protectedRoutes = _routes
        .where((element) => element.protected)
        .map((e) => e.path)
        .toSet();

    _router = GoRouter(
      initialLocation: RouterPath.instance.initialPath,
      redirect: getIt<RouterGuard>().guard,
      debugLogDiagnostics: false,
      navigatorKey: getIt<BaseNavigator>().navigatorKey,
      routes: _routes.map(_mapEntryToGoRoute).toList(),
      observers: [AppNavigatorObserver()],
    );
  }

  GoRoute _mapEntryToGoRoute(RouteEntry entry) {
    return GoRoute(
      path: entry.path,
      builder: (context, state) => entry.builder(context, state),
      routes: entry.routes?.map(_mapEntryToGoRoute).toList() ?? [],
    );
  }

  GoRouter get router => getIt<RouterService>()._router;

  /// Cấu hình auto-restore khi auth state thay đổi
  static void configureAutoRestore({void Function()? onAuthStateChanged}) {
    onAuthStateChangedCallback = onAuthStateChanged;
  }

  static void notifyOnAuthStateChanged() {
    onAuthStateChangedCallback?.call();
  }
}
