// lib/models/team_model.dart
class Team {
  final String id;
  final String name;
  final String logoUrl;
  final int points;
  final int gamesPlayed;
  final int goalsFor;
  final int goalsAgainst;

  Team({required this.id, required this.name, required this.logoUrl, 
        this.points = 0, this.gamesPlayed = 0, this.goalsFor = 0, this.goalsAgainst = 0});
}



