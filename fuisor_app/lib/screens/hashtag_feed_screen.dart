import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/post_card.dart';

class HashtagFeedScreen extends StatefulWidget {
  final String hashtag;

  const HashtagFeedScreen({
    super.key,
    required this.hashtag,
  });

  @override
  State<HashtagFeedScreen> createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends State<HashtagFeedScreen> {
  final ApiService _apiService = ApiService();
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadHashtagPosts();
  }

  Future<void> _loadHashtagPosts({bool loadMore = false}) async {
    try {
      if (loadMore) {
        setState(() {
          _isLoadingMore = true;
        });
      } else {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Get access token from AuthProvider
      final authProvider = context.read<AuthProvider>();
      final accessToken = await authProvider.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      // Set token in ApiService
      _apiService.setAccessToken(accessToken);

      print('HashtagFeedScreen: Loading posts for hashtag: ${widget.hashtag}');
      print('HashtagFeedScreen: Page: $_currentPage, Limit: $_limit');
      
      final posts = await _apiService.getPostsByHashtag(
        widget.hashtag,
        page: _currentPage,
        limit: _limit,
      );
      
      print('HashtagFeedScreen: Received ${posts.length} posts');

      setState(() {
        if (loadMore) {
          _posts.addAll(posts);
        } else {
          _posts = posts;
        }
        _isLoading = false;
        _isLoadingMore = false;
        if (posts.length == _limit) {
          _currentPage++;
        }
      });
    } catch (e) {
      print('HashtagFeedScreen: Error loading posts: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _currentPage = 1;
    });
    await _loadHashtagPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            EvaIcons.arrowBack,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '#${widget.hashtag}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0095F6),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        EvaIcons.alertCircleOutline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading posts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshPosts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095F6),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            EvaIcons.imageOutline,
                            color: Colors.grey,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No posts found',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Be the first to post with this hashtag!',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshPosts,
                      color: const Color(0xFF0095F6),
                      child: ListView.builder(
                        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            // Loading indicator at the bottom
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0095F6),
                                ),
                              ),
                            );
                          }

                          final post = _posts[index];
                          return PostCard(
                            post: post,
                            onLike: () async {
                              // Handle like
                              try {
                                final authProvider = context.read<AuthProvider>();
                                final accessToken = await authProvider.getAccessToken();
                                if (accessToken != null) {
                                  _apiService.setAccessToken(accessToken);
                                  await _apiService.likePost(post.id);
                                  
                                  setState(() {
                                    final postIndex = _posts.indexWhere((p) => p.id == post.id);
                                    if (postIndex != -1) {
                                      _posts[postIndex] = post.copyWith(
                                        isLiked: !post.isLiked,
                                        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
                                      );
                                    }
                                  });
                                }
                              } catch (e) {
                                print('Error liking post: $e');
                              }
                            },
                            onComment: (content, parentCommentId) async {
                              // Handle comment
                              try {
                                final authProvider = context.read<AuthProvider>();
                                final accessToken = await authProvider.getAccessToken();
                                if (accessToken != null) {
                                  _apiService.setAccessToken(accessToken);
                                  await _apiService.addComment(post.id, content, parentCommentId: parentCommentId);
                                  
                                  setState(() {
                                    final postIndex = _posts.indexWhere((p) => p.id == post.id);
                                    if (postIndex != -1) {
                                      _posts[postIndex] = post.copyWith(
                                        commentsCount: post.commentsCount + 1,
                                      );
                                    }
                                  });
                                }
                              } catch (e) {
                                print('Error adding comment: $e');
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
