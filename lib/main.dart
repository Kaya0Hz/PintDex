import 'package:beer_tracker/models/beer_entry.dart';
import 'package:beer_tracker/screens/beer_detail_page.dart';
import 'package:beer_tracker/services/beer_repository.dart';
import 'package:beer_tracker/widgets/beer_bottle_rating.dart';
import 'package:beer_tracker/widgets/beer_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = BeerRepository();
  await repository.load();
  runApp(BeerTrackerApp(repository: repository));
}

class BeerTrackerApp extends StatelessWidget {
  const BeerTrackerApp({
    super.key,
    required this.repository,
    this.initialLayout = BeerLayout.grid,
    this.initialSortMode = BeerSortMode.best,
  });

  final BeerRepository repository;
  final BeerLayout initialLayout;
  final BeerSortMode initialSortMode;

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
      title: 'PintDex',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0E0B0A),
        cardTheme: CardThemeData(
          color: scheme.surfaceContainerHighest,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
      home: BeerHomePage(
        repository: repository,
        initialLayout: initialLayout,
        initialSortMode: initialSortMode,
      ),
    );
  }
}

enum BeerLayout { list, grid }

enum BeerSortMode { title, best, oldest }

class BeerHomePage extends StatefulWidget {
  const BeerHomePage({
    super.key,
    required this.repository,
    this.initialLayout = BeerLayout.grid,
    this.initialSortMode = BeerSortMode.best,
  });

  final BeerRepository repository;
  final BeerLayout initialLayout;
  final BeerSortMode initialSortMode;

  @override
  State<BeerHomePage> createState() => _BeerHomePageState();
}

class _BeerHomePageState extends State<BeerHomePage> {
  late BeerLayout _layout;
  late BeerSortMode _sortMode;
  BeerType _selectedType = BeerType.all;

  @override
  void initState() {
    super.initState();
    _layout = widget.initialLayout;
    _sortMode = widget.initialSortMode;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final beers = _sortedBeers(
          widget.repository.entries.where((beer) => _selectedType == BeerType.all || beer.type == _selectedType).toList(),
        );
        final average = beers.isEmpty
            ? 0.0
            : beers.map((beer) => beer.overallRating).reduce((a, b) => a + b) / beers.length;

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
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 16, top: 10, bottom: 10),
                      child: PintDexMark(size: 36),
                    ),
                    leadingWidth: 60,
                    title: const Text('PintDex'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroCard(total: beers.length, average: average),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _ModeChip<BeerLayout>(
                                label: 'List view',
                                value: BeerLayout.list,
                                groupValue: _layout,
                                onSelected: (value) => setState(() => _layout = value),
                              ),
                              _ModeChip<BeerLayout>(
                                label: 'Box view',
                                value: BeerLayout.grid,
                                groupValue: _layout,
                                onSelected: (value) => setState(() => _layout = value),
                              ),
                              _ModeChip<BeerSortMode>(
                                label: 'A-Z',
                                value: BeerSortMode.title,
                                groupValue: _sortMode,
                                onSelected: (value) => setState(() => _sortMode = value),
                              ),
                              _ModeChip<BeerSortMode>(
                                label: '10 to 1',
                                value: BeerSortMode.best,
                                groupValue: _sortMode,
                                onSelected: (value) => setState(() => _sortMode = value),
                              ),
                              _ModeChip<BeerSortMode>(
                                label: 'Oldest',
                                value: BeerSortMode.oldest,
                                groupValue: _sortMode,
                                onSelected: (value) => setState(() => _sortMode = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _TypeChip(
                                label: 'All',
                                selected: _selectedType == BeerType.all,
                                onTap: () => setState(() => _selectedType = BeerType.all),
                              ),
                              for (final type in _commonTypes)
                                _TypeChip(
                                  label: type.label,
                                  selected: _selectedType == type,
                                  onTap: () => setState(() => _selectedType = type),
                                ),
                              _TypeChip(
                                label: _selectedType == BeerType.all || _commonTypes.contains(_selectedType) ? 'More' : '${_selectedType.label} *',
                                selected: _selectedType != BeerType.all && !_commonTypes.contains(_selectedType),
                                onTap: _openMoreTypeSheet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            beers.isEmpty ? 'No beers yet. Add your first label photo.' : '${beers.length} beers tracked',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  if (beers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _EmptyState(onAdd: _openEditor),
                      ),
                    )
                  else if (_layout == BeerLayout.grid)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => BeerCard(
                            beer: beers[index],
                            compact: true,
                            onTap: () => _openDetails(beers[index]),
                            onEdit: () => _openEditor(existing: beers[index]),
                          ),
                          childCount: beers.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverList.separated(
                        itemCount: beers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) => BeerCard(
                          beer: beers[index],
                          compact: false,
                          onTap: () => _openDetails(beers[index]),
                          onEdit: () => _openEditor(existing: beers[index]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openEditor,
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: const Text('Add beer'),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        );
      },
    );
  }

  List<BeerEntry> _sortedBeers(List<BeerEntry> beers) {
    final sorted = [...beers];
    switch (_sortMode) {
      case BeerSortMode.title:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case BeerSortMode.best:
        sorted.sort((a, b) => b.overallRating.compareTo(a.overallRating));
        break;
      case BeerSortMode.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return sorted;
  }

  Future<void> _openEditor({BeerEntry? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BeerEditorSheet(repository: widget.repository, initial: existing),
    );
  }

  Future<void> _openDetails(BeerEntry beer) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => BeerDetailPage(beer: beer)),
    );
  }

  static const List<BeerType> _commonTypes = [
    BeerType.ipa,
    BeerType.lager,
    BeerType.ale,
    BeerType.stout,
    BeerType.sour,
  ];

  Future<void> _openMoreTypeSheet() async {
    final picked = await showModalBottomSheet<BeerType>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final extraTypes = BeerType.values.where((type) => type != BeerType.all && !_commonTypes.contains(type)).toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('More types', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final type in extraTypes)
                      ChoiceChip(
                        label: Text(type.label),
                        selected: _selectedType == type,
                        onSelected: (_) => Navigator.of(context).pop(type),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedType = picked);
    }
  }
}

