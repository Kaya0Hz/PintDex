import 'dart:io';

import 'package:beer_tracker/models/beer_entry.dart';
import 'package:beer_tracker/widgets/beer_bottle_rating.dart';
import 'package:flutter/material.dart';

class BeerDetailPage extends StatelessWidget {
  const BeerDetailPage({super.key, required this.beer});

  final BeerEntry beer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = beer.imagePath.isEmpty ? null : File(beer.imagePath);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: scheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(beer.title),
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
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(image, fit: BoxFit.cover),
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Text('Ratings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  _InfoCard(
                    title: 'Beer type',
                    body: beer.type.label,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Sweetness', value: beer.sweetnessRating),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Bitterness', value: beer.bitternessRating),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Body', value: beer.bodyRating),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Acidity', value: beer.acidityRating),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Overall', value: beer.overallRating),
                  const SizedBox(height: 20),
                  _InfoCard(
                    title: 'Quick notes',
                    body: 'This version keeps the app simple and local-only. The label photo acts as the visual anchor for each beer.',
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          BeerBottleRating(value: value, onChanged: (_) {}, size: 26, spacing: 6),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primaryContainer, scheme.secondaryContainer]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    );
  }
}
