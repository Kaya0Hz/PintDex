import 'package:flutter/material.dart';

Future<void> showFeatureLogDialog(BuildContext context, {required String version}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text('What\'s New in v$version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A quick look at the main things you can do in PintDex.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            _LogLine(color: scheme.tertiary, text: 'Local-only beer tracker with backup/export on device.'),
            _LogLine(color: scheme.tertiary, text: 'Add beers with photos, notes, ratings, and purchase details.'),
            _LogLine(color: scheme.tertiary, text: 'Long-press a beer card to log a drink.'),
            _LogLine(color: scheme.tertiary, text: 'Tap beer photos to zoom in.'),
            _LogLine(color: scheme.tertiary, text: 'Search, sort, switch list or grid, and filter by type.'),
            _LogLine(color: scheme.tertiary, text: 'Use Favorites, Stats, themes, and Settings from the home screen.'),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
        ],
      );
    },
  );
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 8, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
