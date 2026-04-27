import 'package:flutter/material.dart';
import '../../models/team.dart';
import '../../services/league_service.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Team team;
  const TeamDetailsScreen({super.key, required this.team});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final _leagueService = LeagueService();
  bool _loading = true;
  List<Map<String, dynamic>> _roster = [];

  static const neonGreen = Color(0xFF00FF85);
  static const bgBlack = Color(0xFF0A0A0A);
  static const cardGrey = Color(0xFF141414);

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    setState(() => _loading = true);
    try {
      final roster = await _leagueService.getTeamRoster(widget.team.id);
      if (mounted) {
        setState(() {
          _roster = roster;
        });
      }
    } catch (e) {
      debugPrint("Error loading team roster: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        title: Text(widget.team.name.toUpperCase(), style: const TextStyle(color: neonGreen, fontWeight: FontWeight.w900)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: neonGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamHeader(),
                  const SizedBox(height: 30),
                  const Text("SQUAD", style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 10),
                  _buildRosterList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTeamHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: neonGreen.withValues(alpha: 0.1),
            backgroundImage: widget.team.logoUrl != null ? NetworkImage(widget.team.logoUrl!) : null,
            child: widget.team.logoUrl == null
                ? const Icon(Icons.shield, size: 40, color: neonGreen)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team.name,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatBox("PLAYED", "${widget.team.played}"),
                    const SizedBox(width: 10),
                    _buildStatBox("WON", "${widget.team.won}"),
                    const SizedBox(width: 10),
                    _buildStatBox("PTS", "${widget.team.points}", highlight: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: highlight ? neonGreen : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildRosterList() {
    if (_roster.isEmpty) {
      return const Center(child: Text("No players found.", style: TextStyle(color: Colors.white54)));
    }

    // Sort: CONFIRMED first, then INVITED
    _roster.sort((a, b) {
      final statusA = a['status'] as String;
      final statusB = b['status'] as String;
      if (statusA == 'CONFIRMED' && statusB != 'CONFIRMED') return -1;
      if (statusA != 'CONFIRMED' && statusB == 'CONFIRMED') return 1;
      return 0;
    });

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _roster.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final playerRow = _roster[index];
        final profile = playerRow['profiles'];
        final position = playerRow['position'] as String;
        final status = playerRow['status'] as String;
        
        final isConfirmed = status == 'CONFIRMED';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isConfirmed ? neonGreen.withValues(alpha: 0.2) : Colors.white10,
                child: Text(
                  profile['name'].toString().substring(0, 1).toUpperCase(),
                  style: TextStyle(color: isConfirmed ? neonGreen : Colors.white54),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['name'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Position: $position",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isConfirmed)
                const Icon(Icons.check_circle, color: neonGreen, size: 20)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("PENDING", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }
}
