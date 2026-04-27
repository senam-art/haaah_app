import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _authService.currentProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: HaaahTheme.deepPurple.withValues(alpha: 0.3),
            child: Text(
              profile?.initials ?? '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: HaaahTheme.neonGreen),
            ),
          ),
          const SizedBox(height: 16),
          Text(profile?.name ?? 'Player', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(profile?.email ?? '', style: const TextStyle(color: HaaahTheme.textSecondary)),
          const SizedBox(height: 24),

          // Rating card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: HaaahTheme.glassCard,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: HaaahTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_soccer, color: HaaahTheme.neonGreen),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Overall Rating', style: TextStyle(color: HaaahTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${profile?.overallRating ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
          const SizedBox(height: 40),

          // Sign Out
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: HaaahTheme.red,
                side: BorderSide(color: HaaahTheme.red.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
