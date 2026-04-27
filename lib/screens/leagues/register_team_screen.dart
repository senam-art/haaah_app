import 'package:flutter/material.dart';
import '../../services/league_service.dart';
import '../../services/auth_service.dart';
import '../../models/profile.dart';

class RegisterTeamScreen extends StatefulWidget {
  const RegisterTeamScreen({super.key});

  @override
  State<RegisterTeamScreen> createState() => _RegisterTeamScreenState();
}

class _RegisterTeamScreenState extends State<RegisterTeamScreen> {
  final _teamNameController = TextEditingController();
  final _searchController = TextEditingController();

  final _leagueService = LeagueService();
  final _authService = AuthService();

  // This list holds our added players
  final List<Profile> _squad = [];

  // Search results
  List<Profile> _searchResults = [];
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _isPlayingManager = true;

  static const neonGreen = Color(0xFF00FF85);
  static const bgBlack = Color(0xFF0A0A0A);
  static const cardGrey = Color(0xFF141414);

  void _searchPlayers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _leagueService.searchProfiles(query.trim());
      // Filter out the manager themselves if they are logged in
      final managerId = _authService.currentUserId;
      final filtered = results.where((p) => p.id != managerId).toList();

      setState(() {
        _searchResults = filtered;
      });
    } catch (e) {
      debugPrint('Search failed: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addPlayer(Profile player) {
    if (_squad.length < 10 && !_squad.any((p) => p.id == player.id)) {
      setState(() {
        _squad.add(player);
        _searchController.clear();
        _searchResults.clear();
      });
    }
  }

  Future<void> _submitTeam() async {
    final teamName = _teamNameController.text.trim();
    if (teamName.isEmpty || _squad.length < 10) return;

    setState(() => _isSubmitting = true);

    try {
      final managerId = _authService.currentUserId;
      if (managerId == null) throw Exception("Manager not logged in.");

      final managerProfile = _authService.currentProfile;
      final managerPosition = managerProfile?.position ?? 'SUB';

      // 1. Register the team
      final team = await _leagueService.registerTeam(
        name: teamName,
        managerId: managerId,
        isPlayingManager: _isPlayingManager,
        managerPosition: managerPosition,
      );

      // 2. Invite the players
      await _leagueService.invitePlayersToTeam(team.id, _squad);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Squad confirmed! Invites sent.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error registering team: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(backgroundColor: bgBlack, elevation: 0, title: const Text("BUILD YOUR SQUAD")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "TEAM NAME",
              style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildTextField(_teamNameController, "e.g. Osu Titans FC", Icons.shield_rounded),

            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: cardGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SwitchListTile(
                title: const Text(
                  "I will be playing in this team",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  "If disabled, you will be added as a Manager only.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: _isPlayingManager,
                activeColor: neonGreen,
                onChanged: (val) {
                  setState(() => _isPlayingManager = val);
                },
              ),
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ADD PLAYERS",
                  style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  "${_squad.length} / 10",
                  style: TextStyle(
                    color: _squad.length == 10 ? neonGreen : Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SEARCH BOX
            _buildTextField(
              _searchController,
              "Search by username...",
              Icons.person_search,
              onChanged: _searchPlayers,
            ),

            // SEARCH RESULTS
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(color: neonGreen)),
              )
            else if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: cardGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final player = _searchResults[index];
                    final isAlreadyAdded = _squad.any((p) => p.id == player.id);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: neonGreen.withValues(alpha: 0.2),
                        child: Text(player.initials, style: const TextStyle(color: neonGreen)),
                      ),
                      title: Text(player.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        "Pos: ${player.position} • OVR: ${player.overallRating}",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: isAlreadyAdded
                          ? const Icon(Icons.check_circle, color: neonGreen)
                          : IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: neonGreen),
                              onPressed: () => _addPlayer(player),
                            ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // SQUAD CHIPS AREA
            const Text(
              "CURRENT SQUAD",
              style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: _squad.isEmpty
                  ? const Center(
                      child: Text("No players added yet.", style: TextStyle(color: Colors.white10)),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _squad
                          .map(
                            (player) => InputChip(
                              label: Text("${player.name} (${player.position})"),
                              labelStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              backgroundColor: neonGreen,
                              deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.black),
                              onDeleted: () {
                                setState(() => _squad.remove(player));
                              },
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                          .toList(),
                    ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _squad.length == 10 && !_isSubmitting ? _submitTeam : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonGreen,
                  disabledBackgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text(
                        _squad.length == 10
                            ? "CONFIRM SQUAD & SEND INVITES"
                            : "ADD ${10 - _squad.length} MORE",
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: cardGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
