// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:router/src/interfaces/app_navigator.dart' as _i33;
import 'package:router/src/middleware/app_navigator_impl.dart' as _i1004;
import 'package:router/src/middleware/route_guard.dart' as _i447;
import 'package:router/src/services/auth_service.dart' as _i559;
import 'package:router/src/services/router_service.dart' as _i614;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i447.RouterGuard>(() => _i447.RouterGuard());
    gh.lazySingleton<_i559.AuthService>(() => _i559.AuthService());
    gh.lazySingleton<_i614.RouterService>(() => _i614.RouterService());
    gh.lazySingleton<_i33.AppNavigator>(() => _i1004.AppNavigatorImpl());
    return this;
  }
}
