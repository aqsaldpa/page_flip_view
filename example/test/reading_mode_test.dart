import 'package:flutter_test/flutter_test.dart';
import 'package:page_flip_view_example/main.dart';

void main() {
  test('reading modes cycle', () {
    expect(ReadingMode.values.length, 4);
    expect(ReadingMode.night.next, ReadingMode.normal);
  });
}
