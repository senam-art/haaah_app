import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/league_service.dart';
import '../../services/feed_service.dart';
import '../../models/profile.dart';
import '../../models/post.dart';
import '../auth/login_screen.dart';
import '../../widgets/green_light_badge.dart';
import '../../widgets/player_progress_bar.dart';
import '../leagues/team_details_screen.dart';
import '../../models/team.dart';

class PlayerCardScreen extends StatefulWidget {
  const PlayerCardScreen({super.key});

  @override
  State<PlayerCardScreen> createState() => _PlayerCardScreenState();
}

class _PlayerCardScreenState extends State<PlayerCardScreen> {
  static const neonGreen = Color(0xFF00FF85);
  static const bgBlack = Color(0xFF0A0A0A);
  static const cardGrey = Color(0xFF141414);

  final _authService = AuthService();
  final _leagueService = LeagueService();
  final _feedService = FeedService();
  Profile? _profile;
  List<Map<String, dynamic>> _invites = [];
  List<Map<String, dynamic>> _userTeams = [];
  Map<String, bool> _greenLitTeams = {};
  Map<String, Map<String, int>> _teamRosterCounts = {};
  List<Post> _posts = [];
  Map<String, int> _followStats = {'followers': 0, 'following': 0};
  bool _loading = true;
  File? _profileImage;
  int _selectedTabIndex = 0; // 0 = Attributes, 1 = Posts

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final p = await _authService.fetchAndCacheProfile();
      final invites = await _leagueService.getPendingInvites(p.id);
      final teams = await _leagueService.getUserTeams(p.id);
      
      final Map<String, bool> greenLitData = {};
      final Map<String, Map<String, int>> rosterCounts = {};
      
      for (var team in teams) {
        final teamId = team['team_id'] as String;
        final isGreenLit = await _leagueService.isTeamGreenLit(teamId);
        greenLitData[teamId] = isGreenLit;
        
        final roster = await _leagueService.getTeamRoster(teamId);
        final confirmed = roster.where((p) => p['status'] == 'CONFIRMED').length;
        rosterCounts[teamId] = {
          'current': confirmed,
          'total': roster.length,
        };
      }
      
      final stats = await _feedService.getFollowStats(p.id);
      final posts = await _feedService.fetchUserPosts(p.id, currentUserId: p.id);
      
