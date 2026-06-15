import 'dart:io';
import 'dart:ui' as ui;

import 'package:beer_tracker/models/beer_entry.dart';
import 'package:beer_tracker/screens/beer_detail_page.dart';
import 'package:beer_tracker/screens/settings_page.dart';
import 'package:beer_tracker/screens/stats_page.dart';
import 'package:beer_tracker/services/beer_repository.dart';
import 'package:beer_tracker/services/app_settings.dart';
import 'package:beer_tracker/widgets/beer_editor_sheet.dart';
import 'package:beer_tracker/widgets/feature_log_dialog.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = BeerRepository();
  final settings = AppSettings();
  await repository.load();
  await settings.load();
  await settings.bumpHeroSloganIndex();
  runApp(BeerTrackerApp(repository: repository, settings: settings));
}

class BeerTrackerApp extends StatelessWidget {
  BeerTrackerApp({
    super.key,
    required this.repository,
    AppSettings? settings,
    this.initialLayout = BeerLayout.grid,
    this.initialSortMode = BeerSortMode.best,
  }) : settings = settings ?? AppSettings();

  final BeerRepository repository;
  final AppSettings settings;
  final BeerLayout initialLayout;
  final BeerSortMode initialSortMode;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'PintDex',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          theme: buildPintDexTheme(settings.themePreset),
          home: BeerHomePage(
            repository: repository,
            settings: settings,
            initialLayout: initialLayout,
            initialSortMode: initialSortMode,
          ),
        );
      },
    );
  }
}

enum BeerLayout { list, grid }

enum BeerSortMode { title, best, oldest }

const List<String> _heroSlogans = [
  'One shelf to rule them all.',
  'Because beer deserves paperwork.',
  'Where labels go to be remembered.',
  'Half memory, half mash bill.',
  'Your beer, but with less guesswork.',
  'Catalog the chaos.',
  'For the bottle you almost forgot.',
  'A fancy filing cabinet for hops.',
  'Proof that you meant to save it.',
  'The home for your liquid notes.',
  'Collect the good ones. Remember the rest.',
  'Less guessing, more tasting.',
  'A shelf in your pocket.',
  'Keep calm and log the pint.',
  'Rate it now, thank yourself later.',
  'Beer memory, but organized.',
  'The receipt, but for beer.',
  'Drink it. Track it. Brag responsibly.',
  'Tiny archive, big flavor.',
  'A very serious hobby journal.',
];

class BeerHomePage extends StatefulWidget {
  const BeerHomePage({
    super.key,
    required this.repository,
    required this.settings,
    this.initialLayout = BeerLayout.grid,
    this.initialSortMode = BeerSortMode.best,
  });

  final BeerRepository repository;
  final AppSettings settings;
  final BeerLayout initialLayout;
  final BeerSortMode initialSortMode;

  @override
  State<BeerHomePage> createState() => _BeerHomePageState();
}

class _BeerHomePageState extends State<BeerHomePage> {
  late BeerLayout _layout;
  late BeerSortMode _sortMode;
  late final TextEditingController _searchController;
  late Set<BeerType> _selectedTypes;
  late String _searchQuery;
  late bool _favoritesOnly;
  bool _featureLogChecked = false;

