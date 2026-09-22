import 'package:flutter/material.dart';
import 'package:page_flip_view/pdf.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(length: 2, child: DemoHome()),
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  final controller = PageFlipController();
  int page = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF323232),
      appBar: AppBar(
        title: Text('Page ${page + 1}'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'PDF'),
            Tab(text: 'Widgets'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: controller.previous,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: controller.next,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: PdfFlipBook.asset(
              'assets/sample.pdf',
              controller: controller,
              onPageChanged: (value) => setState(() => page = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: PageFlipView(
              itemCount: 8,
              itemBuilder: (context, index) => ColoredBox(
                color:
                    Colors.primaries[index % Colors.primaries.length].shade100,
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
