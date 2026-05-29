// Placeholder boot test.
//
// The real widget tests arrive with the chat shell milestones (M2+).
// This trivial test keeps `flutter test` / `flutter analyze` green while
// the scaffolding is assembled by other agents.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('boot', () {
    expect(1 + 1, 2);
  });
}
