import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'register_team_screen.dart';
import '../../services/league_service.dart';
import '../../services/fixture_service.dart';
import '../../services/auth_service.dart';
import '../../models/team.dart';
import '../../models/fixture.dart';
import '../../widgets/qr_code_popup.dart';

class LeagueListScreen extends StatefulWidget {
  const LeagueListScreen({super.key});

  @override
  State<LeagueListScreen> createState() => _LeagueListScreenState();
}

class _LeagueListScreenState extends State<LeagueListScreen> {
  bool _showStandings = true; // Toggle state

  final _leagueService = LeagueService();
  final _fixtureService = FixtureService();
  final _authService = AuthService();

  List<Team> _teams = [];
  List<Fixture> _fixtures = [];
  List<Map<String, dynamic>> _invites = [];
  bool _loading = true;

  static const neonGreen = Color(0xFF00FF85);
  static const bgBlack = Color(0xFF0A0A0A);
  static const cardGrey = Color(0xFF141414);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final teams = await _leagueService.fetchStandings();
      final fixtures = await _fixtureService.fetchFixtures();
      
      final userId = _authService.currentUserId;
      List<Map<String, dynamic>> invites = [];
      if (userId != null) {
        invites = await _leagueService.getPendingInvites(userId);
      }

      if (mounted) {
        setState(() {
          _teams = teams;
          _invites = invites;
          _fixtures = fixtures.where((f) => f.status == FixtureStatus.scheduled).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading league data: $e");
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
        title: const Text(
          "HAAAH",
          style: TextStyle(color: neonGreen, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        centerTitle: false,
        actions: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: IconButton(
                  icon: Badge(
                    isLabelVisible: _invites.isNotEmpty,
                    label: Text('${_invites.length}'),
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                  color: neonGreen,
                  onPressed: _showNotificationsDialog,
                ),
              ),
              IconButton(
                onPressed: () {
                  QRCodeScannerPopup.show(
                    context,
                    onScan: (scannedData) async {
                      final userId = _authService.currentUserId;
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("You must be logged in to take attendance."),
                          ),
                        );
                        return;
                      }

                      try {
                        // scannedData is the fixtureId
                        await _fixtureService.recordAttendance(scannedData, userId);
                        final count = await _fixtureService.getAttendanceCount(scannedData);

                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: cardGrey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                "Attendance Taken!",
                                style: TextStyle(color: neonGreen),
                              ),
                              content: Text(
                                "You have been successfully checked in for this match.\n\nTotal Registered Players: $count",
                                style: const TextStyle(color: Colors.white),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK", style: TextStyle(color: neonGreen)),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          final msg = e.toString().contains("ALREADY_SCANNED")
                              ? "You have already scanned in for this match."
                              : "Invalid Match QR Code or network error.";

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: cardGrey,
                              title: const Text("Error", style: TextStyle(color: Colors.redAccent)),
                              content: Text(msg, style: const TextStyle(color: Colors.white)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK", style: TextStyle(color: neonGreen)),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_sharp),
                color: neonGreen,
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: neonGreen))
          : RefreshIndicator(
              color: neonGreen,
              backgroundColor: bgBlack,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "ACCRA DISTRICT",
                      style: TextStyle(
                        color: neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      "SUNDAY LEAGUE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CUSTOM TAB SELECTOR
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: cardGrey,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTab(
                              "GAMES",
                              isSelected: _showStandings,
                              onTap: () => setState(() => _showStandings = true),
                            ),
                          ),
                          Expanded(
                            child: _buildTab(
                              "STANDINGS",
                              isSelected: !_showStandings,
                              onTap: () => setState(() => _showStandings = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // DYNAMIC CONTENT AREA
                    _showStandings ? _buildUpcomingGames() : _buildStandingsTable(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterTeamScreen()),
          );
        },
        backgroundColor: neonGreen,
        elevation: 12,
        icon: const Icon(Icons.group_add_rounded, color: Colors.black),
        label: const Text(
          "REGISTER TEAM",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Future<void> _respondToInvite(String inviteId, bool accept) async {
    try {
      await _leagueService.respondToInvite(inviteId, accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? "Invitation accepted!" : "Invitation declined.")),
        );
        _loadData(); // Reload to refresh lists and bell icon
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Notifications", style: TextStyle(color: neonGreen)),
          content: _invites.isEmpty
              ? const Text("No new notifications.", style: TextStyle(color: Colors.white54))
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _invites.length,
                    itemBuilder: (context, index) {
                      final invite = _invites[index];
                      final teamName = invite['teams']['name'] as String;
                      final position = invite['position'] as String;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: neonGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Team Invite: $teamName",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Position: $position",
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent),
                              onPressed: () {
                                Navigator.pop(context);
                                _respondToInvite(invite['id'], false);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: neonGreen),
                              onPressed: () {
                                Navigator.pop(context);
                                _respondToInvite(invite['id'], true);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(String label, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? neonGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandingsTable() {
    if (_teams.isEmpty) {
      return const Center(
        child: Text("No standings available.", style: TextStyle(color: Colors.white54)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ..._teams.asMap().entries.map((entry) {
            int idx = entry.key;
            Team team = entry.value;
            return _buildTableRow(
              (idx + 1).toString().padLeft(2, '0'),
              team.name.toUpperCase(),
              team.played.toString(),
              team.won.toString(),
              isTop: idx == 0,
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildUpcomingGames() {
    if (_fixtures.isEmpty) {
      return const Center(
        child: Text("No upcoming fixtures.", style: TextStyle(color: Colors.white54)),
      );
    }
    return Column(
      children: _fixtures.map((f) {
        final date = DateFormat('E, MMM d').format(f.dateTime).toUpperCase();
        final time = DateFormat('HH:mm').format(f.dateTime);
        final home = f.homeTeam?.name ?? 'TBD';
        final away = f.awayTeam?.name ?? 'TBD';
        final venue = f.venue?.name ?? 'TBD';
        return _buildMatchCard(date, time, home, away, venue, f.attendanceCount);
      }).toList(),
    );
  }

  Widget _buildMatchCard(
    String date,
    String time,
    String home,
    String away,
    String pitch,
    int attendance,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  home,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    const Text(
                      "VS",
                      style: TextStyle(
                        color: neonGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: neonGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 10, color: neonGreen.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            "$attendance",
                            style: TextStyle(
                              color: neonGreen.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  away,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white24, size: 14),
              const SizedBox(width: 4),
              Text(
                pitch,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- REUSED TABLE WIDGETS ---
  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              "RANK",
              style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              "TEAM",
              style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              "P",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              "W",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String rank, String team, String p, String w, {bool isTop = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 45,
              child: Text(
                rank,
                style: TextStyle(
                  color: isTop ? neonGreen : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white12,
              child: Icon(Icons.shield_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                team,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            SizedBox(
              width: 35,
              child: Text(
                p,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 35,
              child: Text(
                w,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
