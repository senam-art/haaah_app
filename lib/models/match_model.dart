// lib/models/match_model.dart
class Match {
  final String id;
  final String homeTeamName;
  final String awayTeamName;
  final int? homeScore;
  final int? awayScore;
  final String venue; // e.g., "Ajax Park", "Legon"
  final DateTime matchDate;
  final bool isLive;

  Match({required this.id, required this.homeTeamName, required this.awayTeamName, 
         this.homeScore, this.awayScore, required this.venue, required this.matchDate, this.isLive = false});
}