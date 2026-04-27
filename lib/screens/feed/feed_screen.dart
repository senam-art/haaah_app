import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/post.dart';
import '../../services/feed_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/offline_banner.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _feedService = FeedService();
  List<Post> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);
    try {
      _posts = await _feedService.fetchFeed();
    } catch (_) {
      _posts = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final more = await _feedService.fetchFeed(offset: _posts.length);
      _posts.addAll(more);
    } catch (_) {}
    if (mounted) setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Pitch 📸')),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: HaaahTheme.neonGreen))
              : _posts.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.photo_camera, size: 56, color: HaaahTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text('No posts yet', style: TextStyle(color: HaaahTheme.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('Be the first to share a moment!', style: TextStyle(color: HaaahTheme.textSecondary, fontSize: 13)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadFeed,
                      color: HaaahTheme.neonGreen,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) _loadMore();
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: _posts.length + (_loadingMore ? 1 : 0),
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemBuilder: (context, index) {
                            if (index == _posts.length) {
                              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: HaaahTheme.neonGreen)));
                            }
                            return PostCard(
                              post: _posts[index],
                              onTap: () async {
                                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(post: _posts[index])));
                                _loadFeed(); // Refresh to update comment counts
                              },
                            );
                          },
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}
