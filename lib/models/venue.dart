class Venue {
  final String id;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final double pricePerHour;
  final DateTime? createdAt;

  const Venue({
    required this.id,
    required this.name,
    this.address,
    required this.lat,
    required this.lng,
    required this.pricePerHour,
    this.createdAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
    'price_per_hour': pricePerHour,
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
    'price_per_hour': pricePerHour,
    'created_at': createdAt?.toIso8601String(),
  };

  factory Venue.fromSqlite(Map<String, dynamic> map) {
    return Venue(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      pricePerHour: (map['price_per_hour'] as num).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
