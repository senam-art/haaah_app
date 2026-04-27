import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/post.dart';
import '../../services/feed_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _feedService = FeedService();
  final _authService = AuthService();
  final _commentCtrl = TextEditingController();
  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      _comments = await _feedService.fetchComments(widget.post.id);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final comment = await _feedService.addComment(
        postId: widget.post.id,
        userId: _authService.currentUserId!,
        content: text,
      );
      _comments.add(comment);
      _commentCtrl.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Author
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: HaaahTheme.deepPurple.withValues(alpha: 0.3),
                child: Text(post.author?.initials ?? '?', style: const TextStyle(color: HaaahTheme.neonGreen, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(post.author?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(_timeAgo(post.createdAt), style: const TextStyle(color: HaaahTheme.textSecondary, fontSize: 12)),
              ]),
            ]),
          ),

          // Image
          CachedNetworkImage(imageUrl: post.imageUrl, width: double.infinity, fit: BoxFit.cover),

          // Caption
          if (post.caption != null && post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(post.caption!, style: const TextStyle(fontSize: 15, height: 1.4)),
            ),

          // Comments header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Comments (${_comments.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),

          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: HaaahTheme.neonGreen)))
          else if (_comments.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No comments yet', style: TextStyle(color: HaaahTheme.textSecondary))))
          else
            ...(_comments.map((c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: HaaahTheme.surfaceLight,
                  child: Text(c.author?.initials ?? '?', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: HaaahTheme.neonGreen)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(c.author?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(_timeAgo(c.createdAt), style: const TextStyle(color: HaaahTheme.textSecondary, fontSize: 11)),
                  ]),
                  const SizedBox(height: 2),
                  Text(c.content, style: const TextStyle(fontSize: 14, height: 1.3)),
                ])),
              ]),
            ))),
          const SizedBox(height: 80),
        ]))),

        // Comment input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            color: HaaahTheme.cardBg,
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: SafeArea(
            child: Row(children: [
              Expanded(child: TextField(
                controller: _commentCtrl,
                style: const TextStyle(color: HaaahTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true, fillColor: HaaahTheme.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              )),
              const SizedBox(width: 8),
              _sending
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: HaaahTheme.neonGreen)))
                  : IconButton(icon: const Icon(Icons.send, color: HaaahTheme.neonGreen), onPressed: _addComment),
            ]),
          ),
        ),
      ]),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dt);
  }
}