class BeerCard extends StatelessWidget {
  const BeerCard({super.key, required this.beer, required this.compact, required this.onTap, required this.onEdit});

  final BeerEntry beer;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratingColor = _ratingColor(beer.overallRating);

    return Material(
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ratingColor.withValues(alpha: 0.48), scheme.surfaceContainerHighest.withValues(alpha: 0.92)],
            ),
          ),
          child: compact
              ? _GridCardBody(beer: beer, scheme: scheme, onEdit: onEdit, context: context)
              : _ListCardBody(beer: beer, scheme: scheme, onEdit: onEdit, context: context),
        ),
      ),
    );
  }
}

class _GridCardBody extends StatelessWidget {
  const _GridCardBody({required this.beer, required this.scheme, required this.onEdit, required this.context});

  final BeerEntry beer;
  final ColorScheme scheme;
  final VoidCallback onEdit;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (beer.imagePath.isNotEmpty)
                Image.file(File(beer.imagePath), fit: BoxFit.cover)
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.primaryContainer, scheme.secondaryContainer],
                    ),
                  ),
                  child: const Center(child: Icon(Icons.sports_bar_rounded, size: 40)),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    BeerBottleRating(value: beer.overallRating, onChanged: (_) {}, size: 15, spacing: 2),
                    const SizedBox(height: 8),
                    Text(beer.type.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.w700)),
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
              _MetricLine(label: 'Sweetness', value: beer.sweetnessRating),
              const SizedBox(height: 8),
              _MetricLine(label: 'Bitterness', value: beer.bitternessRating),
              const SizedBox(height: 8),
              _MetricLine(label: 'Body', value: beer.bodyRating),
              const SizedBox(height: 8),
              _MetricLine(label: 'Acidity', value: beer.acidityRating),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${beer.type.label} · ${beer.createdAt.day}/${beer.createdAt.month}/${beer.createdAt.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded), visualDensity: VisualDensity.compact),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListCardBody extends StatelessWidget {
  const _ListCardBody({required this.beer, required this.scheme, required this.onEdit, required this.context});

  final BeerEntry beer;
  final ColorScheme scheme;
  final VoidCallback onEdit;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return SizedBox(
      height: 264,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 132,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (beer.imagePath.isNotEmpty)
                  Image.file(File(beer.imagePath), fit: BoxFit.cover)
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primaryContainer, scheme.secondaryContainer],
                      ),
                    ),
                    child: const Center(child: Icon(Icons.sports_bar_rounded, size: 40)),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beer.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  BeerBottleRating(value: beer.overallRating, onChanged: (_) {}, size: 15, spacing: 2),
                  const SizedBox(height: 8),
                  Text(beer.type.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  _MetricLine(label: 'Sweetness', value: beer.sweetnessRating),
                  const SizedBox(height: 8),
                  _MetricLine(label: 'Bitterness', value: beer.bitternessRating),
                  const SizedBox(height: 8),
                  _MetricLine(label: 'Body', value: beer.bodyRating),
                  const SizedBox(height: 8),
                  _MetricLine(label: 'Acidity', value: beer.acidityRating),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${beer.createdAt.day}/${beer.createdAt.month}/${beer.createdAt.year}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded), visualDensity: VisualDensity.compact),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PintDexMark(size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Because "I had one good beer" is not a tasting note.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Label photos, bottle ratings, list or box view, all stored locally.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer.withValues(alpha: 0.85))),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Beers', value: '$total')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Avg rating', value: average == 0 ? '0.0' : average.toStringAsFixed(1))),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
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

