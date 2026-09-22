import 'package:flutter_test/flutter_test.dart';
import 'package:page_flip_view/pdf.dart';

void main() {
  test('pdf library exposes the flip book and night filter', () {
    expect(const PdfFlipBook.asset('book.pdf'), isA<PdfFlipBook>());
    expect(PdfFlipBook.nightMode, isNotNull);
  });
}
