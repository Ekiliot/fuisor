import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../services/api_service.dart';
import '../widgets/safe_avatar.dart';
import '../widgets/post_grid_widget.dart';
import '../widgets/profile_menu_sheet.dart';
import '../models/user.dart';
import 'edit_profile_screen.dart';
import 'followers_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  User? _viewingUser;
  bool _isLoadingUser = false;
  bool _isFollowing = false;
  bool _isCheckingFollowStatus = false;

  @override
  void initState() {
    super.initState();
    // Загружаем посты пользователя при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ждем инициализации AuthProvider
      await _waitForAuthProvider();
      
      final authProvider = context.read<AuthProvider>();
      final postsProvider = context.read<PostsProvider>();
      
      print('ProfileScreen: Initializing...');
      print('ProfileScreen: Viewing profile for userId: ${widget.userId ?? 'current user'}');
      print('ProfileScreen: Current user: ${authProvider.currentUser?.id}');
      print('ProfileScreen: Current user name: ${authProvider.currentUser?.name}');
      print('ProfileScreen: Current user username: ${authProvider.currentUser?.username}');
      
      // Determine which user's posts to load
      final targetUserId = widget.userId ?? authProvider.currentUser?.id;
      
      if (targetUserId != null && targetUserId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access_token');
        
        print('ProfileScreen: Loading posts for user: $targetUserId');
        
        // Load the user's profile if viewing another user
        if (widget.userId != null && widget.userId != authProvider.currentUser?.id) {
          setState(() {
            _isLoadingUser = true;
          });
          
          try {
            final apiService = ApiService();
            final user = await apiService.getUser(widget.userId!);
            setState(() {
              _viewingUser = user;
              _isLoadingUser = false;
            });
            
            // Check if current user is following this user
            await _checkFollowStatus(widget.userId!);
          } catch (e) {
            print('ProfileScreen: Error loading user: $e');
            setState(() {
              _isLoadingUser = false;
            });
          }
        }
        
        await postsProvider.loadUserPosts(
          userId: targetUserId,
          refresh: true,
          accessToken: accessToken,
        );
      } else {
        print('ProfileScreen: No current user found or user ID is empty');
        // Попробуем загрузить профиль
        try {
          print('ProfileScreen: Attempting to refresh profile...');
          await authProvider.refreshProfile();
          
          // Проверяем еще раз после refreshProfile
          if (authProvider.currentUser != null && authProvider.currentUser!.id.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            final accessToken = prefs.getString('access_token');
            
            print('ProfileScreen: Retrying to load posts for user: ${authProvider.currentUser!.id}');
            
            await postsProvider.loadUserPosts(
              userId: authProvider.currentUser!.id,
              refresh: true,
              accessToken: accessToken,
            );
          } else {
            print('ProfileScreen: Still no user after refreshProfile');
            // Попробуем загрузить из SharedPreferences напрямую
            final prefs = await SharedPreferences.getInstance();
            final userDataString = prefs.getString('userData');
            if (userDataString != null) {
              print('ProfileScreen: Found user data in SharedPreferences, parsing...');
              final userData = jsonDecode(userDataString);
              final user = User.fromJson(userData);
              print('ProfileScreen: Parsed user ID: ${user.id}');
              
              // Устанавливаем пользователя в AuthProvider
              authProvider.setCurrentUser(user);
              
              final accessToken = prefs.getString('access_token');
              await postsProvider.loadUserPosts(
                userId: user.id,
                refresh: true,
                accessToken: accessToken,
              );
            }
          }
        } catch (e) {
          print('ProfileScreen: Failed to refresh profile: $e');
        }
      }
    });
  }

  // Ждать инициализации AuthProvider
  Future<void> _waitForAuthProvider() async {
    int attempts = 0;
    const maxAttempts = 10;
    
    while (attempts < maxAttempts) {
      final authProvider = context.read<AuthProvider>();
      
      if (authProvider.currentUser != null && authProvider.currentUser!.id.isNotEmpty) {
        print('ProfileScreen: AuthProvider initialized after ${attempts + 1} attempts');
        return;
      }
      
      print('ProfileScreen: Waiting for AuthProvider... attempt ${attempts + 1}');
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
    
    print('ProfileScreen: AuthProvider not initialized after $maxAttempts attempts');
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final postsProvider = context.read<PostsProvider>();
      
      // Determine which user's profile to refresh
      final targetUserId = widget.userId ?? authProvider.currentUser?.id;
      
      if (targetUserId == null) {
        print('ProfileScreen: Cannot refresh posts - no valid user ID');
        return;
      }
      
      // Reload user data if viewing another user's profile
      if (widget.userId != null && widget.userId != authProvider.currentUser?.id) {
        setState(() {
          _isLoadingUser = true;
        });
        
        try {
          final apiService = ApiService();
          final user = await apiService.getUser(widget.userId!);
          setState(() {
            _viewingUser = user;
            _isLoadingUser = false;
          });
        } catch (e) {
          print('ProfileScreen: Error refreshing user: $e');
          setState(() {
            _isLoadingUser = false;
          });
        }
      } else {
        // Refresh current user's profile
        await authProvider.refreshProfile();
      }
      
      // Загружаем посты пользователя
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      print('ProfileScreen: Refreshing posts for user: $targetUserId');
      
      await postsProvider.loadUserPosts(
        userId: targetUserId,
        refresh: true,
        accessToken: accessToken,
      );
      
      if (mounted) {
        _refreshController.refreshCompleted();
        
        // Показываем уведомление об успешном обновлении
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: Color(0xFF0095F6),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _refreshController.refreshFailed();
        
        // Показываем уведомление об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _checkFollowStatus(String userId) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;
    
    setState(() {
      _isCheckingFollowStatus = true;
    });
    
    try {
      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('No access token');
      }
      
      final apiService = ApiService();
      apiService.setAccessToken(accessToken);
      final isFollowing = await apiService.checkFollowStatus(userId);
      setState(() {
        _isFollowing = isFollowing;
        _isCheckingFollowStatus = false;
      });
    } catch (e) {
      print('ProfileScreen: Error checking follow status: $e');
      setState(() {
        _isCheckingFollowStatus = false;
      });
    }
  }

  Future<void> _toggleFollow(String userId) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;
    
    try {
      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        throw Exception('No access token');
      }
      
      final apiService = ApiService();
      apiService.setAccessToken(accessToken);
      
      if (_isFollowing) {
        await apiService.unfollowUser(userId);
        setState(() {
          _isFollowing = false;
        });
      } else {
        await apiService.followUser(userId);
        setState(() {
          _isFollowing = true;
        });
      }
      
      // Refresh user data to update followers count
      if (mounted && _viewingUser != null) {
        final user = await apiService.getUser(userId);
        setState(() {
          _viewingUser = user;
        });
      }
    } catch (e) {
      print('ProfileScreen: Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: widget.userId != null
            ? IconButton(
                icon: const Icon(EvaIcons.arrowBack, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final displayUser = _viewingUser ?? authProvider.currentUser;
            return Text(
              '@${displayUser?.username ?? 'Profile'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            );
          },
        ),
        actions: [
          // Only show menu button for current user's own profile
          if (widget.userId == null)
            IconButton(
              icon: const Icon(EvaIcons.menu, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => const ProfileMenuSheet(),
                );
              },
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null && _viewingUser == null) {
            return const Center(
              child: Text(
                'Please log in',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Use _viewingUser if viewing another user's profile, otherwise use current user
          final user = _viewingUser ?? authProvider.currentUser!;
          
          if (_isLoadingUser) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            enablePullDown: true,
            enablePullUp: false,
            header: const WaterDropHeader(
              waterDropColor: Color(0xFF0095F6),
              complete: Icon(
                EvaIcons.checkmarkCircle,
                color: Color(0xFF0095F6),
                size: 20,
              ),
              failed: Icon(
                EvaIcons.closeCircle,
                color: Colors.red,
                size: 20,
              ),
            ),
            child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Name and Profile Picture Row
                      Row(
                        children: [
                          // Profile Picture
                          SafeAvatar(
                            imageUrl: user.avatarUrl,
                            radius: 40,
                            backgroundColor: const Color(0xFF262626),
                            fallbackIcon: EvaIcons.personOutline,
                            iconColor: Colors.white,
                          ),
                          const SizedBox(width: 20),
                          // Name next to profile picture
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18, // Increased from 16 to 18
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Posts', user.postsCount),
                          _buildStatColumn(
                            'Followers',
                            user.followersCount,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FollowersListScreen(
                                    userId: user.id,
                                    title: 'Followers',
                                    isFollowers: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildStatColumn(
                            'Following',
                            user.followingCount,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FollowersListScreen(
                                    userId: user.id,
                                    title: 'Following',
                                    isFollowers: false,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bio Section (if exists)
                if (user.bio != null && user.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      user.bio!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Edit Profile Button (only for current user)
                if (widget.userId == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            // Refresh profile data after editing
                            await authProvider.refreshProfile();
                            // Also refresh user posts
                            final postsProvider = context.read<PostsProvider>();
                            final prefs = await SharedPreferences.getInstance();
                            final accessToken = prefs.getString('access_token');
                            if (user.id.isNotEmpty) {
                              await postsProvider.loadUserPosts(
                                userId: user.id,
                                refresh: true,
                                accessToken: accessToken,
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0095F6),
                          side: const BorderSide(color: Color(0xFF262626)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Follow/Unfollow Button (only for other users' profiles)
                if (widget.userId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCheckingFollowStatus
                            ? null
                            : () => _toggleFollow(widget.userId!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing
                              ? const Color(0xFF262626)
                              : const Color(0xFF0095F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isCheckingFollowStatus
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _isFollowing ? 'Unfollow' : 'Follow',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Posts Grid
                Consumer<PostsProvider>(
                  builder: (context, postsProvider, child) {
                    return PostGridWidget(
                      posts: postsProvider.userPosts,
                      isLoading: postsProvider.isLoading,
                      hasMorePosts: postsProvider.hasMoreUserPosts,
                      onLoadMore: () async {
                        // Ждем инициализации AuthProvider перед загрузкой
                        await _waitForAuthProvider();
                        
                        if (authProvider.currentUser != null && authProvider.currentUser!.id.isNotEmpty) {
                          final prefs = await SharedPreferences.getInstance();
                          final accessToken = prefs.getString('access_token');
                          
                          print('ProfileScreen: Loading more posts for user: ${authProvider.currentUser!.id}');
                          
                          await postsProvider.loadUserPosts(
                            userId: authProvider.currentUser!.id,
                            refresh: false,
                            accessToken: accessToken,
                          );
                        } else {
                          print('ProfileScreen: Cannot load more posts - no valid user ID');
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, {VoidCallback? onTap}) {
    final column = Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E8E),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: column,
      );
    }

    return column;
  }
}
