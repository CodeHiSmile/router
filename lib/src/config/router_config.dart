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
  Future<void> config() async {
    RouterGuard.initializeAutoRestore();
    di.configureInjection();
  }
}
