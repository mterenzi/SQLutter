import 'package:flutter_test/flutter_test.dart';

import 'package:sqlutter/sqlutter.dart';

void main() {
  test('Basic', () {
    IntStorage storage = IntStorage(null, name: 'Eee');
    print(storage.nullable);
  });
}
