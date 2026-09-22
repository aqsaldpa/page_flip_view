import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_flip_view/pdf.dart';

void main() {
  test('pdf library exposes the flip book and night filter', () {
    expect(const PdfFlipBook.asset('book.pdf'), isA<PdfFlipBook>());
    expect(PdfFlipBook.nightMode, isNotNull);
    expect(PdfFlipBook.dimPaper, const Color(0xFFBFBFBF));
    expect(PdfFlipBook.sepiaPaper, const Color(0xFFFAEBCC));
    expect(PdfFlipBook.nightPaper, const Color(0xFF000000));
    expect([PdfFlipBook.dim, PdfFlipBook.sepia], everyElement(isNotNull));
    expect(
      PdfFlipBook.network(
        Uri.parse('https://example.com/book.pdf'),
        headers: const {'Authorization': 'Bearer x'},
        loadingBuilder: (context, progress) => const SizedBox(),
      ),
      isA<PdfFlipBook>(),
    );
  });
}
