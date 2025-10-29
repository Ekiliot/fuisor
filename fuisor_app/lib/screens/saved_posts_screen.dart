import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/post_grid_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<Post> _savedPosts = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts({bool refresh = false}) async {
    if (!refresh && !_hasMore) return;

    setState(() {
      if (refresh) {
        _currentPage = 1;
        _savedPosts.clear();
        _hasMore = true;
      }
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      _apiService.setAccessToken(accessToken);

      final result = await _apiService.getSavedPosts(
        page: _currentPage,
        limit: 20,
      );

      if (mounted) {
        final newPosts = (result['posts'] as List? ?? [])
            .map((json) => Post.fromJson(json))
            .toList();

        setState(() {
          if (refresh) {
            _savedPosts = newPosts;
          } else {
            _savedPosts.addAll(newPosts);
          }
          _currentPage++;
          _hasMore = result['page'] < result['totalPages'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading saved posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading && _savedPosts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0095F6),
              ),
            )
          : _savedPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        EvaIcons.bookmarkOutline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No saved posts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Posts you save will appear here',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent * 0.8) {
                        _loadSavedPosts();
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    child: PostGridWidget(
                      posts: _savedPosts,
                      isLoading: _isLoading,
                      hasMorePosts: _hasMore,
                      onLoadMore: () => _loadSavedPosts(),
                    ),
                  ),
                ),
    );
  }
}

