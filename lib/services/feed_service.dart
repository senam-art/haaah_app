import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../db/database_helper.dart';

class FeedService {
  final _supabase = Supabase.instance.client;
  final _dbHelper = DatabaseHelper.instance;

  static const String _bucket = 'post-images';

  // ── Fetch Feed (paginated) ──

  Future<List<Post>> fetchFeed({int offset = 0, int limit = 20, String? currentUserId}) async {
    try {
      // 1. Fetch from Supabase
      final data = await _supabase
          .from('posts')
          .select('*, profiles(*)')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<Post> posts = (data as List).map((json) => Post.fromJson(json)).toList();

      // 2. If logged in, fetch likes and follows to populate UI state
      if (currentUserId != null && posts.isNotEmpty) {
        final postIds = posts.map((p) => p.id).toList();
        final authorIds = posts.map((p) => p.authorId).toSet().toList();

        final likesData = await _supabase
            .from('post_likes')
            .select('post_id')
            .eq('profile_id', currentUserId)
            .inFilter('post_id', postIds);
        
        final followsData = await _supabase
            .from('followers')
            .select('following_id')
            .eq('follower_id', currentUserId)
            .inFilter('following_id', authorIds);

        final likedPostIds = (likesData as List).map((l) => l['post_id'] as String).toSet();
        final followedAuthorIds = (followsData as List).map((f) => f['following_id'] as String).toSet();

        for (var post in posts) {
          post.isLikedByMe = likedPostIds.contains(post.id);
          post.isFollowedByMe = followedAuthorIds.contains(post.authorId);
        }
      }

      // 3. Cache locally (we don't cache likes/follows for now, just the posts)
      if (offset == 0) {
        await _dbHelper.cachePosts(posts.map((p) => p.toSqlite()).toList());
      }

      return posts;
    } catch (e) {
      // 4. Fallback to SQLite
      if (offset == 0) {
        final cachedMaps = await _dbHelper.getPosts();
        if (cachedMaps.isNotEmpty) {
          return cachedMaps.map((map) => Post.fromSqlite(map)).toList();
        }
      }
      rethrow;
    }
  }

  // ── Create Post ──

  Future<Post> createPost({
    required File imageFile,
    String? caption,
    required String userId,
  }) async {
    // 1. Upload image to Storage
    final ext = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.$ext';
    
    await _supabase.storage.from(_bucket).upload(fileName, imageFile);
    final imageUrl = _supabase.storage.from(_bucket).getPublicUrl(fileName);

    // 2. Insert into posts table
    final data = await _supabase
        .from('posts')
        .insert({
          'author_id': userId,
          'image_url': imageUrl,
          'caption': caption,
        })
        .select('*, profiles(*)')
        .single();

    return Post.fromJson(data);
  }

  // ── Social Interactions ──

  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    if (isLiked) {
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'profile_id': userId,
      });
      // Call RPC or let a trigger handle the increment if you have one.
      // Since we don't have a trigger, we can just do a manual increment if RLS allows, 
      // but for now we'll rely on a raw update:
      // Note: Supabase JS has `.rpc`, but standard update works if we fetch current or let DB handle it.
      // We will do a simple read/write for now:
      final postData = await _supabase.from('posts').select('likes_count').eq('id', postId).single();
      final currentLikes = postData['likes_count'] as int? ?? 0;
      await _supabase.from('posts').update({'likes_count': currentLikes + 1}).eq('id', postId);
    } else {
      await _supabase
          .from('post_likes')
          .delete()
          .match({'post_id': postId, 'profile_id': userId});
          
      final postData = await _supabase.from('posts').select('likes_count').eq('id', postId).single();
      final currentLikes = postData['likes_count'] as int? ?? 0;
      await _supabase.from('posts').update({'likes_count': (currentLikes > 0 ? currentLikes - 1 : 0)}).eq('id', postId);
    }
  }

  Future<bool> isFollowingUser(String targetUserId, String currentUserId) async {
    try {
      final response = await _supabase
          .from('followers')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleFollow(String targetUserId, String currentUserId, bool isFollowing) async {
    if (isFollowing) {
      await _supabase.from('followers').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });
    } else {
      await _supabase
          .from('followers')
          .delete()
          .match({'follower_id': currentUserId, 'following_id': targetUserId});
    }
  }

  // ── Stats and User Posts ──

  Future<Map<String, int>> getFollowStats(String profileId) async {
    try {
      final followersResponse = await _supabase.from('followers').select('id').eq('following_id', profileId).count(CountOption.exact);
      final followingResponse = await _supabase.from('followers').select('id').eq('follower_id', profileId).count(CountOption.exact);
      return {
        'followers': followersResponse.count,
        'following': followingResponse.count,
      };
    } catch (e) {
      return {'followers': 0, 'following': 0};
    }
  }

  Future<List<Post>> fetchUserPosts(String profileId, {String? currentUserId}) async {
    try {
      final data = await _supabase
          .from('posts')
          .select('*, profiles(*)')
          .eq('author_id', profileId)
          .order('created_at', ascending: false);

      final posts = (data as List).map((json) => Post.fromJson(json)).toList();

      if (currentUserId != null && posts.isNotEmpty) {
        final postIds = posts.map((p) => p.id).toList();
        final likesData = await _supabase
            .from('post_likes')
            .select('post_id')
            .eq('profile_id', currentUserId)
            .inFilter('post_id', postIds);
        
        final likedPostIds = (likesData as List).map((l) => l['post_id'] as String).toSet();
        for (var post in posts) {
          post.isLikedByMe = likedPostIds.contains(post.id);
        }
      }

      return posts;
    } catch (e) {
      return [];
    }
  }

  // ── Delete Post ──

  Future<void> deletePost(String postId, String imageUrl) async {
    // Delete from DB (Storage needs separate call if we want to clean up, but keeping it simple for now)
    await _supabase.from('posts').delete().eq('id', postId);
  }

  // ── Comments ──

  Future<List<Comment>> fetchComments(String postId) async {
    final data = await _supabase
        .from('post_comments')
        .select('*, profiles(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
        
    return (data as List).map((json) => Comment.fromJson(json)).toList();
  }

  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    final data = await _supabase
        .from('post_comments')
        .insert({
          'post_id': postId,
          'author_id': userId,
          'content': content,
        })
        .select('*, profiles(*)')
        .single();
        
    return Comment.fromJson(data);
  }

}
