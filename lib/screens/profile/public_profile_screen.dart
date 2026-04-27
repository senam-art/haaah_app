import 'package:flutter/material.dart';
import '../../models/profile.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String profileId;

  const PublicProfileScreen({super.key, required this.profileId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  static const neonGreen = Color(0xFF00FF85);
  static const bgBlack = Color(0xFF0A0A0A);
  static const cardGrey = Color(0xFF141414);

  final _authService = AuthService();
  final _feedService = FeedService();

  Profile? _profile;
  List<Post> _posts = [];
  Map<String, int> _followStats = {'followers': 0, 'following': 0};
  bool _isLoading = true;
  bool _isFollowing = false;

  int _selectedTabIndex = 0; // 0 = Attributes, 1 = Posts

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final p = await _authService.fetchProfileById(widget.profileId);
      final stats = await _feedService.getFollowStats(widget.profileId);
      final currentUserId = _authService.currentUserId;
      final posts = await _feedService.fetchUserPosts(
        widget.profileId,
        currentUserId: currentUserId,
      );

      bool isFollowing = false;
      if (currentUserId != null) {
        isFollowing = await _feedService.isFollowingUser(widget.profileId, currentUserId);
      }

      if (mounted) {
        setState(() {
          _profile = p;
          _followStats = stats;
          _posts = posts;
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading public profile: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) return;

    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !wasFollowing;
      _followStats['followers'] = (_followStats['followers'] ?? 0) + (_isFollowing ? 1 : -1);
    });

    try {
      await _feedService.toggleFollow(widget.profileId, currentUserId, _isFollowing);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = wasFollowing;
          _followStats['followers'] = (_followStats['followers'] ?? 0) + (_isFollowing ? 1 : -1);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgBlack,
        body: Center(child: CircularProgressIndicator(color: neonGreen)),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: bgBlack,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text("Profile not found", style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final isMe = widget.profileId == _authService.currentUserId;

    return Scaffold(
      backgroundColor: bgBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: bgBlack,
            elevation: 0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              _profile!.name.toUpperCase(),
              style: const TextStyle(
                color: neonGreen,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            actions: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing ? Colors.transparent : neonGreen,
                      side: _isFollowing
                          ? const BorderSide(color: Colors.white54)
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(
                      _isFollowing ? "FOLLOWING" : "FOLLOW",
                      style: TextStyle(
                        color: _isFollowing ? Colors.white54 : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildFollowStatsRow(),
                  const SizedBox(height: 30),
                  _buildTabs(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_selectedTabIndex == 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildAttributesGrid(),
              ),
            )
          else
            _posts.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          "No posts yet.",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
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
                      }, childCount: _posts.length),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _profile!.avatarUrl != null
                ? Image.network(_profile!.avatarUrl!, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF1A1A1A),
                    width: double.infinity,
                    child: Center(
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 80,
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
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: neonGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _profile!.position.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn("FOLLOWERS", "${_followStats['followers']}"),
        _buildStatColumn("FOLLOWING", "${_followStats['following']}"),
      ],
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
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

  Widget _buildAttributesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard("PACE", _profile!.pace),
        _buildStatCard("SHOOTING", _profile!.shooting),
        _buildStatCard("DRIBBLING", _profile!.dribbling),
        _buildStatCard("PHYSICAL", _profile!.physical),
      ],
    );
  }

  Widget _buildStatCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: neonGreen,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
