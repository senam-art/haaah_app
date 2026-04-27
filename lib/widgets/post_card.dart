import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/post.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: HaaahTheme.glassCard,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: HaaahTheme.deepPurple.withValues(alpha: 0.3),
                    child: Text(
                      post.author?.initials ?? '?',
                      style: const TextStyle(
                        color: HaaahTheme.neonGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author?.name ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: HaaahTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: HaaahTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Photo
            CachedNetworkImage(
              imageUrl: post.imageUrl,
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor: HaaahTheme.surfaceLight,
                highlightColor: HaaahTheme.cardBg,
                child: Container(
                  height: 260,
                  color: HaaahTheme.surfaceLight,
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 260,
                color: HaaahTheme.surfaceLight,
                child: const Center(
                  child: Icon(Icons.broken_image, color: HaaahTheme.textSecondary),
                ),
              ),
            ),

            // Caption + Comments
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.caption != null && post.caption!.isNotEmpty) ...[
                    Text(
                      post.caption!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: HaaahTheme.textPrimary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: HaaahTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentsCount} ${post.commentsCount == 1 ? 'comment' : 'comments'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: HaaahTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}
