import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/user.dart';
import '../services/api_service.dart';

class PostsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Post> _posts = [];
  List<Post> _feedPosts = [];
  List<Post> _hashtagPosts = [];
  List<Post> _mentionedPosts = [];
  List<Post> _userPosts = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _error;
  int _currentPage = 1;
  int _currentUserPage = 1;
  bool _hasMorePosts = true;
  bool _hasMoreUserPosts = true;

  List<Post> get posts => _posts;
  List<Post> get feedPosts => _feedPosts;
  List<Post> get hashtagPosts => _hashtagPosts;
  List<Post> get mentionedPosts => _mentionedPosts;
  List<Post> get userPosts => _userPosts;
  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;
  String? get error => _error;
  bool get hasMorePosts => _hasMorePosts;
  bool get hasMoreUserPosts => _hasMoreUserPosts;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadPosts({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMorePosts = true;
        _posts.clear();
      }

      _setLoading(true);
      _setError(null);

      final newPosts = await _apiService.getPosts(
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _posts = newPosts;
      } else {
        _posts.addAll(newPosts);
      }

      _hasMorePosts = newPosts.length == 10;
      _currentPage++;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadFeed({bool refresh = false, String? accessToken}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMorePosts = true;
        _feedPosts.clear();
        _isInitialLoading = false; // Не первая загрузка при refresh
      }

      _setLoading(true);
      _setError(null);

      // Устанавливаем токен перед запросом
      if (accessToken != null) {
        _apiService.setAccessToken(accessToken);
      }

      final newPosts = await _apiService.getFeed(
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _feedPosts = newPosts;
      } else {
        _feedPosts.addAll(newPosts);
      }

      _hasMorePosts = newPosts.length == 10;
      _currentPage++;

      _isInitialLoading = false; // Первая загрузка завершена
      _setLoading(false);
    } catch (e) {
      // При ошибке загрузки дополнительных страниц - просто останавливаем загрузку
      if (!refresh) {
        _hasMorePosts = false; // Больше нет постов для загрузки
        print('PostsProvider: No more posts to load, stopping pagination');
      } else {
        // При ошибке первой загрузки показываем ошибку
        _feedPosts = [];
        _setError(e.toString());
      }
      _isInitialLoading = false;
      _setLoading(false);
    }
  }

  Future<void> loadHashtagPosts(String hashtag, {bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMorePosts = true;
        _hashtagPosts.clear();
      }

      _setLoading(true);
      _setError(null);

      final newPosts = await _apiService.getPostsByHashtag(
        hashtag,
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _hashtagPosts = newPosts;
      } else {
        _hashtagPosts.addAll(newPosts);
      }

      _hasMorePosts = newPosts.length == 10;
      _currentPage++;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadMentionedPosts({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMorePosts = true;
        _mentionedPosts.clear();
      }

      _setLoading(true);
      _setError(null);

      final newPosts = await _apiService.getMentionedPosts(
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _mentionedPosts = newPosts;
      } else {
        _mentionedPosts.addAll(newPosts);
      }

      _hasMorePosts = newPosts.length == 10;
      _currentPage++;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await _apiService.likePost(postId);
      
      // Update local state in all lists
      _updatePostLikeStatus(_posts, postId);
      _updatePostLikeStatus(_feedPosts, postId);
      _updatePostLikeStatus(_userPosts, postId);
      _updatePostLikeStatus(_hashtagPosts, postId);
      _updatePostLikeStatus(_mentionedPosts, postId);
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _updatePostLikeStatus(List<Post> list, String postId) {
    final postIndex = list.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = list[postIndex];
      list[postIndex] = Post(
        id: post.id,
        userId: post.userId,
        caption: post.caption,
        mediaUrl: post.mediaUrl,
        mediaType: post.mediaType,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        commentsCount: post.commentsCount,
        mentions: post.mentions,
        hashtags: post.hashtags,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
        user: post.user,
        comments: post.comments,
        isLiked: !post.isLiked,
      );
    }
  }

  Future<Map<String, dynamic>> loadComments(String postId, {int page = 1, int limit = 20}) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final result = await _apiService.getComments(postId, page: page, limit: limit);
      
      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> addComment(String postId, String content, {String? parentCommentId}) async {
    try {
      final comment = await _apiService.addComment(postId, content, parentCommentId: parentCommentId);
      
      // Update local state
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final updatedComments = List<Comment>.from(post.comments ?? []);
        updatedComments.add(comment);
        
        _posts[postIndex] = Post(
          id: post.id,
          userId: post.userId,
          caption: post.caption,
          mediaUrl: post.mediaUrl,
          mediaType: post.mediaType,
          likesCount: post.likesCount,
          commentsCount: post.commentsCount + 1,
          mentions: post.mentions,
          hashtags: post.hashtags,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          user: post.user,
          comments: updatedComments,
          isLiked: post.isLiked,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Создать новый пост
  Future<void> createPost({
    required String caption,
    required Uint8List? mediaBytes,
    required String mediaFileName,
    required String mediaType,
    List<String>? mentions,
    List<String>? hashtags,
    String? accessToken, // Добавляем токен как параметр
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      print('PostsProvider: Creating post...');
      print('PostsProvider: Checking if ApiService has token...');

      // Устанавливаем токен перед запросом
      if (accessToken != null) {
        _apiService.setAccessToken(accessToken);
        print('PostsProvider: Token set in ApiService');
      }

      final newPost = await _apiService.createPost(
        caption: caption,
        mediaBytes: mediaBytes,
        mediaFileName: mediaFileName,
        mediaType: mediaType,
        mentions: mentions,
        hashtags: hashtags,
      );

      // Добавляем новый пост в начало списка
      _posts.insert(0, newPost);
      _feedPosts.insert(0, newPost);
      
      // Обновляем счетчик постов
      _currentPage = 1;
      _hasMorePosts = true;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> updatePost({
    required String postId,
    required String caption,
    required String accessToken,
  }) async {
    try {
      print('PostsProvider: Updating post with access token check...');
      _apiService.setAccessToken(accessToken);
      
      _setLoading(true);
      _setError(null);

      final updatedPost = await _apiService.updatePost(
        postId: postId,
        caption: caption,
      );

      // Update in all lists
      _updatePostInList(_posts, updatedPost);
      _updatePostInList(_feedPosts, updatedPost);
      _updatePostInList(_hashtagPosts, updatedPost);
      _updatePostInList(_mentionedPosts, updatedPost);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _updatePostInList(List<Post> list, Post updatedPost) {
    final index = list.indexWhere((post) => post.id == updatedPost.id);
    if (index != -1) {
      list[index] = updatedPost;
    }
  }

  Future<void> loadUserPosts({
    required String userId,
    bool refresh = false,
    String? accessToken,
  }) async {
    try {
      if (refresh) {
        _userPosts.clear();
        _currentUserPage = 1;
        _hasMoreUserPosts = true;
      }

      if (!_hasMoreUserPosts) return;

      print('PostsProvider: Loading user posts for user: $userId');
      print('PostsProvider: Page: $_currentUserPage');

      // Устанавливаем токен перед запросом
      if (accessToken != null) {
        _apiService.setAccessToken(accessToken);
      }

      _setLoading(true);
      _setError(null);

      final response = await _apiService.getUserPosts(
        userId,
        page: _currentUserPage,
        limit: 20,
      );

      if (response.isNotEmpty) {
        if (refresh) {
          _userPosts.clear();
        }
        _userPosts.addAll(response);
        _currentUserPage++;
        
        // Если получили меньше постов чем лимит, значит больше нет
        if (response.length < 20) {
          _hasMoreUserPosts = false;
        }
      } else {
        _hasMoreUserPosts = false;
      }

      print('PostsProvider: Loaded ${response.length} user posts');
      print('PostsProvider: Total user posts: ${_userPosts.length}');
    } catch (e) {
      print('PostsProvider: Error loading user posts: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Загрузить дополнительные посты для детального экрана
  Future<void> loadMoreFeedPosts({
    required int page,
    required int limit,
    required String accessToken,
  }) async {
    try {
      print('PostsProvider: Loading more feed posts...');
      print('PostsProvider: Page: $page, Limit: $limit');

      // Устанавливаем токен перед запросом
      _apiService.setAccessToken(accessToken);

      _setLoading(true);
      _setError(null);

      final response = await _apiService.getFeed(
        page: page,
        limit: limit,
      );

      if (response.isNotEmpty) {
        _feedPosts.addAll(response);
        _currentPage = page;
        
        // Если получили меньше постов чем лимит, значит больше нет
        if (response.length < limit) {
          _hasMorePosts = false;
        }
      } else {
        _hasMorePosts = false;
      }

      print('PostsProvider: Loaded ${response.length} more feed posts');
      print('PostsProvider: Total feed posts: ${_feedPosts.length}');
    } catch (e) {
      print('PostsProvider: Error loading more feed posts: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }
}
