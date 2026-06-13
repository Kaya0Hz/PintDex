import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:beer_tracker/models/beer_entry.dart';
import 'package:path_provider/path_provider.dart';

class BeerRepository extends ChangeNotifier {
  final List<BeerEntry> _entries = [];
  Directory? _baseDirectory;

  BeerRepository({Iterable<BeerEntry>? seedEntries}) {
    if (seedEntries != null) {
      _entries.addAll(seedEntries);
    }
  }

  List<BeerEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    _baseDirectory ??= await _resolveBaseDirectory();
    final file = File(p.join(_baseDirectory!.path, 'beers.json'));

    if (!await file.exists()) {
      _entries.clear();
      return;
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as List<dynamic>;
    _entries
      ..clear()
      ..addAll(
        decoded.map(
          (item) => BeerEntry.fromJson(item as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  Future<void> upsertBeer({BeerEntry? existing, required BeerDraft draft}) async {
    _baseDirectory ??= await _resolveBaseDirectory();
    final imagePath = draft.image == null
        ? existing?.imagePath
        : await _importImage(draft.image!);

    final entry = BeerEntry(
      id: existing?.id ?? _createId(),
      title: draft.title.trim().isEmpty ? 'Untitled beer' : draft.title.trim(),
      imagePath: imagePath ?? existing?.imagePath ?? '',
      type: draft.type,
      sweetnessRating: draft.sweetnessRating,
      bitternessRating: draft.bitternessRating,
      bodyRating: draft.bodyRating,
      acidityRating: draft.acidityRating,
      overallRating: draft.overallRating,
      brewery: draft.brewery.trim(),
      style: draft.style.trim(),
      abv: draft.abv,
      notes: draft.notes.trim(),
      purchaseLocationType: draft.purchaseLocationType,
      purchaseLocation: draft.purchaseLocation.trim(),
      purchaseDate: draft.purchaseDate,
      pricePerUnit: draft.pricePerUnit,
      totalCost: draft.totalCost,
      favorite: existing?.favorite ?? false,
      drinkHistory: existing?.drinkHistory ?? <DateTime>[],
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    if (existing != null) {
      _entries.removeWhere((item) => item.id == existing.id);
    }

    _entries.add(entry);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persist();
    notifyListeners();
  }

  Future<void> replaceBeer(BeerEntry entry) async {
    _entries.removeWhere((item) => item.id == entry.id);
    _entries.add(entry);
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persist();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _entries.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final updated = _entries[index].copyWith(favorite: !_entries[index].favorite);
    _entries[index] = updated;
    await _persist();
    notifyListeners();
  }

  Future<void> recordDrink(String id, {DateTime? when}) async {
    final index = _entries.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final updated = _entries[index].copyWith(
      drinkHistory: [..._entries[index].drinkHistory, when ?? DateTime.now()]..sort(),
    );
    _entries[index] = updated;
    await _persist();
    notifyListeners();
  }

  Future<void> removeDrink(String id, DateTime when) async {
    final index = _entries.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final updated = _entries[index].copyWith(
      drinkHistory: _entries[index].drinkHistory.where((item) => item != when).toList(),
    );
    _entries[index] = updated;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteBeer(String id) async {
    _entries.removeWhere((item) => item.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> exportBackup(String path) async {
    final backup = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'beers': _entries.map((item) => item.toJson()).toList(),
    };
    await File(path).writeAsString(jsonEncode(backup));
  }

  Future<int> importBackup(String path) async {
    final raw = await File(path).readAsString();
    final decoded = jsonDecode(raw);

    final List<dynamic> beersJson = decoded is Map<String, dynamic>
        ? (decoded['beers'] as List<dynamic>? ?? const [])
        : decoded is List<dynamic>
            ? decoded
            : const [];

    final imported = beersJson
        .map((item) => BeerEntry.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _entries
      ..clear()
      ..addAll(imported);
    await _persist();
    notifyListeners();
    return imported.length;
  }

  Future<String?> _importImage(XFile file) async {
    final base = _baseDirectory ??= await _resolveBaseDirectory();
    final imageDir = Directory(p.join(base.path, 'images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final extension = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final destination = p.join(imageDir.path, '${_createId()}$extension');
    final copied = await File(file.path).copy(destination);
    return copied.path;
  }

  Future<void> _persist() async {
    final base = _baseDirectory ??= await _resolveBaseDirectory();
    final file = File(p.join(base.path, 'beers.json'));
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(_entries.map((item) => item.toJson()).toList()));
  }

  Future<Directory> _resolveBaseDirectory() async {
    final base = await getApplicationSupportDirectory();
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    return base;
  }

  String _createId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class BeerDraft {
  const BeerDraft({
    required this.title,
    required this.type,
    required this.sweetnessRating,
    required this.bitternessRating,
    required this.bodyRating,
    required this.acidityRating,
    required this.overallRating,
    required this.brewery,
    required this.style,
    required this.abv,
    required this.notes,
    required this.purchaseLocationType,
    required this.purchaseLocation,
    required this.purchaseDate,
    required this.pricePerUnit,
    required this.totalCost,
    this.image,
  });

  final String title;
  final BeerType type;
  final int sweetnessRating;
  final int bitternessRating;
  final int bodyRating;
  final int acidityRating;
  final int overallRating;
  final String brewery;
  final String style;
  final double? abv;
  final String notes;
  final PurchaseLocationType purchaseLocationType;
  final String purchaseLocation;
  final DateTime? purchaseDate;
  final double? pricePerUnit;
  final double? totalCost;
  final XFile? image;
}