  @override
  void initState() {
    super.initState();
    _layout = widget.initialLayout;
    _sortMode = widget.initialSortMode;
    _searchController = TextEditingController();
    _selectedTypes = <BeerType>{};
    _searchQuery = '';
    _favoritesOnly = widget.settings.showFavoritesOnlyOnHome;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showFeatureLogIfNeeded());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPhoneLayout = MediaQuery.sizeOf(context).width < 700;
    final currentSlogan = _heroSlogans[widget.settings.heroSloganIndex % _heroSlogans.length];

    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final beers = _sortedBeers(
          widget.repository.entries.where(_matchesFilters).toList(),
        );
        final hasAnyEntries = widget.repository.entries.isNotEmpty;
        final favorites = widget.repository.entries.where((beer) => beer.favorite).length;
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
                    titleSpacing: 0,
                    toolbarHeight: isPhoneLayout ? 72 : 56,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('PintDex'),
                        Text(
                          currentSlogan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Stats',
                        onPressed: _openStats,
                        icon: const Icon(Icons.bar_chart_rounded),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_rounded),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroCard(
                            total: beers.length,
                            average: average,
                            favorites: favorites,
                            favoritesOnly: _favoritesOnly,
                            onFavoritesTap: favorites == 0
                                ? null
                                : () {
                                    final nextValue = !_favoritesOnly;
                                    setState(() => _favoritesOnly = nextValue);
                                    widget.settings.setShowFavoritesOnlyOnHome(nextValue);
                                  },
                          ),
                          const SizedBox(height: 16),
                          if (widget.settings.showHomeTips) ...[
                            const _TipsStrip(),
                            const SizedBox(height: 14),
                          ],
                          if (_favoritesOnly) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() => _favoritesOnly = false);
                                  widget.settings.setShowFavoritesOnlyOnHome(false);
                                },
                                icon: const Icon(Icons.favorite_border_rounded),
                                label: const Text('Showing favorites only'),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: _openSearchSheet,
                                  icon: const Icon(Icons.search_rounded),
                                  label: const Text('Search'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: _openControlsSheet,
                                  icon: const Icon(Icons.tune_rounded),
                                  label: const Text('Filter'),
                                ),
                              ),
                            ],
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InputChip(
                                label: Text('Search: $_searchQuery'),
                                onDeleted: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            !hasAnyEntries
                                ? 'No beers yet. Add your first label photo.'
                                : beers.isEmpty
                                    ? 'No beers match your filters.'
                                    : '${beers.length} beers tracked',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  if (!hasAnyEntries)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _EmptyState(onAdd: _openEditor),
                      ),
                    )
                  else if (beers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _FilteredEmptyState(
                          onClear: _clearFilters,
                          query: _searchQuery,
                          selectedTypes: _selectedTypes,
                        ),
                      ),
                    )
                  else if (_layout == BeerLayout.grid)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: isPhoneLayout ? 0.84 : 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => BeerCard(
                            key: ValueKey(beers[index].id),
                            beer: beers[index],
                            compact: true,
                            dense: isPhoneLayout,
                            onTap: () => _openDetails(beers[index]),
                            onDrink: () => _drinkBeer(beers[index]),
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
                          key: ValueKey(beers[index].id),
                          beer: beers[index],
                          compact: false,
                          dense: isPhoneLayout,
                          onTap: () => _openDetails(beers[index]),
                          onDrink: () => _drinkBeer(beers[index]),
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

  bool _matchesFilters(BeerEntry beer) {
    if (_favoritesOnly && !beer.favorite) {
      return false;
    }

    final matchesType = _selectedTypes.isEmpty || _selectedTypes.contains(beer.type);
    if (!matchesType) {
      return false;
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final haystack = [
      beer.title,
      beer.type.label,
      beer.brewery,
      beer.style,
      beer.notes,
      beer.purchaseLocation,
      beer.abv?.toStringAsFixed(1) ?? '',
      beer.pricePerUnit?.toStringAsFixed(2) ?? '',
      beer.totalCost?.toStringAsFixed(2) ?? '',
    ].join(' ').toLowerCase();

    return haystack.contains(query);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedTypes = <BeerType>{};
    });
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
      MaterialPageRoute(builder: (context) => BeerDetailPage(repository: widget.repository, settings: widget.settings, beerId: beer.id)),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SettingsPage(repository: widget.repository, settings: widget.settings)),
    );
  }

  Future<void> _openStats() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => StatsPage(repository: widget.repository)),
    );
  }

  Future<void> _showFeatureLogIfNeeded() async {
    if (_featureLogChecked || !mounted) {
      return;
    }
    _featureLogChecked = true;
    if (widget.settings.lastSeenAppVersion == appVersion) {
      return;
    }

    await showFeatureLogDialog(context, version: appVersion);
    if (mounted) {
      await widget.settings.markFeatureLogSeen(appVersion);
    }
  }

  Future<void> _drinkBeer(BeerEntry beer) async {
    await widget.repository.recordDrink(beer.id);
  }

  Future<void> _openSearchSheet() async {
    final controller = TextEditingController(text: _searchQuery);
    final query = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search beers'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Name, brewery, location, notes',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clear();
              Navigator.of(context).pop('');
            },
            child: const Text('Clear'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Apply')),
        ],
      ),
    );

    controller.dispose();
    if (query != null) {
      setState(() => _searchQuery = query);
    }
  }

  Future<void> _openControlsSheet() async {
    final result = await showModalBottomSheet<_HomeControlsResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _HomeControlsSheet(
        initialLayout: _layout,
        initialSortMode: _sortMode,
        initialSelectedTypes: _selectedTypes,
      ),
    );

    if (result != null) {
      setState(() {
        _layout = result.layout;
        _sortMode = result.sortMode;
        _selectedTypes = result.selectedTypes;
      });
    }
  }
}

