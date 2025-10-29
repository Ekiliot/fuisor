import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../providers/posts_provider.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final String initialPostId;
  final List<Post> initialPosts;

  const PostDetailScreen({
    Key? key,
    required this.initialPostId,
    required this.initialPosts,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  int? _initialPostIndex;

  @override
  void initState() {
    super.initState();
    
    // Находим индекс начального поста
    _initialPostIndex = widget.initialPosts.indexWhere(
      (post) => post.id == widget.initialPostId,
    );
    
    // Если пост не найден в начальном списке, добавляем его
    if (_initialPostIndex == -1) {
      _initialPostIndex = 0;
    }
    
    // Скроллим к нужному посту после загрузки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialPostIndex != null && _initialPostIndex! < widget.initialPosts.length) {
        _scrollToPost(_initialPostIndex!);
      }
    });
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final postsProvider = context.read<PostsProvider>();
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken != null) {
        await postsProvider.loadMoreFeedPosts(
          page: _currentPage + 1,
          limit: 20,
          accessToken: accessToken,
        );
        
        setState(() {
          _currentPage++;
          _hasMorePosts = postsProvider.hasMorePosts;
        });
      }
    } catch (e) {
      print('Error loading more posts: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _scrollToPost(int index) {
    if (index < widget.initialPosts.length) {
      // Вычисляем примерную позицию поста
      final double itemHeight = MediaQuery.of(context).size.width + 200; // Примерная высота поста
      final double targetPosition = index * itemHeight;
      
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(EvaIcons.arrowBack, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Posts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(EvaIcons.shareOutline, color: Colors.white),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: Consumer<PostsProvider>(
        builder: (context, postsProvider, child) {
          final allPosts = postsProvider.feedPosts;
          
          if (allPosts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    EvaIcons.imageOutline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No posts available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: allPosts.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == allPosts.length) {
                // Показать индикатор загрузки в конце
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0095F6),
                    ),
                  ),
                );
              }

              final post = allPosts[index];
              return PostCard(
                post: post,
                onLike: () => postsProvider.likePost(post.id),
                onComment: (content, parentCommentId) => postsProvider.addComment(
                  post.id,
                  content,
                  parentCommentId: parentCommentId,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
