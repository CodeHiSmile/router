import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteEntry {
  final String path;
  final Widget Function(BuildContext, GoRouterState) builder;
  final bool protected;
  final List<RouteEntry>? routes;

  RouteEntry({
    required this.path,
    required this.builder,
    this.protected = false,
    this.routes,
  });
}
