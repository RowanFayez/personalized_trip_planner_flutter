import 'package:flutter_test/flutter_test.dart';

import 'package:nextstation/main.dart';

void main() {
  test('NextStation app shell can be constructed', () {
    const app = NextStationApp();
    expect(app, isA<NextStationApp>());
  });
}
