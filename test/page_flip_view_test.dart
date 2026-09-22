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
}