      if (mounted) {
        setState(() {
          _profile = p;
          _invites = invites;
          _userTeams = teams;
          _greenLitTeams = greenLitData;
          _teamRosterCounts = rosterCounts;
          _followStats = stats;
          _posts = posts;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateProfilePic() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: neonGreen),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _processSelectedImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: neonGreen),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _processSelectedImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processSelectedImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (photo == null) return;

      final ext = photo.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Only picture files (jpg, png, webp) are allowed.")));
        }
        return;
      }

      final file = File(photo.path);
      final sizeInBytes = await file.length();
      if (sizeInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image size must be less than 5MB.")));
        }
        return;
      }

      // Upload to Supabase
      if (mounted) setState(() => _loading = true);
      
      await _authService.uploadProfilePicture(file);
      
      if (mounted) {
        // Reload the profile to get the updated data in memory properly
        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Profile picture updated!"),
          backgroundColor: neonGreen,
        ));
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respondToInvite(String inviteId, bool accept) async {
    try {
      await _leagueService.respondToInvite(inviteId, accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? "Invitation accepted!" : "Invitation declined.")),
        );
        _loadProfile(); // Reload to refresh lists
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: neonGreen))
          : _profile == null
              ? const Center(child: Text("Profile not found", style: TextStyle(color: Colors.white)))
              : RefreshIndicator(
                  color: neonGreen,
                  backgroundColor: bgBlack,
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildLargePlayerCard(),
                        const SizedBox(height: 20),
                        _buildTeamsList(),
                        const SizedBox(height: 20),
                        _buildInvitationsList(),
                        const SizedBox(height: 20),
                        _buildStatsGrid(),
                        const SizedBox(height: 25),
                        _buildTabs(),
                        const SizedBox(height: 20),
                        if (_selectedTabIndex == 0) ...[
                          _buildTacticalAttributes(),
                          const SizedBox(height: 25),
                          _buildTraitsRow(),
                        ] else ...[
                          _buildPostsGrid(),
                        ],
                        const SizedBox(height: 40),
                        _buildLogoutButton(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTeamsList() {
    if (_userTeams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MY TEAMS",
          style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 10),
        ..._userTeams.map((teamData) {
          final team = teamData['teams'];
          final teamId = team['id'] as String;
          final teamName = team['name'] as String;
          final isGreenLit = _greenLitTeams[teamId] ?? false;
          final counts = _teamRosterCounts[teamId] ?? {'current': 0, 'total': 0};
          
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamDetailsScreen(team: Team.fromJson(team)),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.white38, size: 30),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          teamName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isGreenLit) const GreenLightBadge(),
                    ],
                  ),
                  const SizedBox(height: 15),
                  PlayerProgressBar(
                    current: counts['current']!,
                    total: counts['total']!,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInvitationsList() {
    if (_invites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PENDING INVITATIONS",
          style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 10),
        ..._invites.map((invite) {
          final teamName = invite['teams']['name'] as String;
          final position = invite['position'] as String;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: neonGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Position: $position",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      onPressed: () => _respondToInvite(invite['id'], false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: neonGreen),
                      onPressed: () => _respondToInvite(invite['id'], true),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLargePlayerCard() {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _profileImage != null
                ? Image.file(_profileImage!, width: double.infinity, fit: BoxFit.cover)
                : _profile?.avatarUrl != null
                    ? Image.network(
                        _profile!.avatarUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) => progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator(color: neonGreen)),
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.black,
                          child: const Icon(Icons.broken_image, color: Colors.white24, size: 50),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF1A1A1A),
                        width: double.infinity,
                        child: Center(
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 120,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: _updateProfilePic,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: neonGreen),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: neonGreen, size: 20),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "SUNDAY LEAGUE",
                      style: TextStyle(
                        color: neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _profile!.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            right: 25,
            child: Column(
              children: [
                Text(
                  "${_profile!.overallRating}",
                  style: const TextStyle(
                    color: neonGreen,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  "ST", 
                  style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statBox("${_profile!.goals}", "GOALS", highlight: true)),
            const SizedBox(width: 12),
            Expanded(child: _statBox("${_profile!.assists}", "ASSISTS")),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statBox("${_followStats['followers']}", "FOLLOWERS")),
            const SizedBox(width: 12),
            Expanded(child: _statBox("${_followStats['following']}", "FOLLOWING")),
          ],
        ),
      ],
    );
  }

  Widget _statBox(String val, String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: highlight ? const Border(left: BorderSide(color: neonGreen, width: 3)) : null,
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalAttributes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tactical Attributes",
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _attrBar("PACE", _profile!.pace / 100),
        _attrBar("SHOOTING", _profile!.shooting / 100),
        _attrBar("DRIBBLING", _profile!.dribbling / 100),
        _attrBar("PHYSICAL", _profile!.physical / 100),
      ],
    );
  }

  Widget _attrBar(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${(val * 100).toInt()}",
                style: const TextStyle(color: neonGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: val,
            backgroundColor: Colors.white10,
            color: neonGreen,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _traitBadge(Icons.bolt, "SPEEDSTER", true),
        _traitBadge(Icons.track_changes, "SNIPER", true),
        _traitBadge(Icons.shield, "TANK", false),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 0),
            child: Column(
              children: [
                Text(
                  "ATTRIBUTES",
                  style: TextStyle(
                    color: _selectedTabIndex == 0 ? neonGreen : Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  color: _selectedTabIndex == 0 ? neonGreen : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 1),
            child: Column(
              children: [
                Text(
                  "POSTS",
                  style: TextStyle(
                    color: _selectedTabIndex == 1 ? neonGreen : Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  color: _selectedTabIndex == 1 ? neonGreen : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsGrid() {
    if (_posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            "No posts yet.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _posts[index].imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: cardGrey,
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          ),
        );
      },
    );
  }

  Widget _traitBadge(IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? neonGreen.withValues(alpha: 0.2) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? neonGreen : Colors.white10, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white10,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await _authService.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          "LOGOUT FROM HAAAH",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