class BeerCard extends StatefulWidget {
  const BeerCard({super.key, required this.beer, required this.compact, required this.dense, required this.onTap, required this.onDrink, required this.onEdit});

  final BeerEntry beer;
  final bool compact;
  final bool dense;
  final VoidCallback onTap;
  final Future<void> Function() onDrink;
  final VoidCallback onEdit;

  @override
  State<BeerCard> createState() => _BeerCardState();
}

class _BeerCardState extends State<BeerCard> with SingleTickerProviderStateMixin {
  late final AnimationController _drinkController;
  bool _drinking = false;

  @override
  void initState() {
    super.initState();
    _drinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _drinkController.dispose();
    super.dispose();
  }

  Future<void> _handleLongPress() async {
    if (_drinking) {
      return;
    }

    setState(() => _drinking = true);
    try {
      await _drinkController.forward(from: 0);
      await widget.onDrink();
    } finally {
      if (mounted) {
        setState(() => _drinking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratingColor = _ratingColor(widget.beer.overallRating);

    return Material(
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: widget.onTap,
            onLongPress: _handleLongPress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ratingColor.withValues(alpha: 0.48), scheme.surfaceContainerHighest.withValues(alpha: 0.92)],
                ),
              ),
              child: widget.compact
                  ? _GridCardBody(beer: widget.beer, scheme: scheme, onEdit: widget.onEdit, context: context, dense: widget.dense)
                  : _ListCardBody(beer: widget.beer, scheme: scheme, onEdit: widget.onEdit, context: context, dense: widget.dense),
              ),
            ),
          if (_drinking || _drinkController.isAnimating)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _drinkController,
                  builder: (context, _) {
                    return _DrinkFillOverlay(progress: Curves.easeOutCubic.transform(_drinkController.value));
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridCardBody extends StatelessWidget {
  const _GridCardBody({required this.beer, required this.scheme, required this.onEdit, required this.context, required this.dense});

  final BeerEntry beer;
  final ColorScheme scheme;
  final VoidCallback onEdit;
  final BuildContext context;
  final bool dense;

  @override
  Widget build(BuildContext _) {
    final imageWidth = dense ? 88.0 : 104.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: imageWidth,
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
                  child: const Center(child: Icon(Icons.sports_bar_rounded, size: 34)),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.68)],
                  ),
                ),
              ),
              if (beer.favorite)
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(999)),
                    child: const Icon(Icons.favorite_rounded, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(dense ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beer.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: dense ? 15 : 16),
                ),
                const SizedBox(height: 4),
                Text(
                  beer.type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: dense ? 8 : 10),
                _RatingSummary(
                  overall: beer.overallRating,
                  sweetness: beer.sweetnessRating,
                  bitterness: beer.bitternessRating,
                  body: beer.bodyRating,
                  acidity: beer.acidityRating,
                  dense: dense,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${beer.createdAt.day}/${beer.createdAt.month}/${beer.createdAt.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _ListCardBody extends StatelessWidget {
  const _ListCardBody({required this.beer, required this.scheme, required this.onEdit, required this.context, required this.dense});

  final BeerEntry beer;
  final ColorScheme scheme;
  final VoidCallback onEdit;
  final BuildContext context;
  final bool dense;

  @override
  Widget build(BuildContext _) {
    return SizedBox(
      height: dense ? 206 : 264,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: dense ? 108 : 132,
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
              padding: EdgeInsets.all(dense ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (beer.favorite)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(999)),
                        child: const Icon(Icons.favorite_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  if (beer.favorite) const SizedBox(height: 6),
                  Text(
                    beer.title,
                    maxLines: dense ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: dense ? 16 : null),
                  ),
                  SizedBox(height: dense ? 8 : 10),
                  Text(beer.type.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  SizedBox(height: dense ? 10 : 14),
                  _RatingSummary(
                    overall: beer.overallRating,
                    sweetness: beer.sweetnessRating,
                    bitterness: beer.bitternessRating,
                    body: beer.bodyRating,
                    acidity: beer.acidityRating,
                    dense: dense,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${beer.createdAt.day}/${beer.createdAt.month}/${beer.createdAt.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

class _DrinkFillOverlay extends StatelessWidget {
  const _DrinkFillOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.12 * progress),
      child: Center(
        child: SizedBox(
          width: 122,
          height: 168,
          child: CustomPaint(
            painter: _BeerGlassPainter(
              progress: progress,
              fillColor: scheme.tertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BeerGlassPainter extends CustomPainter {
  const _BeerGlassPainter({required this.progress, required this.fillColor});

  final double progress;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final glassPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.82);

    final liquidPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor.withValues(alpha: 0.88);

    final foamPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.92);

    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.14);

    final left = size.width * 0.22;
    final right = size.width * 0.70;
    final top = size.height * 0.12;
    final bottom = size.height * 0.90;
    final centerX = size.width * 0.46;

    final glassPath = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(size.width * 0.62, bottom)
      ..lineTo(size.width * 0.30, bottom)
      ..close();

    final fillTop = ui.lerpDouble(bottom - 8, top + 18, progress.clamp(0.0, 1.0))!;
    final fillPath = Path()
      ..moveTo(left + 12, bottom - 8)
      ..lineTo(right - 12, bottom - 8)
      ..lineTo(size.width * 0.58, fillTop)
      ..lineTo(size.width * 0.34, fillTop)
      ..close();

    final foamHeight = ui.lerpDouble(4, 16, progress.clamp(0.0, 1.0))!;
    final foamPath = Path()
      ..moveTo(size.width * 0.34, fillTop)
      ..quadraticBezierTo(centerX - 18, fillTop - foamHeight, centerX - 2, fillTop + 1)
      ..quadraticBezierTo(centerX + 8, fillTop - foamHeight * 0.8, size.width * 0.58, fillTop)
      ..lineTo(size.width * 0.58, fillTop + 10)
      ..lineTo(size.width * 0.34, fillTop + 10)
      ..close();

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left + 8, top + 2, right - left - 16, bottom - top - 6), const Radius.circular(14)),
      shadowPaint,
    );
    canvas.drawPath(fillPath, liquidPaint);
    if (progress > 0.15) {
      canvas.drawPath(foamPath, foamPaint);
    }
    canvas.drawPath(glassPath, glassPaint);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.34);
    canvas.drawLine(
      Offset(size.width * 0.35, top + 8),
      Offset(size.width * 0.35, bottom - 18),
      highlightPaint,
    );

    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.55 * progress);
    canvas.drawCircle(Offset(size.width * 0.74, bottom - 42), 3.5, sparklePaint);
    canvas.drawCircle(Offset(size.width * 0.78, bottom - 62), 2.2, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant _BeerGlassPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.fillColor != fillColor;
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.overall,
    required this.sweetness,
    required this.bitterness,
    required this.body,
    required this.acidity,
    required this.dense,
  });

  final int overall;
  final int sweetness;
  final int bitterness;
  final int body;
  final int acidity;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall: $overall',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: dense ? 15 : 16),
        ),
        SizedBox(height: dense ? 6 : 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RatingChip(label: 'S', value: sweetness, color: scheme.tertiary),
            _RatingChip(label: 'B', value: bitterness, color: scheme.primary),
            _RatingChip(label: 'Bdy', value: body, color: scheme.secondary),
            _RatingChip(label: 'A', value: acidity, color: scheme.error),
          ],
        ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label:$value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.total,
    required this.average,
    required this.favorites,
    required this.favoritesOnly,
    required this.onFavoritesTap,
  });

  final int total;
  final double average;
  final int favorites;
  final bool favoritesOnly;
  final VoidCallback? onFavoritesTap;

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
              Expanded(child: _StatTile(label: 'Beers', value: '$total')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Avg rating', value: average == 0 ? '0.0' : average.toStringAsFixed(1))),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Favorites',
                  value: '$favorites',
                  onTap: onFavoritesTap,
                  selected: favoritesOnly,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipsStrip extends StatelessWidget {
  const _TipsStrip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _TipChip(icon: Icons.touch_app_rounded, text: 'Long-press cards to log a drink', color: scheme.tertiary),
        _TipChip(icon: Icons.zoom_out_map_rounded, text: 'Tap photos to zoom', color: scheme.primary),
        _TipChip(icon: Icons.download_rounded, text: 'Back up from Settings', color: scheme.secondary),
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _HomeControlsResult {
  const _HomeControlsResult({required this.layout, required this.sortMode, required this.selectedTypes});

  final BeerLayout layout;
  final BeerSortMode sortMode;
  final Set<BeerType> selectedTypes;
}

class _HomeControlsSheet extends StatefulWidget {
  const _HomeControlsSheet({required this.initialLayout, required this.initialSortMode, required this.initialSelectedTypes});

  final BeerLayout initialLayout;
  final BeerSortMode initialSortMode;
  final Set<BeerType> initialSelectedTypes;

  @override
  State<_HomeControlsSheet> createState() => _HomeControlsSheetState();
}

class _HomeControlsSheetState extends State<_HomeControlsSheet> {
  late BeerLayout _layout;
  late BeerSortMode _sortMode;
  late Set<BeerType> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _layout = widget.initialLayout;
    _sortMode = widget.initialSortMode;
    _selectedTypes = {...widget.initialSelectedTypes};
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allTypes = BeerType.values.where((type) => type != BeerType.all).toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter beers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Choose how the list looks and which beers show up.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              Text('View', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
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
                ],
              ),
              const SizedBox(height: 16),
              Text('Sort', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Types', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _selectedTypes = <BeerType>{}),
                    child: const Text('Any'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedTypes = {...allTypes}),
                    child: const Text('All'),
                  ),
                  TextButton(
                    onPressed: _selectedTypes.isEmpty ? null : () => setState(() => _selectedTypes.clear()),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final type in allTypes)
                    FilterChip(
                      label: Text(type.label),
                      selected: _selectedTypes.contains(type),
                      onSelected: (value) => setState(() {
                        if (value) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _HomeControlsResult(layout: _layout, sortMode: _sortMode, selectedTypes: _selectedTypes),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.onTap, this.selected = false});

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: selected ? scheme.tertiary.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? scheme.tertiary : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
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

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onClear, required this.query, required this.selectedTypes});

  final VoidCallback onClear;
  final String query;
  final Set<BeerType> selectedTypes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 72),
          const SizedBox(height: 16),
          Text('No beers match your filters', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            query.isEmpty && selectedTypes.isEmpty
                ? 'Try adjusting the list view.'
                : 'Clear search or type filters to show more beers.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: onClear, icon: const Icon(Icons.clear_rounded), label: const Text('Clear filters')),
        ],
      ),
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
