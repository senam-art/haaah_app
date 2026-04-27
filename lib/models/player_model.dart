// lib/models/player_model.dart
class Player {
  final String id;
  final String name;
  final String position;
  final String teamName;
  final String profileImg;
  final int rating;
  
  // Stats
  final int goals;
  final int assists;
  final int appearances;
  final int motm; // Man of the Match

  // Attributes (0.0 to 1.0)
  final double pace;
  final double shooting;
  final double passing;
  final double dribbling;
  final double physical;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.teamName,
    required this.profileImg,
    this.rating = 0,
    this.goals = 0,
    this.assists = 0,
    this.appearances = 0,
    this.motm = 0,
    this.pace = 0.0,
    this.shooting = 0.0,
    this.passing = 0.0,
    this.dribbling = 0.0,
    this.physical = 0.0,
  });
}