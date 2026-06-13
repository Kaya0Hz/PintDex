import 'dart:convert';

enum BeerType {
  all,
  sour,
  ale,
  stout,
  lager,
  ipa,
  porter,
  wheat,
  pilsner,
  amber,
  other,
}

extension BeerTypeLabel on BeerType {
  String get label => switch (this) {
        BeerType.all => 'All types',
        BeerType.sour => 'Sour',
        BeerType.ale => 'Ale',
        BeerType.stout => 'Stout',
        BeerType.lager => 'Lager',
        BeerType.ipa => 'IPA',
        BeerType.porter => 'Porter',
        BeerType.wheat => 'Wheat',
        BeerType.pilsner => 'Pilsner',
        BeerType.amber => 'Amber',
        BeerType.other => 'Other',
      };

  String get storageKey => name;

  static BeerType fromJsonValue(Object? value) {
    if (value is String) {
      for (final entry in BeerType.values) {
        if (entry.name == value) {
          return entry;
        }
      }
    }
    return BeerType.ale;
  }
}

const int beerRatingMax = 10;

const String _legacyFlavorKey = 'flavorRating';
const String _legacySournessKey = 'sournessRating';
const String _legacyMaltinessKey = 'maltinessRating';
const String _legacyHoppinessKey = 'hoppinessRating';

const String _breweryKey = 'brewery';
const String _styleKey = 'style';
const String _abvKey = 'abv';
const String _notesKey = 'notes';
const String _purchaseLocationTypeKey = 'purchaseLocationType';
const String _purchaseLocationKey = 'purchaseLocation';
const String _legacyPurchasedFromKey = 'purchasedFrom';
const String _purchaseDateKey = 'purchaseDate';
const String _pricePerUnitKey = 'pricePerUnit';
const String _totalCostKey = 'totalCost';
const String _favoriteKey = 'favorite';
const String _drinkHistoryKey = 'drinkHistory';

enum PurchaseLocationType {
  bottleShop,
  brewery,
  pub,
  bar,
  other,
}

extension PurchaseLocationTypeLabel on PurchaseLocationType {
  String get label => switch (this) {
        PurchaseLocationType.bottleShop => 'Bottle shop',
        PurchaseLocationType.brewery => 'Brewery',
        PurchaseLocationType.pub => 'Pub',
        PurchaseLocationType.bar => 'Bar',
        PurchaseLocationType.other => 'Other',
      };

  String get storageKey => name;

  static PurchaseLocationType fromJsonValue(Object? value) {
    if (value is String) {
      for (final entry in PurchaseLocationType.values) {
        if (entry.name == value) {
          return entry;
        }
      }
    }
    return PurchaseLocationType.other;
  }
}

class BeerEntry {
  const BeerEntry({
    required this.id,
    required this.title,
    required this.imagePath,
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
    required this.favorite,
    required this.drinkHistory,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String imagePath;
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
  final bool favorite;
  final List<DateTime> drinkHistory;
  final DateTime createdAt;

  String get purchasedFrom => purchaseLocation;

  BeerEntry copyWith({
    String? title,
    String? imagePath,
    BeerType? type,
    int? sweetnessRating,
    int? bitternessRating,
    int? bodyRating,
    int? acidityRating,
    int? overallRating,
    String? brewery,
    String? style,
    double? abv,
    String? notes,
    PurchaseLocationType? purchaseLocationType,
    String? purchaseLocation,
    DateTime? purchaseDate,
    double? pricePerUnit,
    double? totalCost,
    bool? favorite,
    List<DateTime>? drinkHistory,
  }) {
    return BeerEntry(
      id: id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      sweetnessRating: sweetnessRating ?? this.sweetnessRating,
      bitternessRating: bitternessRating ?? this.bitternessRating,
      bodyRating: bodyRating ?? this.bodyRating,
      acidityRating: acidityRating ?? this.acidityRating,
      overallRating: overallRating ?? this.overallRating,
      brewery: brewery ?? this.brewery,
      style: style ?? this.style,
      abv: abv ?? this.abv,
      notes: notes ?? this.notes,
      purchaseLocationType: purchaseLocationType ?? this.purchaseLocationType,
      purchaseLocation: purchaseLocation ?? this.purchaseLocation,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalCost: totalCost ?? this.totalCost,
      favorite: favorite ?? this.favorite,
      drinkHistory: drinkHistory ?? this.drinkHistory,
      createdAt: createdAt,
    );
  }

  int get timesDrunk => drinkHistory.length;

  DateTime? get lastDrank => drinkHistory.isEmpty ? null : drinkHistory.last;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'imagePath': imagePath,
        'type': type.storageKey,
        'sweetnessRating': sweetnessRating,
        'bitternessRating': bitternessRating,
        'bodyRating': bodyRating,
        'acidityRating': acidityRating,
        'overallRating': overallRating,
        _breweryKey: brewery,
        _styleKey: style,
        _abvKey: abv,
        _notesKey: notes,
        _purchaseLocationTypeKey: purchaseLocationType.storageKey,
        _purchaseLocationKey: purchaseLocation,
        _legacyPurchasedFromKey: purchaseLocation,
        _purchaseDateKey: purchaseDate?.toIso8601String(),
        _pricePerUnitKey: pricePerUnit,
        _totalCostKey: totalCost,
        _favoriteKey: favorite,
        _drinkHistoryKey: drinkHistory.map((item) => item.toIso8601String()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory BeerEntry.fromJson(Map<String, dynamic> json) {
    return BeerEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      imagePath: json['imagePath'] as String,
      type: BeerTypeLabel.fromJsonValue(json['type']),
      sweetnessRating: _toRating(json['sweetnessRating'] ?? json[_legacyFlavorKey]),
      bitternessRating: _toRating(json['bitternessRating'] ?? json[_legacyHoppinessKey] ?? json[_legacyFlavorKey]),
      bodyRating: _toRating(json['bodyRating'] ?? json[_legacyMaltinessKey] ?? json[_legacyFlavorKey]),
      acidityRating: _toRating(json['acidityRating'] ?? json[_legacySournessKey]),
      overallRating: _toRating(json['overallRating']),
      brewery: (json[_breweryKey] as String?) ?? '',
      style: (json[_styleKey] as String?) ?? '',
      abv: _toNullableDouble(json[_abvKey]),
      notes: (json[_notesKey] as String?) ?? '',
      purchaseLocationType: PurchaseLocationTypeLabel.fromJsonValue(json[_purchaseLocationTypeKey]),
      purchaseLocation: (json[_purchaseLocationKey] as String?) ?? (json[_legacyPurchasedFromKey] as String?) ?? '',
      purchaseDate: _toNullableDateTime(json[_purchaseDateKey]),
      pricePerUnit: _toNullableDouble(json[_pricePerUnitKey]),
      totalCost: _toNullableDouble(json[_totalCostKey]),
      favorite: json[_favoriteKey] as bool? ?? false,
      drinkHistory: _toDrinkHistory(json[_drinkHistoryKey]),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory BeerEntry.fromJsonString(String source) =>
      BeerEntry.fromJson(jsonDecode(source) as Map<String, dynamic>);

  static int _toRating(Object? value) {
    final raw = value is num ? value.toInt() : 0;
    return raw.clamp(1, beerRatingMax);
  }

  static double? _toNullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String && value.trim().isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime? _toNullableDateTime(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<DateTime> _toDrinkHistory(Object? value) {
    if (value is List) {
      return value
          .map((item) => item is String ? DateTime.tryParse(item) : null)
          .whereType<DateTime>()
          .toList()
        ..sort();
    }
    return const [];
  }
}
