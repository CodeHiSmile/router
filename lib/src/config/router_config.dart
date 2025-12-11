import 'package:router/src/config/router_path.dart';
import 'package:router/src/middleware/route_guard.dart';
import 'package:shared/shared.dart';

import '../di/di.dart' as di;

class RouterConfig extends Config {
  RouterConfig._();

  factory RouterConfig.getInstance() {
    return _instance;
  }

  static final RouterConfig _instance = RouterConfig._();

  @override
  Future<void> init({String? initialRoute, String? loginRoute}) {
    configRoute(initialRoute, loginRoute);
    return super.init();
  }

  Future<void> configRoute(String? initialRoute, String? loginRoute) async {
    if (initialRoute != null) {
      RouterPath.instance.initialPath = initialRoute;
    }

    if (loginRoute != null) {
      RouterPath.instance.loginPath = loginRoute;
    }

    RouterGuard.initializeAutoRestore();
  }

  @override
  Future<void> config() async {
    di.configureInjection();
  }
}
