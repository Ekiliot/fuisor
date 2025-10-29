import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../models/user.dart';
import '../widgets/safe_avatar.dart';
import '../screens/edit_post_screen.dart';
import '../screens/comments_screen.dart';
import '../screens/hashtag_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import 'hashtag_text.dart';
import 'package:provider/provider.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onLike;
  final Function(String content, String? parentCommentId) onComment;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _navigateToHashtag(String hashtag) {
    print('PostCard: Navigating to hashtag: $hashtag');
    print('PostCard: Context is mounted: ${mounted}');
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HashtagScreen(hashtag: hashtag),
        ),
      );
      print('PostCard: Navigation completed');
    } catch (e) {
      print('PostCard: Navigation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SafeAvatar(
                  imageUrl: widget.post.user?.avatarUrl,
                  radius: 18,
                  backgroundColor: const Color(0xFF262626),
                  fallbackIcon: EvaIcons.personOutline,
                  iconColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.user?.name ?? widget.post.user?.username ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '@${widget.post.user?.username ?? 'unknown'}',
                        style: const TextStyle(
                          color: Color(0xFF8E8E8E),
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatTimeAgo(widget.post.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF8E8E8E),
                              fontSize: 12,
                            ),
                          ),
                          if (widget.post.createdAt != widget.post.updatedAt) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '• Изменено',
                              style: TextStyle(
                                color: Color(0xFF8E8E8E),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(EvaIcons.moreHorizontal, size: 20, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => EditPostScreen(
                            postId: widget.post.id,
                            currentCaption: widget.post.caption,
                          ),
                        ),
                      );
                      
                      if (result == true && mounted) {
                        // Post was updated, refresh the feed
                        final postsProvider = context.read<PostsProvider>();
                        final authProvider = context.read<AuthProvider>();
                        final accessToken = await authProvider.getAccessToken();
                        if (accessToken != null) {
                          await postsProvider.loadFeed(refresh: true, accessToken: accessToken);
                        }
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final authProvider = context.read<AuthProvider>();
                    final isOwnPost = authProvider.currentUser?.id == widget.post.userId;
                    
                    return [
                      if (isOwnPost)
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(EvaIcons.editOutline, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Edit Post', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(EvaIcons.flagOutline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Report', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),

          // Media
          AspectRatio(
            aspectRatio: 1,
            child: widget.post.mediaType == 'video'
                ? Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        EvaIcons.playCircleOutline,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: widget.post.mediaUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error),
                      ),
                    ),
                  ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLiked = !_isLiked;
                        });
                        widget.onLike();
                      },
                      child: Icon(
                        _isLiked ? EvaIcons.heart : EvaIcons.heartOutline,
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(
                              postId: widget.post.id,
                              post: widget.post,
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        EvaIcons.messageCircleOutline,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(
                      EvaIcons.paperPlaneOutline,
                      size: 28,
                      color: Colors.white,
                    ),
                    const Spacer(),
                    const Icon(
                      EvaIcons.bookmarkOutline,
                      size: 28,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Likes count
                if (widget.post.likesCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${widget.post.likesCount} ${widget.post.likesCount == 1 ? 'like' : 'likes'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Caption
                if (widget.post.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.post.user?.name ?? widget.post.user?.username ?? 'Unknown'} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: HashtagText(
                            text: widget.post.caption,
                            style: const TextStyle(color: Colors.white),
                            hashtagStyle: const TextStyle(
                              color: Color(0xFF0095F6),
                              fontWeight: FontWeight.w600,
                            ),
                            onHashtagTap: _navigateToHashtag,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Comments count
                if (widget.post.commentsCount > 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showComments = !_showComments;
                      });
                    },
                    child: Text(
                      'View all ${widget.post.commentsCount} comments',
                      style: const TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Comments
                if (_showComments && widget.post.comments != null)
                  ...widget.post.comments!.take(3).map(
                        (comment) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${comment.user?.name ?? comment.user?.username ?? 'Unknown'} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: HashtagText(
                                  text: comment.content,
                                  style: const TextStyle(color: Colors.white),
                                  hashtagStyle: const TextStyle(
                                    color: Color(0xFF0095F6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onHashtagTap: _navigateToHashtag,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                // Add comment
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      // Current user avatar (larger to match input field height)
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final currentUser = authProvider.currentUser;
                          return SafeAvatar(
                            imageUrl: currentUser?.avatarUrl,
                            radius: 20, // Increased from 16 to 20
                            backgroundColor: const Color(0xFF262626),
                            fallbackIcon: EvaIcons.personOutline,
                            iconColor: Colors.white,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // More rounded comment input field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(30), // Increased from 25 to 30 for more rounded corners
                            border: Border.all(
                              color: const Color(0xFF404040),
                              width: 0.5,
                            ),
                          ),
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 18, // Increased from 16 to 18
                                vertical: 14, // Increased from 12 to 14
                              ),
                              hintStyle: TextStyle(
                                color: Color(0xFF8E8E8E),
                                fontSize: 14,
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                widget.onComment(value.trim(), null);
                                _commentController.clear(); // Clear the field after submitting
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
