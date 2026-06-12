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
  final DateTime createdAt;

  BeerEntry copyWith({
    String? title,
    String? imagePath,
    BeerType? type,
    int? sweetnessRating,
    int? bitternessRating,
    int? bodyRating,
    int? acidityRating,
    int? overallRating,
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
      createdAt: createdAt,
    );
  }

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
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory BeerEntry.fromJsonString(String source) =>
      BeerEntry.fromJson(jsonDecode(source) as Map<String, dynamic>);

  static int _toRating(Object? value) {
    final raw = value is num ? value.toInt() : 0;
    return raw.clamp(1, beerRatingMax);
  }
}
