import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String appVersion = '0.1.0';

enum ThemePreset {
  defaultTheme,
  pink,
  rainbow,
  gothic,
  neon,
  darkMode,
}

extension ThemePresetLabel on ThemePreset {
  String get label => switch (this) {
        ThemePreset.defaultTheme => 'Default',
        ThemePreset.pink => 'Pink',
        ThemePreset.rainbow => 'Rainbow',
        ThemePreset.gothic => 'Gothic',
        ThemePreset.neon => 'Neon',
        ThemePreset.darkMode => 'Dark Mode',
      };

  Color get accent => switch (this) {
        ThemePreset.defaultTheme => const Color(0xFFE2A94C),
        ThemePreset.pink => const Color(0xFFFF78B0),
        ThemePreset.rainbow => const Color(0xFF6EE7FF),
        ThemePreset.gothic => const Color(0xFFC6A1FF),
        ThemePreset.neon => const Color(0xFF44FFCC),
        ThemePreset.darkMode => const Color(0xFFFFA23A),
      };

  String get storageKey => name;
}

ThemePreset themePresetFromStorage(Object? value) {
  if (value is String) {
    for (final preset in ThemePreset.values) {
      if (preset.name == value) {
        return preset;
      }
    }
  }
  return ThemePreset.defaultTheme;
}

class AppSettings extends ChangeNotifier {
  static const _fileName = 'app_settings.json';

  ThemePreset themePreset = ThemePreset.defaultTheme;
  bool showAdvancedBeerInfo = true;
  bool showPurchaseDetails = true;
  bool showDrinkHistory = true;
  bool confirmDrinkAgain = false;
  bool showFavoritesOnlyOnHome = false;
  bool showHomeTips = true;
  int heroSloganIndex = 0;
  String? lastSeenAppVersion;

  Directory? _baseDirectory;

