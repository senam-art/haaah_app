import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haaah_app/screens/fixtures/fixtures_screen.dart';
import 'package:haaah_app/screens/leagues/league_list_screen.dart';
import 'package:haaah_app/screens/park/park_feed_screen.dart';
import 'package:haaah_app/screens/profile/player_card_screen.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Default to 'The Park' - Social Space

  final _screens = const [
    LeagueListScreen(),
    ParkFeedScreen(),
    FixturesScreen(),
    PlayerCardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A0A0A),
        selectedItemColor: Colors.greenAccent[400],
        unselectedItemColor: Colors.white38,
        onTap: (index) async {
          Haptics.vibrate(HapticsType.light); // Haptic Feedback Feature
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Leagues'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'The Park'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Fixtures'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
