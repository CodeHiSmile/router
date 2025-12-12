class RouterPath {
  RouterPath._private();

  static final RouterPath instance = RouterPath._private();

  String initialPath = '/';
  String loginPath = '/login';
  String dashboardPath = '/dashboard';
}
