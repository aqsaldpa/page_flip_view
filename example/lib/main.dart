import 'package:flutter/material.dart';
import 'package:page_flip_view/pdf.dart';

void main() => runApp(const DemoApp());

const samplePdfUrl =
    'https://raw.githubusercontent.com/mozilla/pdf.js/master/web/compressed.tracemonkey-pldi-09.pdf';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFF323232),
          appBar: AppBar(
            toolbarHeight: 0,
            bottom: const TabBar(
              tabs: [
                Tab(text: 'PDF asset'),
                Tab(text: 'PDF network'),
                Tab(text: 'Widgets'),
              ],
            ),
          ),
          body: const SafeArea(
            top: false,
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [AssetPdfDemo(), NetworkPdfDemo(), WidgetsDemo()],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bundled PDF with page buttons and a night mode switch.
class AssetPdfDemo extends StatefulWidget {
  const AssetPdfDemo({super.key});

  @override
  State<AssetPdfDemo> createState() => _AssetPdfDemoState();
}

class _AssetPdfDemoState extends State<AssetPdfDemo> {
  final controller = PageFlipController();
  int page = 0;
  int total = 0;
  bool night = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoFrame(
      controller: controller,
      label: 'Page ${page + 1} of $total',
      trailing: IconButton(
        color: Colors.white,
        tooltip: 'Night mode',
        onPressed: () => setState(() => night = !night),
        icon: Icon(night ? Icons.light_mode : Icons.dark_mode),
      ),
      child: PdfFlipBook.asset(
        'assets/sample.pdf',
        controller: controller,
        onLoaded: (count) => setState(() => total = count),
        onPageChanged: (value) => setState(() => page = value),
        colorFilter: night ? PdfFlipBook.nightMode : null,
        paperColor: night ? const Color(0xFF1E1E1E) : Colors.white,
      ),
    );
  }
}

/// A PDF downloaded from a URL, with a download progress indicator.
class NetworkPdfDemo extends StatefulWidget {
  const NetworkPdfDemo({super.key});

  @override
  State<NetworkPdfDemo> createState() => _NetworkPdfDemoState();
}

class _NetworkPdfDemoState extends State<NetworkPdfDemo> {
  final controller = PageFlipController();
  int page = 0;
  int total = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoFrame(
      controller: controller,
      label: total == 0 ? 'Downloading…' : 'Page ${page + 1} of $total',
      child: PdfFlipBook.network(
        Uri.parse(samplePdfUrl),
        controller: controller,
        onLoaded: (count) => setState(() => total = count),
        onPageChanged: (value) => setState(() => page = value),
        loadingBuilder: (context, progress) => Center(
          child: SizedBox(
            width: 200,
            child: LinearProgressIndicator(value: progress),
          ),
        ),
        errorBuilder: (context, error, retry) => Center(
          child: FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Could not download. Retry'),
          ),
        ),
      ),
    );
  }
}

/// Plain widgets as pages: anything works, not only PDFs.
class WidgetsDemo extends StatelessWidget {
  const WidgetsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PageFlipView(
        itemCount: 8,
        itemBuilder: (context, index) => ColoredBox(
          color: Colors.primaries[index % Colors.primaries.length].shade100,
          child: Center(
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
        ),
      ),
    );
  }
}

/// The book with previous / next buttons and a page label under it.
class DemoFrame extends StatelessWidget {
  const DemoFrame({
    super.key,
    required this.controller,
    required this.label,
    required this.child,
    this.trailing,
  });

  final PageFlipController controller;
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
        Row(
          children: [
            IconButton(
              color: Colors.white,
              onPressed: controller.previous,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (trailing != null) trailing!,
            IconButton(
              color: Colors.white,
              onPressed: controller.next,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
