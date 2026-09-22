import 'package:flutter/widgets.dart';

import 'pdf_flip_book.dart';
import 'pdf_page_cache.dart';

class PdfPageImage extends StatelessWidget {
  const PdfPageImage({
    super.key,
    required this.cache,
    required this.index,
    required this.paperColor,
    this.placeholderBuilder,
    this.pageErrorBuilder,
    this.colorFilter,
  });

  final PdfPageCache cache;
  final int index;
  final Color paperColor;
  final PdfPagePlaceholderBuilder? placeholderBuilder;
  final PdfPageErrorBuilder? pageErrorBuilder;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: paperColor,
      child: ListenableBuilder(
        listenable: cache,
        builder: (context, _) {
          final image = cache.imageAt(index);
          if (image != null) {
            final picture = RawImage(
              image: image,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            );
            final filter = colorFilter;
            if (filter == null) return picture;
            return ColorFiltered(colorFilter: filter, child: picture);
          }
          final errorBuilder = pageErrorBuilder;
          if (cache.hasFailed(index) && errorBuilder != null) {
            return errorBuilder(context, index, () => cache.retry(index));
          }
          return placeholderBuilder?.call(context, index) ??
              const SizedBox.expand();
        },
      ),
    );
  }
}
