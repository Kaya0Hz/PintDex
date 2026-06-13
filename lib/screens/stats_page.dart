import 'package:beer_tracker/models/beer_entry.dart';
import 'package:beer_tracker/services/beer_repository.dart';
import 'package:flutter/material.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.repository});

  final BeerRepository repository;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final beers = repository.entries;
        final totalDrinks = beers.fold<int>(0, (sum, beer) => sum + beer.timesDrunk);
        final favorites = beers.where((beer) => beer.favorite).length;
        final avgRating = beers.isEmpty ? 0.0 : beers.map((beer) => beer.overallRating).reduce((a, b) => a + b) / beers.length;
        final mostDrunk = [...beers]..sort((a, b) => b.timesDrunk.compareTo(a.timesDrunk));
        final latestDrink = _latestDrink(beers);
        final breweryCount = beers.where((beer) => beer.brewery.trim().isNotEmpty).map((beer) => beer.brewery.trim()).toSet().length;
        final favoriteBeer = beers.where((beer) => beer.favorite).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Stats')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _SummaryCard(
                title: 'Overview',
                children: [
                  _StatRow(label: 'Beers logged', value: beers.length.toString()),
                  _StatRow(label: 'Drinks logged', value: totalDrinks.toString()),
                  _StatRow(label: 'Favorites', value: favorites.toString()),
                  _StatRow(label: 'Average rating', value: beers.isEmpty ? '0.0' : avgRating.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 18),
              _SummaryCard(
                title: 'Highlights',
                children: [
                  _StatRow(label: 'Most drunk', value: mostDrunk.isEmpty ? 'None' : '${mostDrunk.first.title} (${mostDrunk.first.timesDrunk})'),
                  _StatRow(label: 'Last drank', value: latestDrink == null ? 'None yet' : _formatDateTime(context, latestDrink)),
                  _StatRow(label: 'Unique breweries', value: breweryCount.toString()),
                  _StatRow(label: 'Favorite beer', value: favoriteBeer.isEmpty ? 'None yet' : favoriteBeer.first.title),
                ],
              ),
              const SizedBox(height: 18),
              _SummaryCard(
                title: 'Top beers',
                children: [
                  if (beers.isEmpty)
                    const Text('Add a few beers to see rankings.')
                  else
                    for (final beer in [...beers]..sort((a, b) => b.overallRating.compareTo(a.overallRating))) ...[
                      _BeerStatTile(beer: beer),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  DateTime? _latestDrink(List<BeerEntry> beers) {
    final drinks = beers.expand((beer) => beer.drinkHistory).toList()..sort();
    return drinks.isEmpty ? null : drinks.last;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BeerStatTile extends StatelessWidget {
  const _BeerStatTile({required this.beer});

  final BeerEntry beer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(beer.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${beer.overallRating}/10 · ${beer.type.label}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text('${beer.timesDrunk} drinks'),
        ],
      ),
    );
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(value)} at ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
}