  Future<void> load() async {
    _baseDirectory ??= await _resolveBaseDirectory();
    final file = File(p.join(_baseDirectory!.path, _fileName));
    if (!await file.exists()) {
      return;
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    themePreset = themePresetFromStorage(decoded['themePreset']);
    showAdvancedBeerInfo = decoded['showAdvancedBeerInfo'] as bool? ?? true;
    showPurchaseDetails = decoded['showPurchaseDetails'] as bool? ?? true;
    showDrinkHistory = decoded['showDrinkHistory'] as bool? ?? true;
    confirmDrinkAgain = decoded['confirmDrinkAgain'] as bool? ?? false;
    showFavoritesOnlyOnHome = decoded['showFavoritesOnlyOnHome'] as bool? ?? false;
    showHomeTips = decoded['showHomeTips'] as bool? ?? true;
    heroSloganIndex = decoded['heroSloganIndex'] as int? ?? 0;
    lastSeenAppVersion = decoded['lastSeenAppVersion'] as String?;
    notifyListeners();
  }

  Future<void> setThemePreset(ThemePreset value) async {
    if (themePreset == value) return;
    themePreset = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setShowAdvancedBeerInfo(bool value) async {
    if (showAdvancedBeerInfo == value) return;
    showAdvancedBeerInfo = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setShowPurchaseDetails(bool value) async {
    if (showPurchaseDetails == value) return;
    showPurchaseDetails = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setShowDrinkHistory(bool value) async {
    if (showDrinkHistory == value) return;
    showDrinkHistory = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setConfirmDrinkAgain(bool value) async {
    if (confirmDrinkAgain == value) return;
    confirmDrinkAgain = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setShowFavoritesOnlyOnHome(bool value) async {
    if (showFavoritesOnlyOnHome == value) return;
    showFavoritesOnlyOnHome = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setShowHomeTips(bool value) async {
    if (showHomeTips == value) return;
    showHomeTips = value;
    notifyListeners();
    await _persist();
  }

  Future<void> bumpHeroSloganIndex() async {
    heroSloganIndex += 1;
    notifyListeners();
    await _persist();
  }

  Future<void> markFeatureLogSeen(String version) async {
    if (lastSeenAppVersion == version) return;
    lastSeenAppVersion = version;
    notifyListeners();
    await _persist();
  }

  Map<String, Object?> toJson() => {
        'themePreset': themePreset.storageKey,
        'showAdvancedBeerInfo': showAdvancedBeerInfo,
        'showPurchaseDetails': showPurchaseDetails,
        'showDrinkHistory': showDrinkHistory,
        'confirmDrinkAgain': confirmDrinkAgain,
        'showFavoritesOnlyOnHome': showFavoritesOnlyOnHome,
        'showHomeTips': showHomeTips,
        'heroSloganIndex': heroSloganIndex,
        'lastSeenAppVersion': lastSeenAppVersion,
      };

  Future<void> _persist() async {
    _baseDirectory ??= await _resolveBaseDirectory();
    final file = File(p.join(_baseDirectory!.path, _fileName));
    if (!await _baseDirectory!.exists()) {
      await _baseDirectory!.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(toJson()));
  }

  Future<Directory> _resolveBaseDirectory() async {
    final base = await getApplicationSupportDirectory();
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    return base;
  }
}

ThemeData buildPintDexTheme(ThemePreset preset) {
  final palette = _paletteFor(preset);
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.seed,
    brightness: Brightness.dark,
  ).copyWith(
    surface: palette.surface,
    primaryContainer: palette.primaryContainer,
    secondaryContainer: palette.secondaryContainer,
    tertiary: palette.tertiary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
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
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? scheme.tertiary : scheme.outline),
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? scheme.tertiary.withValues(alpha: 0.35) : scheme.surfaceContainerHighest),
    ),
  );
}

_ThemePalette _paletteFor(ThemePreset preset) => switch (preset) {
      ThemePreset.defaultTheme => _ThemePalette(
          seed: const Color(0xFFB26A2B),
          background: const Color(0xFF0E0B0A),
          surface: const Color(0xFF151110),
          primaryContainer: const Color(0xFF3A2618),
          secondaryContainer: const Color(0xFF24312A),
          tertiary: const Color(0xFFE2A94C),
        ),
      ThemePreset.pink => _ThemePalette(
          seed: const Color(0xFFE91E63),
          background: const Color(0xFF140B11),
          surface: const Color(0xFF1B1018),
          primaryContainer: const Color(0xFF381A2A),
          secondaryContainer: const Color(0xFF2C1831),
          tertiary: const Color(0xFFFF7AB6),
        ),
      ThemePreset.rainbow => _ThemePalette(
          seed: const Color(0xFF6F63FF),
          background: const Color(0xFF0B1020),
          surface: const Color(0xFF121A33),
          primaryContainer: const Color(0xFF1E2450),
          secondaryContainer: const Color(0xFF173746),
          tertiary: const Color(0xFF6EE7FF),
        ),
      ThemePreset.gothic => _ThemePalette(
          seed: const Color(0xFF5B2A86),
          background: const Color(0xFF100C13),
          surface: const Color(0xFF17111D),
          primaryContainer: const Color(0xFF23152C),
          secondaryContainer: const Color(0xFF171824),
          tertiary: const Color(0xFFC6A1FF),
        ),
      ThemePreset.neon => _ThemePalette(
          seed: const Color(0xFF00E5FF),
          background: const Color(0xFF071112),
          surface: const Color(0xFF0C1A1C),
          primaryContainer: const Color(0xFF0E2B30),
          secondaryContainer: const Color(0xFF112A45),
          tertiary: const Color(0xFF44FFCC),
        ),
      ThemePreset.darkMode => _ThemePalette(
          seed: const Color(0xFFFF8A00),
          background: const Color(0xFF101010),
          surface: const Color(0xFF171717),
          primaryContainer: const Color(0xFF262626),
          secondaryContainer: const Color(0xFF1C1C1C),
          tertiary: const Color(0xFFFFA23A),
        ),
    };

class _ThemePalette {
  const _ThemePalette({
    required this.seed,
    required this.background,
    required this.surface,
    required this.primaryContainer,
    required this.secondaryContainer,
    required this.tertiary,
  });

  final Color seed;
  final Color background;
  final Color surface;
  final Color primaryContainer;
  final Color secondaryContainer;
  final Color tertiary;
}
