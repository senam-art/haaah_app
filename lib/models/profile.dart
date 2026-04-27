class Profile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String position;
  
  // Sunday League Stats
  final int goals;
  final int assists;
  final int appearances;
  final int motm;

  // Attributes (0-99)
  final int pace;
  final int shooting;
  final int dribbling;
  final int physical;

  final DateTime? createdAt;

  const Profile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.position = 'SUB',
    this.goals = 0,
    this.assists = 0,
    this.appearances = 0,
    this.motm = 0,
    this.pace = 75,
    this.shooting = 75,
    this.dribbling = 75,
    this.physical = 75,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      position: json['position'] as String? ?? 'SUB',
      goals: json['goals'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      appearances: json['appearances'] as int? ?? 0,
      motm: json['motm'] as int? ?? 0,
      pace: json['pace'] as int? ?? 75,
      shooting: json['shooting'] as int? ?? 75,
      dribbling: json['dribbling'] as int? ?? 75,
      physical: json['physical'] as int? ?? 75,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar_url': avatarUrl,
    'position': position,
    'goals': goals,
    'assists': assists,
    'appearances': appearances,
    'motm': motm,
    'pace': pace,
    'shooting': shooting,
    'dribbling': dribbling,
    'physical': physical,
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar_url': avatarUrl,
    'position': position,
    'goals': goals,
    'assists': assists,
    'appearances': appearances,
    'motm': motm,
    'pace': pace,
    'shooting': shooting,
    'dribbling': dribbling,
    'physical': physical,
    'created_at': createdAt?.toIso8601String(),
  };

  factory Profile.fromSqlite(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatar_url'] as String?,
      position: map['position'] as String? ?? 'SUB',
      goals: map['goals'] as int? ?? 0,
      assists: map['assists'] as int? ?? 0,
      appearances: map['appearances'] as int? ?? 0,
      motm: map['motm'] as int? ?? 0,
      pace: map['pace'] as int? ?? 75,
      shooting: map['shooting'] as int? ?? 75,
      dribbling: map['dribbling'] as int? ?? 75,
      physical: map['physical'] as int? ?? 75,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Calculates the player's overall rating based on stats and attributes
  int get overallRating {
    double base = (pace + shooting + dribbling + physical) / 4;
    double bonus = 0;
    if (appearances > 0) {
      bonus = (goals * 0.5 + motm * 2) / (appearances / 10);
    }
    return (base + bonus).clamp(0, 99).toInt();
  }

  /// Returns the user's initials for avatar display.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
