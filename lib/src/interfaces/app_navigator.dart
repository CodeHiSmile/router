import 'package:flutter/material.dart';

abstract class AppNavigator {
  BuildContext? get currentContext;

  NavigatorState? get currentNavigator;

  void navigateTo(String path, {Object? extra});

  Future<void> pushTo(String path, {Object? extra});

  Future<void> pop([Object? result]);

  Future<void> pushReplacement(String path, {Object? extra});

  Future<void> replace(String path, {Object? extra});

  bool canPop();

  String getCurrentPath();

  void popUntilRoot();

  void popUntilRouteName(String routeName);
}
