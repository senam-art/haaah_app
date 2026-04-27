import 'dart:convert';
import 'team.dart';
import 'venue.dart';

enum FixtureStatus { scheduled, live, finished, postponed }

FixtureStatus fixtureStatusFromString(String s) {
  switch (s.toUpperCase()) {
    case 'LIVE':
      return FixtureStatus.live;
    case 'FINISHED':
      return FixtureStatus.finished;
    case 'POSTPONED':
      return FixtureStatus.postponed;
    default:
      return FixtureStatus.scheduled;
  }
}

String fixtureStatusToString(FixtureStatus status) {
  switch (status) {
    case FixtureStatus.scheduled:
      return 'SCHEDULED';
    case FixtureStatus.live:
      return 'LIVE';
    case FixtureStatus.finished:
      return 'FINISHED';
    case FixtureStatus.postponed:
      return 'POSTPONED';
  }
}

class Fixture {
  final String id;
  final String? venueId;
  final String homeTeamId;
  final String awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final DateTime dateTime;
  final FixtureStatus status;
  final bool isLive;
  final DateTime? createdAt;
  final int attendanceCount;

  // Joined relations
  final Venue? venue;
  final Team? homeTeam;
  final Team? awayTeam;

  const Fixture({
    required this.id,
    this.venueId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore,
    this.awayScore,
    required this.dateTime,
    required this.status,
    this.isLive = false,
    this.createdAt,
    this.venue,
    this.homeTeam,
    this.awayTeam,
    this.attendanceCount = 0,
  });

  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      id: json['id'] as String,
      venueId: json['venue_id'] as String?,
      homeTeamId: json['home_team_id'] as String,
      awayTeamId: json['away_team_id'] as String,
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      dateTime: DateTime.parse(json['date_time'] as String),
      status: fixtureStatusFromString(json['status'] as String),
      isLive: json['is_live'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      venue: json['venues'] != null
          ? Venue.fromJson(json['venues'] as Map<String, dynamic>)
          : null,
      homeTeam: json['home_team'] != null
          ? Team.fromJson(json['home_team'] as Map<String, dynamic>)
          : null,
      awayTeam: json['away_team'] != null
          ? Team.fromJson(json['away_team'] as Map<String, dynamic>)
          : null,
      attendanceCount: _parseAttendanceCount(json['match_attendance']),
    );
  }

  static int _parseAttendanceCount(dynamic matchAttendance) {
    if (matchAttendance == null) return 0;
    if (matchAttendance is List && matchAttendance.isNotEmpty) {
      return matchAttendance[0]['count'] as int? ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'venue_id': venueId,
    'home_team_id': homeTeamId,
    'away_team_id': awayTeamId,
    'home_score': homeScore,
    'away_score': awayScore,
    'date_time': dateTime.toIso8601String(),
    'status': fixtureStatusToString(status),
    'is_live': isLive,
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'venue_id': venueId,
    'home_team_id': homeTeamId,
    'away_team_id': awayTeamId,
    'home_score': homeScore,
    'away_score': awayScore,
    'date_time': dateTime.toIso8601String(),
    'status': fixtureStatusToString(status),
    'is_live': isLive ? 1 : 0,
    'created_at': createdAt?.toIso8601String(),
    'home_team_json': homeTeam != null ? jsonEncode(homeTeam!.toJson()) : null,
    'away_team_json': awayTeam != null ? jsonEncode(awayTeam!.toJson()) : null,
    'venue_json': venue != null ? jsonEncode(venue!.toJson()) : null,
  };

  factory Fixture.fromSqlite(Map<String, dynamic> map) {
    return Fixture(
      id: map['id'] as String,
      venueId: map['venue_id'] as String?,
      homeTeamId: map['home_team_id'] as String,
      awayTeamId: map['away_team_id'] as String,
      homeScore: map['home_score'] as int?,
      awayScore: map['away_score'] as int?,
      dateTime: DateTime.parse(map['date_time'] as String),
      status: fixtureStatusFromString(map['status'] as String),
      isLive: (map['is_live'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      homeTeam: map['home_team_json'] != null
          ? Team.fromJson(jsonDecode(map['home_team_json'] as String))
          : null,
      awayTeam: map['away_team_json'] != null
          ? Team.fromJson(jsonDecode(map['away_team_json'] as String))
          : null,
      venue: map['venue_json'] != null
          ? Venue.fromJson(jsonDecode(map['venue_json'] as String))
          : null,
    );
  }
}
