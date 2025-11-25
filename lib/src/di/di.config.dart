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
import 'package:router/src/services/auth_service.dart' as _i584;
import 'package:router/src/middleware/route_guard.dart' as _i462;
import 'package:router/src/services/router_service.dart' as _i513;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i584.AuthService>(() => _i584.AuthService());
    gh.lazySingleton<_i462.RouterGuard>(() => _i462.RouterGuard());
    gh.lazySingleton<_i513.RouterService>(() => _i513.RouterService());
    return this;
  }
}
