class Team {
  final String id;
  final String name;
  final String? logoUrl;
  final String? managerId;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int points;
  final DateTime? createdAt;

  const Team({
    required this.id,
    required this.name,
    this.logoUrl,
    this.managerId,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.points = 0,
    this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      managerId: json['manager_id'] as String?,
      played: json['played'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      drawn: json['drawn'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo_url': logoUrl,
    'manager_id': managerId,
    'played': played,
    'won': won,
    'drawn': drawn,
    'lost': lost,
    'points': points,
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'name': name,
    'logo_url': logoUrl,
    'manager_id': managerId,
    'played': played,
    'won': won,
    'drawn': drawn,
    'lost': lost,
    'points': points,
    'created_at': createdAt?.toIso8601String(),
  };

  factory Team.fromSqlite(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      logoUrl: map['logo_url'] as String?,
      managerId: map['manager_id'] as String?,
      played: map['played'] as int? ?? 0,
      won: map['won'] as int? ?? 0,
      drawn: map['drawn'] as int? ?? 0,
      lost: map['lost'] as int? ?? 0,
      points: map['points'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
