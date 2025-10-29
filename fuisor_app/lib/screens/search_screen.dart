import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/posts_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../widgets/recommended_posts_grid.dart';
import '../widgets/safe_avatar.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<User> _users = [];
  List<Post> _posts = [];
  List<dynamic> _hashtags = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _setupApiService();
  }

  Future<void> _setupApiService() async {
    final authProvider = context.read<AuthProvider>();
    final accessToken = await authProvider.getAccessToken();
    if (accessToken != null) {
      _apiService.setAccessToken(accessToken);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _users = [];
        _posts = [];
        _hashtags = [];
        _hasSearched = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final result = await _apiService.search(query);
      
      setState(() {
        _users = (result['users'] as List? ?? [])
            .map((json) => User.fromJson(json))
            .toList();
        _posts = (result['posts'] as List? ?? [])
            .map((json) => Post.fromJson(json))
            .toList();
        _hashtags = result['hashtags'] as List? ?? [];
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching: $e');
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF262626)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              if (value.trim().isNotEmpty) {
                _performSearch(value);
              } else {
                setState(() {
                  _users = [];
                  _posts = [];
                  _hashtags = [];
                  _hasSearched = false;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Search for users, posts and hashtags',
              hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: const Icon(EvaIcons.searchOutline, color: Color(0xFF8E8E8E)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(EvaIcons.closeCircle, color: Color(0xFF8E8E8E)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _users = [];
                          _posts = [];
                          _hashtags = [];
                          _hasSearched = false;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: _isSearching
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0095F6)),
            )
          : _hasSearched
              ? _buildSearchResults()
              : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search placeholder
            Container(
              height: 200,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      EvaIcons.searchOutline,
                      size: 64,
                      color: Color(0xFF8E8E8E),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Search for users, posts and hashtags',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF8E8E8E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Recommended Posts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended Posts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<PostsProvider>(
                    builder: (context, postsProvider, child) {
                      return RecommendedPostsGrid(
                        posts: postsProvider.feedPosts.take(12).toList(), // Show first 12 posts as recommendations
                        isLoading: postsProvider.isLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_users.isEmpty && _posts.isEmpty && _hashtags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              EvaIcons.searchOutline,
              size: 64,
              color: Color(0xFF8E8E8E),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching for something else',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E8E),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Users
          if (_users.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: SafeAvatar(
                    imageUrl: user.avatarUrl,
                    radius: 20,
                  ),
                  title: Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: user.name.isNotEmpty
                      ? Text(
                          user.name,
                          style: const TextStyle(color: Color(0xFF8E8E8E)),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: user.id),
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(color: Color(0xFF262626)),
          ],

          // Posts
          if (_posts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RecommendedPostsGrid(
                posts: _posts,
                isLoading: false,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF262626)),
          ],

          // Hashtags
          if (_hashtags.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Hashtags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _hashtags.length,
              itemBuilder: (context, index) {
                final hashtag = _hashtags[index];
                return ListTile(
                  leading: const Icon(
                    EvaIcons.hash,
                    color: Color(0xFF0095F6),
                  ),
                  title: Text(
                    '#${hashtag['name']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${hashtag['posts_count']} posts',
                    style: const TextStyle(color: Color(0xFF8E8E8E)),
                  ),
                  onTap: () {
                    // TODO: Navigate to hashtag posts
                    print('Navigate to hashtag: ${hashtag['name']}');
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
