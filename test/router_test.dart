import 'package:flutter_test/flutter_test.dart';

import 'package:router/router.dart';

void main() {
  test('router service can be instantiated', () {
    final service = RouterService();
    expect(service, isA<RouterService>());
  });
}
