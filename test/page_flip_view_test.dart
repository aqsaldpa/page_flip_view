import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_flip_view/page_flip_view.dart';

Widget book(PageFlipController controller, List<int> changes) => MaterialApp(
  home: PageFlipView(
    itemCount: 4,
    controller: controller,
    onPageChanged: changes.add,
    itemBuilder: (context, index) => Center(child: Text('page $index')),
  ),
);

void main() {
  testWidgets('fling turns forward, short drag falls back', (tester) async {
    final controller = PageFlipController();
    final changes = <int>[];
    await tester.pumpWidget(book(controller, changes));

    await tester.fling(find.byType(PageFlipView), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(changes, [1]);
    expect(controller.page, 1);

    await tester.drag(find.byType(PageFlipView), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(changes, [1]);
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('controller and edge taps turn pages', (tester) async {
    final controller = PageFlipController();
    final changes = <int>[];
    await tester.pumpWidget(book(controller, changes));

    controller.next();
    await tester.pumpAndSettle();
    expect(changes.last, 1);

    await tester.tapAt(const Offset(790, 300));
    await tester.pumpAndSettle();
    expect(changes.last, 2);

    await tester.tapAt(const Offset(10, 300));
    await tester.pumpAndSettle();
    expect(changes.last, 1);

    controller.jumpTo(3);
    await tester.pumpAndSettle();
    expect(find.text('page 3'), findsOneWidget);

    controller.next();
    await tester.pumpAndSettle();
    expect(controller.page, 3);
  });

  testWidgets('double tap zooms, edge taps pause while zoomed', (tester) async {
    final controller = PageFlipController();
    final changes = <int>[];
    final zooms = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PageFlipView(
          itemCount: 4,
          controller: controller,
          onPageChanged: changes.add,
          onZoomChanged: zooms.add,
          itemBuilder: (context, index) => Center(child: Text('page $index')),
        ),
      ),
    );

    await tester.tapAt(const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();
    expect(zooms.last, closeTo(2.5, 0.01));

    await tester.tapAt(const Offset(790, 300));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);

    await tester.tapAt(const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();
    expect(zooms.last, 1);

    await tester.tapAt(const Offset(790, 300));
    await tester.pumpAndSettle();
    expect(changes, [1]);
  });

  testWidgets('single middle tap reaches onCenterTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PageFlipView(
          itemCount: 2,
          onCenterTap: () => taps++,
          itemBuilder: (context, index) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.tapAt(const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 400));
    expect(taps, 1);
  });
}
