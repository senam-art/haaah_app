import 'profile.dart';

class Post {
  final String id;
  final String authorId;
  final String imageUrl;
  final String? caption;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  /// Populated from a joined query with profiles.
  final Profile? author;
  
  // Transient UI states
  bool isLikedByMe;
  bool isFollowedByMe;

  Post({
    required this.id,
    required this.authorId,
    required this.imageUrl,
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.author,
    this.isLikedByMe = false,
    this.isFollowedByMe = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'author_id': authorId,
    'image_url': imageUrl,
    'caption': caption,
    'likes_count': likesCount,
  };

  Map<String, dynamic> toSqlite() => {
    'post_id': id,
    'author_id': authorId,
    'author_name': author?.name ?? '',
    'image_url': imageUrl,
    'caption': caption ?? '',
    'likes_count': likesCount,
    'comments_count': commentsCount,
    'created_at': createdAt.toIso8601String(),
  };

  factory Post.fromSqlite(Map<String, dynamic> map) {
    return Post(
      id: map['post_id'] as String,
      authorId: map['author_id'] as String,
      imageUrl: map['image_url'] as String,
      caption: (map['caption'] as String?)?.isEmpty == true
          ? null
          : map['caption'] as String?,
      likesCount: map['likes_count'] as int? ?? 0,
      commentsCount: map['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      author: Profile(
        id: map['author_id'] as String,
        name: map['author_name'] as String? ?? '',
        email: '',
      ),
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final Profile? author;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }
}
