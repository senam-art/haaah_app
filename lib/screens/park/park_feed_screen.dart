import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/feed_service.dart';
import '../../services/auth_service.dart';
import '../../models/post.dart';
import '../profile/public_profile_screen.dart';

class ParkFeedScreen extends StatefulWidget {
  const ParkFeedScreen({super.key});

  @override
  State<ParkFeedScreen> createState() => _ParkFeedScreenState();
}

class _ParkFeedScreenState extends State<ParkFeedScreen> {
  static const neonGreen = Color(0xFF00FF85);
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  final _feedService = FeedService();
  final _authService = AuthService();

  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _feedService.fetchFeed(currentUserId: _authService.currentUserId);
      if (mounted) setState(() => _posts = posts);
    } catch (e) {
      debugPrint("Error loading feed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageSource() async {
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
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (photo == null) return;

      // Ensure it is a picture by checking extension (basic check)
      final ext = photo.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Only picture files (jpg, png, webp) are allowed.")));
        }
        return;
      }

      // Check size limit (5MB)
      final file = File(photo.path);
      final sizeInBytes = await file.length();
      if (sizeInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image size must be less than 5MB.")));
        }
        return;
      }

      if (mounted) {
        _showPreviewDialog(photo);
      }
    } catch (e) {
      debugPrint("Hardware Error: $e");
    }
  }

  Future<void> _postVibe(File imageFile) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Must be logged in to post")));
      return;
    }

    setState(() => _isPosting = true);
    Navigator.pop(context); // Close the preview dialog

    try {
      await _feedService.createPost(
        imageFile: imageFile,
        caption: _captionController.text.trim(),
        userId: userId,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vibe Posted to the Park!"), backgroundColor: neonGreen),
      );
      
      _loadFeed(); // Refresh the feed
    } catch (e) {
      debugPrint("Error posting vibe: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error posting: $e")));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text("Delete Post?", style: TextStyle(color: Colors.white)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _feedService.deletePost(post.id, post.imageUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post deleted"), backgroundColor: Colors.redAccent),
        );
      }
      _loadFeed();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting post: $e")),
        );
      }
    }
  }

  void _showPreviewDialog(XFile photo) {
    _captionController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "CONFIRM VIBE",
                style: TextStyle(color: neonGreen, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(File(photo.path), fit: BoxFit.cover, width: double.infinity),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "ADD A CAPTION",
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _captionController,
                autofocus: false,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "What's happening at the park? #SundayLeague",
                  hintStyle: const TextStyle(color: Colors.white12, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF141414),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("DISCARD", style: TextStyle(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _postVibe(File(photo.path)),
                      child: const Text("POST VIBE", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(Post post) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    final wasLiked = post.isLikedByMe;
    
    // Optimistic update
    setState(() {
      post.isLikedByMe = !wasLiked;
      if (wasLiked) {
        // We can't directly mutate likesCount because it's final in the model,
        // Wait, likesCount is final. We can't mutate it easily without making it a var or copying.
        // Let's modify the Post model later to make likesCount a var or create a copyWith method.
        // For now, let's just trigger a backend update and re-fetch if needed.
      }
    });

    try {
      await _feedService.toggleLike(post.id, userId, post.isLikedByMe);
      _loadFeed(); // Refresh to get exact counts
    } catch (e) {
      // Revert on failure
      setState(() {
        post.isLikedByMe = wasLiked;
      });
    }
  }

  Future<void> _toggleFollow(Post post) async {
    final userId = _authService.currentUserId;
    if (userId == null || userId == post.authorId) return;

    final wasFollowed = post.isFollowedByMe;

    setState(() {
      post.isFollowedByMe = !wasFollowed;
    });

    try {
      await _feedService.toggleFollow(post.authorId, userId, post.isFollowedByMe);
    } catch (e) {
      setState(() {
        post.isFollowedByMe = wasFollowed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: neonGreen))
          else if (_posts.isEmpty)
            const Center(
              child: Text("No posts in the park yet. Be the first to vibe!", style: TextStyle(color: Colors.white54)),
            )
          else
            RefreshIndicator(
              color: neonGreen,
              backgroundColor: Colors.black,
              onRefresh: () async {
                await _loadFeed();
              },
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return _buildStoryItem(_posts[index]);
                },
              ),
            ),

          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "HAAAH SPORTS",
                  style: TextStyle(
                    color: neonGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
                Row(
                  children: [
                    if (_isPosting) 
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(color: neonGreen, strokeWidth: 2)
                        ),
                      ),
                    GestureDetector(
                      onTap: _pickImageSource,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: neonGreen.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, color: neonGreen, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(Post post) {
    final authorName = post.author?.name ?? 'Unknown Player';
    final positionLabel = post.author?.position ?? 'SUB';
    final isMe = post.authorId == _authService.currentUserId;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          post.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator(color: neonGreen)),
          errorBuilder: (context, error, stack) => Container(
            color: Colors.black,
            child: const Icon(Icons.broken_image, color: Colors.white24, size: 50),
          ),
        ),

        Positioned(
          right: 15,
          bottom: 140,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(post),
                child: _buildInteraction(
                  post.isLikedByMe ? Icons.favorite : Icons.favorite_outline, 
                  "${post.likesCount}", 
                  color: post.isLikedByMe ? Colors.redAccent : Colors.white,
                ),
              ),
              if (!isMe) ...[
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () => _toggleFollow(post),
                  child: _buildInteraction(
                    post.isFollowedByMe ? Icons.person_remove_rounded : Icons.person_add_alt_1_rounded, 
                    post.isFollowedByMe ? "FOLLOWING" : "FOLLOW", 
                    color: post.isFollowedByMe ? Colors.white54 : neonGreen,
                  ),
                ),
              ],
              if (isMe) ...[
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () => _deletePost(post),
                  child: _buildInteraction(Icons.delete_outline, "DELETE", color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),

        Positioned(
          bottom: 30,
          left: 15,
          right: 85,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (post.authorId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PublicProfileScreen(profileId: post.authorId),
                        ),
                      );
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: neonGreen,
                            child: Icon(Icons.person, size: 16, color: Colors.black),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Position: $positionLabel",
                        style: const TextStyle(
                          color: neonGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.caption != null && post.caption!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    post.caption!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteraction(IconData icon, String label, {Color color = Colors.white}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
