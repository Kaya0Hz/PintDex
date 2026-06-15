import 'dart:io';

import 'package:beer_tracker/models/beer_entry.dart';
import 'package:beer_tracker/services/beer_repository.dart';
import 'package:beer_tracker/services/app_settings.dart';
import 'package:beer_tracker/widgets/beer_bottle_rating.dart';
import 'package:beer_tracker/widgets/beer_editor_sheet.dart';
import 'package:beer_tracker/widgets/image_preview_dialog.dart';
import 'package:flutter/material.dart';

class BeerDetailPage extends StatelessWidget {
  const BeerDetailPage({super.key, required this.repository, required this.settings, required this.beerId});

  final BeerRepository repository;
  final AppSettings settings;
  final String beerId;

  @override
  Widget build(BuildContext context) {
    final isPhoneLayout = MediaQuery.sizeOf(context).width < 700;
    return AnimatedBuilder(
      animation: Listenable.merge([repository, settings]),
      builder: (context, _) {
        final matches = repository.entries.where((item) => item.id == beerId).toList();
        final beer = matches.isEmpty ? null : matches.first;
        if (beer == null) {
          return const Scaffold(
            body: Center(child: Text('Beer not found')),
          );
        }

        final scheme = Theme.of(context).colorScheme;
        final image = beer.imagePath.isEmpty ? null : File(beer.imagePath);
        final recentDrinks = beer.drinkHistory.reversed.take(5).toList();
        final olderDrinks = beer.drinkHistory.reversed.skip(5).toList();

          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _recordDrink(context, beer),
              icon: const Icon(Icons.local_drink_rounded),
              label: const Text('Drink again'),
            ),
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: isPhoneLayout ? 250 : 340,
                  pinned: true,
                  stretch: true,
                  backgroundColor: scheme.surface,
                actions: [
                  if (image != null)
                    IconButton(
                      tooltip: 'View photo',
                      onPressed: () => showImagePreview(context, image.path, title: beer.title),
                      icon: const Icon(Icons.zoom_out_map_rounded),
                    ),
                  IconButton(
                    tooltip: beer.favorite ? 'Unfavorite' : 'Favorite',
                    onPressed: () => repository.toggleFavorite(beer.id),
                    icon: Icon(beer.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                  ),
                  IconButton(
                    tooltip: 'Edit beer',
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => BeerEditorSheet(repository: repository, initial: beer),
                    ),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(beer.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  background: image == null
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [scheme.primary, scheme.tertiary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(child: Icon(Icons.sports_bar_rounded, size: 96, color: Colors.white70)),
                        )
                      : GestureDetector(
                          onTap: () => showImagePreview(context, image.path, title: beer.title),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(tag: image.path, child: Image.file(image, fit: BoxFit.cover)),
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
                ),
                ),
                SliverPadding(
                padding: EdgeInsets.fromLTRB(isPhoneLayout ? 14 : 20, isPhoneLayout ? 14 : 20, isPhoneLayout ? 14 : 20, 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _OverviewCard(beer: beer, compact: isPhoneLayout),
                      SizedBox(height: isPhoneLayout ? 14 : 18),
                      _SectionTitle('Ratings'),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Sweetness', value: beer.sweetnessRating, compact: isPhoneLayout),
                      SizedBox(height: isPhoneLayout ? 10 : 12),
                      _DetailRow(label: 'Bitterness', value: beer.bitternessRating, compact: isPhoneLayout),
                      SizedBox(height: isPhoneLayout ? 10 : 12),
                      _DetailRow(label: 'Body', value: beer.bodyRating, compact: isPhoneLayout),
                      SizedBox(height: isPhoneLayout ? 10 : 12),
                      _DetailRow(label: 'Acidity', value: beer.acidityRating, compact: isPhoneLayout),
                      SizedBox(height: isPhoneLayout ? 10 : 12),
                      _DetailRow(label: 'Overall', value: beer.overallRating, compact: isPhoneLayout),
                        _InfoCard(title: 'Notes', value: beer.notes, compact: isPhoneLayout),
                        _InfoCard(title: 'Brewery', value: beer.brewery, compact: isPhoneLayout),
                        SizedBox(height: isPhoneLayout ? 10 : 12),
                        _InfoCard(title: 'Purchase location', value: beer.purchaseLocation, compact: isPhoneLayout),
                        SizedBox(height: isPhoneLayout ? 10 : 12),
                        _InfoCard(title: 'Purchase type', value: beer.purchaseLocationType.label, compact: isPhoneLayout),
                        SizedBox(height: isPhoneLayout ? 10 : 12),
                        _InfoCard(title: 'Price per unit', value: _money(beer.pricePerUnit), compact: isPhoneLayout),
                        if (settings.showAdvancedBeerInfo) ...[
                          SizedBox(height: isPhoneLayout ? 14 : 18),
                          _SectionTitle('Beer details'),
                          const SizedBox(height: 12),
                          _InfoCard(title: 'Style', value: beer.style, compact: isPhoneLayout),
                          SizedBox(height: isPhoneLayout ? 10 : 12),
                          _InfoCard(title: 'ABV', value: beer.abv == null ? '' : '${beer.abv!.toStringAsFixed(1)}%', compact: isPhoneLayout),
                        ],
                       if (settings.showPurchaseDetails) ...[
                         SizedBox(height: isPhoneLayout ? 14 : 18),
                         _SectionTitle('Purchase details'),
                         const SizedBox(height: 12),
                         ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          title: const Text('More purchase details'),
                          subtitle: Text(beer.purchaseDate == null ? 'No purchase date saved' : _formatDate(context, beer.purchaseDate)),
                          children: [
                             _InfoCard(title: 'Total cost', value: _money(beer.totalCost), compact: isPhoneLayout),
                             const SizedBox(height: 12),
                             _InfoCard(title: 'Purchase date', value: _formatDate(context, beer.purchaseDate), compact: isPhoneLayout),
                          ],
                        ),
                      ],
                      if (settings.showDrinkHistory) ...[
                         SizedBox(height: isPhoneLayout ? 14 : 18),
                         _SectionTitle('Drink history'),
                       ],
                       SizedBox(height: isPhoneLayout ? 10 : 12),
                       _InfoCard(title: 'Times drunk', value: beer.timesDrunk.toString(), compact: isPhoneLayout),
                       SizedBox(height: isPhoneLayout ? 10 : 12),
                       _InfoCard(title: 'Last drank', value: beer.lastDrank == null ? 'Not set' : _formatDateTime(context, beer.lastDrank!), compact: isPhoneLayout),
                       if (settings.showDrinkHistory) ...[
                         SizedBox(height: isPhoneLayout ? 10 : 12),
                         if (beer.drinkHistory.isEmpty)
                          const _EmptyHistoryCard()
                        else ...[
                          Column(
                            children: [
                              for (final drink in recentDrinks) ...[
                                _DrinkHistoryTile(
                                  when: drink,
                                  onDelete: () => repository.removeDrink(beer.id, drink),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ),
                          if (olderDrinks.isNotEmpty)
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text('Older drinks (${olderDrinks.length})'),
                              childrenPadding: const EdgeInsets.only(bottom: 8),
                              children: [
                                const SizedBox(height: 6),
                                Column(
                                  children: [
                                    for (final drink in olderDrinks) ...[
                                      _DrinkHistoryTile(
                                        when: drink,
                                        onDelete: () => repository.removeDrink(beer.id, drink),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recordDrink(BuildContext context, BeerEntry beer) async {
    if (!settings.confirmDrinkAgain) {
      await repository.recordDrink(beer.id);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add drink entry?'),
        content: Text('Log another drink for ${beer.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Log it')),
        ],
      ),
    );

    if (confirmed == true) {
      await repository.recordDrink(beer.id);
    }
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.beer, required this.compact});

  final BeerEntry beer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primaryContainer, scheme.secondaryContainer]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  beer.title,
                  maxLines: compact ? 2 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: (compact ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineSmall)
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (beer.favorite) const Icon(Icons.favorite_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Text(beer.type.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: compact ? 15 : null)),
          const SizedBox(height: 12),
          BeerBottleRating(value: beer.overallRating, onChanged: (_) {}, size: compact ? 22 : 26, spacing: compact ? 4 : 6),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
               _Pill(label: '${beer.timesDrunk} drinks', compact: compact),
               _Pill(label: beer.lastDrank == null ? 'Never drank' : 'Last drank ${_formatDateTime(context, beer.lastDrank!)}', compact: compact),
                if (beer.purchaseLocation.isNotEmpty) _Pill(label: beer.purchaseLocation, compact: compact),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900));
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.compact = false});

  final String label;
  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: compact ? 14 : null)),
          ),
          BeerBottleRating(value: value, onChanged: (_) {}, size: compact ? 22 : 26, spacing: compact ? 4 : 6),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value, this.compact = false});

  final String title;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: compact ? 12 : null)),
          const SizedBox(height: 6),
          Text(value.isEmpty ? 'Not set' : value, maxLines: compact ? 2 : null, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DrinkHistoryTile extends StatelessWidget {
  const _DrinkHistoryTile({required this.when, required this.onDelete});

  final DateTime when;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded),
          const SizedBox(width: 12),
          Expanded(child: Text(_formatDateTime(context, when))),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('No drink history yet.'),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

String _money(double? value) => value == null ? '' : '\$${value.toStringAsFixed(2)}';

String _formatDate(BuildContext context, DateTime? value) {
  if (value == null) {
    return 'Not set';
  }
  return MaterialLocalizations.of(context).formatMediumDate(value);
}

String _formatDateTime(BuildContext context, DateTime value) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(value)} at ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
}
