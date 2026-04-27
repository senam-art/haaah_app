import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:haaah_app/screens/fixtures/game_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/fixture_service.dart';
import '../../models/fixture.dart';

class FixturesScreen extends StatefulWidget {
  const FixturesScreen({super.key});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  static const neonGreen = Color(0xFF00FF85);
  static const bgBlack = Color(0xFF0A0A0A);
  static const cardGrey = Color(0xFF141414);

  final _fixtureService = FixtureService();
  List<Fixture> _fixtures = [];
  List<DateTime> _uniqueDates = [];
  DateTime? _selectedDate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFixtures();
  }

  Future<void> _loadFixtures() async {
    setState(() => _loading = true);
    try {
      final fixtures = await _fixtureService.fetchFixtures();
      if (mounted) {
        setState(() {
          _fixtures = fixtures;

          // Compute unique dates
          final dates = fixtures
              .map((f) => DateTime(f.dateTime.year, f.dateTime.month, f.dateTime.day))
              .toSet()
              .toList();
          dates.sort();
          _uniqueDates = dates;

          // Select the first date if none selected, or if the current one isn't in the new list
          if (_selectedDate == null || !_uniqueDates.contains(_selectedDate)) {
            _selectedDate = _uniqueDates.isNotEmpty ? _uniqueDates.first : null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading fixtures: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // HARDWARE FEATURE: PHONE CALL
  Future<void> _callManager(String number) async {
    final Uri url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // HARDWARE FEATURE: GPS / MAPS
  Future<void> _getDirections(double lat, double lng) async {
    // Handoff location to the natuve Maps App
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
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
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "FIXTURES  ",
                style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: neonGreen))
          : RefreshIndicator(
              color: neonGreen,
              backgroundColor: bgBlack,
              onRefresh: _loadFixtures,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _uniqueDates.map((date) {
                          final monthFormat = DateFormat('MMM d').format(date).toUpperCase();

                          // See if it is today
                          final now = DateTime.now();
                          final isToday =
                              date.year == now.year &&
                              date.month == now.month &&
                              date.day == now.day;
                          final dayFormat = isToday
                              ? "TODAY"
                              : DateFormat('E').format(date).toUpperCase();

                          final isSelected = _selectedDate == date;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            child: _buildDateCard(monthFormat, dayFormat, isSelected: isSelected),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    if (_fixtures.isEmpty || _selectedDate == null)
                      const Center(
                        child: Text(
                          "No fixtures scheduled yet.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ..._fixtures
                          .where(
                            (f) =>
                                f.dateTime.year == _selectedDate!.year &&
                                f.dateTime.month == _selectedDate!.month &&
                                f.dateTime.day == _selectedDate!.day,
                          )
                          .map((f) {
                            final timeStr = DateFormat('HH:mm').format(f.dateTime);
                            String statusText;
                            if (f.status == FixtureStatus.live) {
                              statusText = "LIVE • $timeStr";
                            } else {
                              statusText = "KICK-OFF: $timeStr";
                            }

                            String scoreText = "-- : --";
                            if (f.homeScore != null && f.awayScore != null) {
                              scoreText = "${f.homeScore} - ${f.awayScore}";
                            }

                            return _buildMatchCard(
                              context,
                              status: statusText,
                              homeTeam: f.homeTeam?.name.toUpperCase() ?? 'TBD',
                              awayTeam: f.awayTeam?.name.toUpperCase() ?? 'TBD',
                              score: scoreText,
                              venue: f.venue?.name.toUpperCase() ?? 'TBD',
                              isLive: f.status == FixtureStatus.live,
                              lat: f.venue?.lat ?? 5.55,
                              lng: f.venue?.lng ?? -0.20,
                              attendanceCount: f.attendanceCount,
                            );
                          }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateCard(String date, String day, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.transparent : cardGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? neonGreen : Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            date,
            style: TextStyle(
              color: isSelected ? neonGreen : Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(day, style: TextStyle(color: isSelected ? neonGreen : Colors.white10, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context, {
    required String status,
    required String homeTeam,
    required String awayTeam,
    required String score,
    required String venue,
    bool isLive = false,
    required double lat,
    required double lng,
    int attendanceCount = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), 
      child: Ink(
        
        decoration: BoxDecoration(
          color: cardGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLive ? neonGreen.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: neonGreen.withValues(alpha: 0.2),
          highlightColor: neonGreen.withValues(alpha:0.1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameDetailsScreen(
                  homeTeam: homeTeam,
                  awayTeam: awayTeam,
                  score: score,
                  venue: venue,
                  lat: lat,
                  lng: lng,
                ),
              ),
            );
          },
          child: Container(
            // 2. This container is now transparent so the Ink shows through
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isLive) const Icon(Icons.circle, color: neonGreen, size: 8),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: isLive ? neonGreen : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      "GHANA LEAGUE A",
                      style: TextStyle(color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _teamInfo(homeTeam, Icons.shield),
                    Column(
                      children: [
                        Text(
                          score,
                          style: const TextStyle(
                            color: neonGreen,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
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
                                "$attendanceCount",
                                style: TextStyle(color: neonGreen.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _teamInfo(awayTeam, Icons.cabin),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white24, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      venue,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _getDirections(lat, lng),
                        icon: const Icon(Icons.near_me, size: 16),
                        label: const Text(
                          "GET DIRECTIONS",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonGreen,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callManager("+233240000000"),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text(
                          "CALL MANAGER",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: neonGreen,
                          side: const BorderSide(color: neonGreen),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamInfo(String name, IconData logo) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white12,
          child: Icon(logo, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