class _ModeChip<T> extends StatelessWidget {
  const _ModeChip({required this.label, required this.value, required this.groupValue, required this.onSelected});

  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: scheme.tertiary.withValues(alpha: 0.22),
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      labelStyle: TextStyle(color: selected ? scheme.onSurface : scheme.onSurfaceVariant),
      side: BorderSide(color: selected ? scheme.tertiary : scheme.outlineVariant),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      side: BorderSide(color: selected ? scheme.tertiary : scheme.outlineVariant),
      backgroundColor: selected ? scheme.tertiary.withValues(alpha: 0.22) : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      labelStyle: TextStyle(color: selected ? scheme.onSurface : scheme.onSurfaceVariant),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer]),
            ),
            child: const Center(child: PintDexMark(size: 58)),
          ),
          const SizedBox(height: 18),
          Text('Your shelf is empty', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Add a bottle, snap the label, and start rating.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_photo_alternate_rounded), label: const Text('Add first beer')),
        ],
      ),
    );
  }
}

class PintDexMark extends StatelessWidget {
  const PintDexMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PintDexMarkPainter(
          fillColor: Theme.of(context).colorScheme.tertiary,
        ),
      ),
    );
  }
}

class _PintDexMarkPainter extends CustomPainter {
  const _PintDexMarkPainter({required this.fillColor});

  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final glassLeft = size.width * 0.22;
    final glassRight = size.width * 0.68;
    final glassTop = size.height * 0.18;
    final glassBottom = size.height * 0.88;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black;

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: 0.18);

    final glass = Path()
      ..moveTo(glassLeft, glassTop)
      ..lineTo(glassRight, glassTop)
      ..lineTo(glassRight, glassBottom)
      ..lineTo(glassLeft, glassBottom)
      ..close();

    final handle = Path()
      ..moveTo(size.width * 0.69, size.height * 0.32)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.32, size.width * 0.9, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.72, size.width * 0.69, size.height * 0.72)
      ..lineTo(size.width * 0.69, size.height * 0.63)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.63, size.width * 0.8, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.41, size.width * 0.69, size.height * 0.41)
      ..close();

    final foam = Path()
      ..moveTo(glassLeft, glassTop)
      ..quadraticBezierTo(size.width * 0.31, size.height * 0.07, size.width * 0.39, size.height * 0.17)
      ..quadraticBezierTo(size.width * 0.46, size.height * 0.06, size.width * 0.53, size.height * 0.16)
      ..quadraticBezierTo(size.width * 0.59, size.height * 0.08, glassRight, glassTop)
      ..close();

    canvas.drawPath(glass, shadowPaint);
    canvas.drawPath(handle, shadowPaint);
    canvas.drawPath(foam, shadowPaint);

    canvas.drawPath(glass, fillPaint);
    canvas.drawPath(handle, fillPaint);
    canvas.drawPath(foam, fillPaint);

    canvas.drawPath(glass, outlinePaint);
    canvas.drawPath(handle, outlinePaint);
    canvas.drawPath(foam, outlinePaint);

    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..color = Colors.white.withValues(alpha: 0.34);
    canvas.drawLine(
      Offset(size.width * 0.39, size.height * 0.24),
      Offset(size.width * 0.39, size.height * 0.8),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _PintDexMarkPainter oldDelegate) => oldDelegate.fillColor != fillColor;
}

Color _ratingColor(int rating) {
  final t = ((rating.clamp(1, beerRatingMax) - 1) / (beerRatingMax - 1)).toDouble();
  return Color.lerp(const Color(0xFFFF8A00), const Color(0xFF19B36A), t)!;
}
