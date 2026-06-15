import 'package:beer_tracker/services/beer_repository.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:beer_tracker/services/app_settings.dart';
import 'package:beer_tracker/widgets/feature_log_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.repository, required this.settings});

  final BeerRepository repository;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _SectionCard(
                title: 'Themes',
                subtitle: 'Pick a look for PintDex.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final preset in ThemePreset.values)
                      _ThemeChip(
                        preset: preset,
                        selected: settings.themePreset == preset,
                        onTap: () => settings.setThemePreset(preset),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Profile sections',
                subtitle: 'Hide the extra stuff when you want a cleaner profile.',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show advanced beer info'),
                      subtitle: const Text('Brewery, style, and ABV'),
                      value: settings.showAdvancedBeerInfo,
                      onChanged: (value) => settings.setShowAdvancedBeerInfo(value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show purchase details'),
                      subtitle: const Text('Total cost and purchase date'),
                      value: settings.showPurchaseDetails,
                      onChanged: (value) => settings.setShowPurchaseDetails(value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show drink history'),
                      subtitle: const Text('The full list of drink dates'),
                      value: settings.showDrinkHistory,
                      onChanged: (value) => settings.setShowDrinkHistory(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Behavior',
                subtitle: 'Small workflow touches.',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Confirm drink logging'),
                  subtitle: const Text('Ask before adding a new drink entry'),
                  value: settings.confirmDrinkAgain,
                  onChanged: (value) => settings.setConfirmDrinkAgain(value),
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Home tips',
                subtitle: 'Show or hide the quick usage hints on the home screen.',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show profile tips'),
                  subtitle: const Text('Long-press, zoom, and backup hints'),
                  value: settings.showHomeTips,
                  onChanged: (value) => settings.setShowHomeTips(value),
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Backup',
                subtitle: 'Export or import your local beer data.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _exportBackup(context),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Export backup'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _importBackup(context),
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Import backup'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'What\'s New',
                subtitle: 'Open the release notes for this version.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      settings.lastSeenAppVersion == appVersion
                          ? 'You are up to date on this device.'
                          : 'There are new release notes waiting for you.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await showFeatureLogDialog(context, version: appVersion);
                        if (context.mounted) {
                          await settings.markFeatureLogSeen(appVersion);
                        }
                      },
                      icon: const Icon(Icons.new_releases_rounded),
                      label: const Text('View release notes'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'v$appVersion · Changes save locally on this device.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final location = await getSaveLocation(
      suggestedName: 'pintdex-backup.json',
      confirmButtonText: 'Save backup',
      acceptedTypeGroups: [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (location == null) {
      return;
    }

    await repository.exportBackup(location.path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup exported')));
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text('This will replace the current beer list with the backup file contents.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Import')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final count = await repository.importBackup(file.path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $count beers')));
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

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
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.preset, required this.selected, required this.onTap});

  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: preset.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(preset.label),
        ],
      ),
      selectedColor: preset.accent.withValues(alpha: 0.25),
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
    );
  }
}
