import 'package:beer_tracker/widgets/beer_bottle_rating.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(ScreenshotsDemoApp(initialScreen: _screenFromUri(Uri.base)));
}

class ScreenshotsDemoApp extends StatelessWidget {
  const ScreenshotsDemoApp({super.key, required this.initialScreen});

  final DemoScreen initialScreen;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB26A2B),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF151110),
      primaryContainer: const Color(0xFF3A2618),
      secondaryContainer: const Color(0xFF24312A),
      tertiary: const Color(0xFFE2A94C),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0E0B0A),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
      home: _DemoHomePage(initialScreen: initialScreen),
    );
  }
}

enum DemoScreen { grid, list, editor, detail }

class _DemoHomePage extends StatefulWidget {
  const _DemoHomePage({required this.initialScreen});

  final DemoScreen initialScreen;

  @override
  State<_DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<_DemoHomePage> {
  late DemoScreen _screen;

  @override
  void initState() {
    super.initState();
    _screen = widget.initialScreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1210), Color(0xFF0E0B0A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    const Expanded(child: Text('PintDex', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
                    PopupMenuButton<DemoScreen>(
                      initialValue: _screen,
                      onSelected: (value) => setState(() => _screen = value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: DemoScreen.grid, child: Text('Grid')),
                        PopupMenuItem(value: DemoScreen.list, child: Text('List')),
                        PopupMenuItem(value: DemoScreen.editor, child: Text('Editor')),
                        PopupMenuItem(value: DemoScreen.detail, child: Text('Detail')),
                      ],
                      child: const Icon(Icons.more_vert_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_screen) {
                    DemoScreen.grid => const _GridScreen(key: ValueKey('grid')),
                    DemoScreen.list => const _ListScreen(key: ValueKey('list')),
                    DemoScreen.editor => const _EditorScreen(key: ValueKey('editor')),
                    DemoScreen.detail => const _DetailScreen(key: ValueKey('detail')),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DemoScreen _screenFromUri(Uri uri) {
  return switch (uri.queryParameters['screen']) {
    'list' => DemoScreen.list,
    'editor' => DemoScreen.editor,
    'detail' => DemoScreen.detail,
    _ => DemoScreen.grid,
  };
}

class _BeerSeed {
  const _BeerSeed(this.title, this.flavor, this.sourness, this.overall, this.color);

  final String title;
  final int flavor;
  final int sourness;
  final int overall;
  final Color color;
}

const _beers = [
  _BeerSeed('Sunset Hazy IPA', 5, 1, 5, Color(0xFFB26A2B)),
  _BeerSeed('Forest Sour', 3, 5, 4, Color(0xFF355A42)),
  _BeerSeed('Midnight Stout', 5, 1, 5, Color(0xFF2A2324)),
  _BeerSeed('Amber Lager', 4, 1, 3, Color(0xFF9A5C29)),
];

class _GridScreen extends StatelessWidget {
  const _GridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _HeroCard(total: _beers.length, average: 4.3),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _Pill(label: 'List view', selected: false),
            _Pill(label: 'Box view', selected: true),
            _Pill(label: 'A-Z', selected: false),
            _Pill(label: '5 to 1 bottles', selected: true),
          ],
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _beers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) => _BeerCard(seed: _beers[index]),
        ),
      ],
    );
  }
}

class _ListScreen extends StatelessWidget {
  const _ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _HeroCard(total: _beers.length, average: 4.3),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _Pill(label: 'List view', selected: true),
            _Pill(label: 'Box view', selected: false),
            _Pill(label: 'A-Z', selected: true),
            _Pill(label: '5 to 1 bottles', selected: false),
          ],
        ),
        const SizedBox(height: 18),
        ..._beers.map((beer) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _BeerListCard(seed: beer),
            )),
      ],
    );
  }
}

class _EditorScreen extends StatelessWidget {
  const _EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add beer', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Use the label photo as the visual title and rate the pour.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(colors: [Color(0xFF3A2618), Color(0xFF24312A)]),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_rounded, size: 48),
                      SizedBox(height: 12),
                      Text('Add a label photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      SizedBox(height: 6),
                      Text('Capture on Android or pick a file on Linux'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const TextField(decoration: InputDecoration(labelText: 'Beer title', hintText: 'Optional manual name')),
              const SizedBox(height: 20),
              const _RatingEditor(label: 'Sweetness', value: 3),
              const SizedBox(height: 18),
              const _RatingEditor(label: 'Bitterness', value: 2),
              const SizedBox(height: 18),
              const _RatingEditor(label: 'Body', value: 5),
              const SizedBox(height: 18),
              const _RatingEditor(label: 'Acidity', value: 3),
              const SizedBox(height: 18),
              const _RatingEditor(label: 'Overall', value: 4),
              const SizedBox(height: 24),
              FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.save_rounded), label: const Text('Save beer')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailScreen extends StatelessWidget {
  const _DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Sunset Hazy IPA'),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFB26A2B), Color(0xFF24312A)]),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                Text('Ratings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                const _DetailRow(label: 'Sweetness', value: 5),
                const SizedBox(height: 12),
                const _DetailRow(label: 'Bitterness', value: 1),
                const SizedBox(height: 12),
                const _DetailRow(label: 'Body', value: 5),
                const SizedBox(height: 12),
                const _DetailRow(label: 'Acidity', value: 3),
                const SizedBox(height: 12),
                const _DetailRow(label: 'Overall', value: 5),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF3A2618), Color(0xFF24312A)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      SizedBox(height: 8),
                      Text('Local-only beer tracking with label photos, bottle ratings, list and box views.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.total, required this.average});

  final int total;
  final double average;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primaryContainer, scheme.secondaryContainer]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Track every pour', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text('Label photos, bottle ratings, list or box view, all stored locally.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer.withValues(alpha: 0.85))),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Beers', value: '$total')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Avg rating', value: average.toStringAsFixed(1))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      backgroundColor: selected ? scheme.tertiary.withValues(alpha: 0.22) : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      side: BorderSide(color: selected ? scheme.tertiary : scheme.outlineVariant),
    );
  }
}

class _BeerCard extends StatelessWidget {
  const _BeerCard({required this.seed});

  final _BeerSeed seed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [seed.color, scheme.secondaryContainer])),
                  child: const Center(child: Icon(Icons.local_bar_rounded, size: 44)),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)]),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seed.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      BeerBottleRating(value: seed.overall, onChanged: (_) {}, size: 24, spacing: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricLine(label: 'Sweetness', value: seed.flavor),
                const SizedBox(height: 8),
                _MetricLine(label: 'Bitterness', value: seed.sourness),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeerListCard extends StatelessWidget {
  const _BeerListCard({required this.seed});

  final _BeerSeed seed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 160,
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [seed.color, scheme.secondaryContainer])),
                child: const Center(child: Icon(Icons.local_bar_rounded, size: 44)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seed.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    BeerBottleRating(value: seed.overall, onChanged: (_) {}, size: 26, spacing: 4),
                    const SizedBox(height: 16),
                    _MetricLine(label: 'Sweetness', value: seed.flavor),
                    const SizedBox(height: 10),
                    _MetricLine(label: 'Bitterness', value: seed.sourness),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        BeerBottleRating(value: value, onChanged: (_) {}, size: 20, spacing: 3),
      ],
    );
  }
}

class _RatingEditor extends StatelessWidget {
  const _RatingEditor({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
          child: BeerBottleRating(value: value, onChanged: (_) {}),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          BeerBottleRating(value: value, onChanged: (_) {}, size: 26, spacing: 6),
        ],
      ),
    );
  }
}
