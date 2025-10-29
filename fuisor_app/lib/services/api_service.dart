import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user.dart';

class ApiService {
  // Измените этот IP на ваш локальный IP адрес (узнайте через ipconfig)
  // Для эмулятора Android: 10.0.2.2
  // Для реального устройства: ваш локальный IP (например, 192.168.1.100)
  // Для iOS симулятора: localhost
  static const String baseUrl = 'http://localhost:3000/api'; // Измените на http://192.168.X.X:3000/api
  String? _accessToken;

  void setAccessToken(String? token) {
    print('ApiService: Setting access token: ${token != null ? "Present (${token.substring(0, 20)}...)" : "Cleared"}');
    _accessToken = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // Auth endpoints
  Future<AuthResponse> login(String emailOrUsername, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email_or_username': emailOrUsername,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }

  Future<void> signup(String email, String password, String username, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
        'name': name,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Signup failed');
    }
  }

  Future<void> logout() async {
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers,
    );
    _accessToken = null;
  }

  // Posts endpoints
  Future<List<Post>> getPosts({int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['posts'] as List)
          .map((post) => Post.fromJson(post))
          .toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<List<Post>> getFeed({int page = 1, int limit = 10}) async {
    print('ApiService: Getting feed...');
    print('ApiService: Access token: ${_accessToken != null ? "Present (${_accessToken!.substring(0, 20)}...)" : "Missing"}');
    print('ApiService: Headers: $_headers');
    
    final response = await http.get(
      Uri.parse('$baseUrl/posts/feed?page=$page&limit=$limit'),
      headers: _headers,
    );

    print('ApiService: Feed response status: ${response.statusCode}');
    print('ApiService: Feed response body: ${response.body}');

    // Проверяем ошибки аутентификации
    if (response.statusCode == 401 || response.statusCode == 403) {
      print('ApiService: Authentication error in feed request');
      await _handleAuthError(response);
      throw Exception('Authentication failed - token may be expired');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['posts'] as List)
          .map((post) => Post.fromJson(post))
          .toList();
    } else {
      throw Exception('Failed to load feed');
    }
  }

  Future<Post> getPost(String postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load post');
    }
  }


  Future<void> likePost(String postId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like post');
    }
  }

  // Comment likes endpoints
  Future<Map<String, dynamic>> likeComment(String postId, String commentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments/$commentId/like'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to like comment');
    }
  }

  Future<Map<String, dynamic>> dislikeComment(String postId, String commentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments/$commentId/dislike'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to dislike comment');
    }
  }

  Future<Map<String, dynamic>> getComments(String postId, {int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/comments?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'comments': (data['comments'] as List)
            .map((json) => Comment.fromJson(json))
            .toList(),
        'total': data['total'],
        'page': data['page'],
        'totalPages': data['totalPages'],
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load comments');
    }
  }

  Future<Comment> addComment(String postId, String content, {String? parentCommentId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: _headers,
      body: jsonEncode({
        'content': content,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      }),
    );

    if (response.statusCode == 201) {
      return Comment.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to add comment');
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$postId/comments/$commentId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete comment');
    }
  }

  // User endpoints
  Future<User> getUser(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<List<Post>> getUserPosts(String userId, {int page = 1, int limit = 10}) async {
    print('ApiService: Getting user posts for userId: $userId');
    print('ApiService: Page: $page, Limit: $limit');
    print('ApiService: Access token: ${_accessToken != null ? "Present (${_accessToken!.substring(0, 20)}...)" : "Missing"}');
    
    final url = '$baseUrl/users/$userId/posts?page=$page&limit=$limit';
    print('ApiService: URL: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    print('ApiService: User posts response status: ${response.statusCode}');
    print('ApiService: User posts response body: ${response.body}');

    // Проверяем ошибки аутентификации
    if (response.statusCode == 401 || response.statusCode == 403) {
      print('ApiService: Authentication error in user posts request');
      await _handleAuthError(response);
      throw Exception('Authentication failed - token may be expired');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final posts = (data['posts'] as List)
          .map((post) => Post.fromJson(post))
          .toList();
      print('ApiService: Loaded ${posts.length} user posts');
      return posts;
    } else {
      print('ApiService: Error loading user posts: ${response.statusCode}');
      throw Exception('Failed to load user posts');
    }
  }

  // Hashtag endpoints
  Future<List<Post>> getPostsByHashtag(String hashtag, {int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/hashtag/$hashtag?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['posts'] as List)
          .map((post) => Post.fromJson(post))
          .toList();
    } else {
      throw Exception('Failed to load hashtag posts');
    }
  }

  Future<Map<String, dynamic>> getHashtagInfo(String hashtag) async {
    try {
      print('ApiService: Getting hashtag info for: #$hashtag');
      
      final response = await http.get(
        Uri.parse('$baseUrl/hashtags/$hashtag'),
        headers: _headers,
      );

      print('ApiService: Hashtag info response status: ${response.statusCode}');
      print('ApiService: Hashtag info response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('ApiService: Hashtag info loaded successfully');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to load hashtag info');
      }
    } catch (e) {
      print('ApiService: Exception: $e');
      throw Exception('Failed to load hashtag info: $e');
    }
  }

  // Mentions endpoints
  Future<List<Post>> getMentionedPosts({int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/mentions?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['posts'] as List)
          .map((post) => Post.fromJson(post))
          .toList();
    } else {
      throw Exception('Failed to load mentioned posts');
    }
  }

  // Update user profile
  Future<User> updateProfile({
    String? name,
    String? username,
    String? bio,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/users/profile'),
      );

      // Add headers
      request.headers.addAll(_headers);

      // Add text fields
      if (name != null && name.isNotEmpty) request.fields['name'] = name;
      if (username != null && username.isNotEmpty) request.fields['username'] = username;
      if (bio != null && bio.isNotEmpty) request.fields['bio'] = bio;

      // Add avatar file if provided
      if (avatarBytes != null && avatarFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            avatarBytes,
            filename: avatarFileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Profile update response status: ${response.statusCode}');
      print('Profile update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed response data: $responseData');
        return User.fromJson(responseData);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Получить текущего пользователя
  Future<User> getCurrentUser() async {
    print('ApiService: Getting current user...');
    print('ApiService: Access token: ${_accessToken != null ? "Present (${_accessToken!.substring(0, 20)}...)" : "Missing"}');
    print('ApiService: Headers: $_headers');
    
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
    );

    print('ApiService: Current user response status: ${response.statusCode}');
    print('ApiService: Current user response body: ${response.body}');

    // Проверяем ошибки аутентификации
    if (response.statusCode == 401 || response.statusCode == 403) {
      print('ApiService: Authentication error in getCurrentUser request');
      await _handleAuthError(response);
      throw Exception('Authentication failed - token may be expired');
    }

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      print('ApiService: Current user loaded successfully');
      return User.fromJson(userData);
    } else {
      print('ApiService: Error loading current user: ${response.statusCode}');
      throw Exception('Failed to load current user');
    }
  }

  // Создать новый пост
  Future<Post> createPost({
    required String caption,
    required Uint8List? mediaBytes,
    required String mediaFileName,
    required String mediaType,
    List<String>? mentions,
    List<String>? hashtags,
  }) async {
    try {
      print('ApiService: Creating post with filename: $mediaFileName');
      print('ApiService: Media type: $mediaType');
      print('ApiService: Media bytes length: ${mediaBytes?.length ?? 0}');
      print('ApiService: Caption: $caption');
      print('ApiService: Access token: ${_accessToken != null ? "Present (${_accessToken!.substring(0, 20)}...)" : "Missing"}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/posts'),
      );

      request.headers.addAll(_headers);
      // Убираем Content-Type для multipart запроса - он будет установлен автоматически
      request.headers.remove('Content-Type');
      print('ApiService: Headers: ${request.headers}');

      // Добавляем поля
      request.fields['caption'] = caption;
      request.fields['media_type'] = mediaType;
      
      if (mentions != null && mentions.isNotEmpty) {
        request.fields['mentions'] = jsonEncode(mentions);
      }
      
      // Hashtags are stored directly in caption text

      print('ApiService: Request fields: ${request.fields}');

      // Добавляем медиа файл
      if (mediaBytes != null) {
        // Определяем MIME тип по расширению файла
        String contentType = 'image/jpeg'; // По умолчанию
        if (mediaFileName.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        } else if (mediaFileName.toLowerCase().endsWith('.gif')) {
          contentType = 'image/gif';
        } else if (mediaFileName.toLowerCase().endsWith('.webp')) {
          contentType = 'image/webp';
        } else if (mediaFileName.toLowerCase().endsWith('.mp4')) {
          contentType = 'video/mp4';
        } else if (mediaFileName.toLowerCase().endsWith('.webm')) {
          contentType = 'video/webm';
        } else if (mediaFileName.toLowerCase().endsWith('.mov')) {
          contentType = 'video/quicktime';
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'media',
            mediaBytes,
            filename: mediaFileName,
            contentType: MediaType.parse(contentType),
          ),
        );
        print('ApiService: Added media file: $mediaFileName with content-type: $contentType');
      }

      print('ApiService: Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('ApiService: Response status: ${response.statusCode}');
      print('ApiService: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('ApiService: Post created successfully');
        return Post.fromJson(responseData);
      } else {
        final error = jsonDecode(response.body);
        print('ApiService: Error response: $error');
        throw Exception(error['error'] ?? 'Failed to create post');
      }
    } catch (e) {
      print('ApiService: Exception: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  Future<Post> updatePost({
    required String postId,
    required String caption,
  }) async {
    try {
      print('ApiService: Updating post $postId...');
      print('ApiService: Access token: ${_accessToken != null ? "Present (${_accessToken!.substring(0, 20)}...)" : "Missing"}');
      
      final response = await http.put(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: _headers,
        body: jsonEncode({
          'caption': caption,
        }),
      );

      print('ApiService: Update response status: ${response.statusCode}');
      print('ApiService: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('ApiService: Post updated successfully');
        return Post.fromJson(responseData);
      } else {
        final error = jsonDecode(response.body);
        print('ApiService: Error response: $error');
        throw Exception(error['error'] ?? 'Failed to update post');
      }
    } catch (e) {
      print('ApiService: Exception: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  // Обработать ошибку аутентификации
  Future<bool> _handleAuthError(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      print('ApiService: Authentication error detected (${response.statusCode})');
      print('ApiService: Response body: ${response.body}');
      
      // Здесь можно добавить логику обновления токена
      // Пока что просто возвращаем false
      return false;
    }
    return false;
  }

  // Follow/Unfollow endpoints
  Future<void> followUser(String userId) async {
    try {
      print('ApiService: Following user $userId...');
      final response = await http.post(
        Uri.parse('$baseUrl/follow/$userId'),
        headers: _headers,
      );

      print('ApiService: Follow response status: ${response.statusCode}');
      print('ApiService: Follow response body: ${response.body}');

      if (response.statusCode == 201) {
        print('ApiService: User followed successfully');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to follow user');
      }
    } catch (e) {
      print('ApiService: Exception: $e');
      throw Exception('Failed to follow user: $e');
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      print('ApiService: Unfollowing user $userId...');
      final response = await http.delete(
        Uri.parse('$baseUrl/follow/$userId'),
        headers: _headers,
      );

      print('ApiService: Unfollow response status: ${response.statusCode}');
      print('ApiService: Unfollow response body: ${response.body}');

      if (response.statusCode == 200) {
        print('ApiService: User unfollowed successfully');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to unfollow user');
      }
    } catch (e) {
      print('ApiService: Exception: $e');
      throw Exception('Failed to unfollow user: $e');
    }
  }

  Future<bool> checkFollowStatus(String userId) async {
    try {
      print('ApiService: Checking follow status for user $userId...');
      final response = await http.get(
        Uri.parse('$baseUrl/follow/status/$userId'),
        headers: _headers,
      );

      print('ApiService: Follow status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFollowing'] ?? false;
      } else {
        throw Exception('Failed to check follow status');
      }
    } catch (e) {
      print('ApiService: Exception: $e');
      throw Exception('Failed to check follow status: $e');
    }
  }

  Future<Map<String, dynamic>> getFollowers(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/follow/followers/$userId?page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load followers');
      }
    } catch (e) {
      throw Exception('Failed to load followers: $e');
    }
  }

  Future<Map<String, dynamic>> getFollowing(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/follow/following/$userId?page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load following');
      }
    } catch (e) {
      throw Exception('Failed to load following: $e');
    }
  }

  // Notifications endpoints
  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      print('ApiService: Getting notifications (page $page)...');
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?page=$page&limit=$limit'),
        headers: _headers,
      );

      print('ApiService: Notifications response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to load notifications');
      }
    } catch (e) {
      print('ApiService: Exception: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Search endpoints
  Future<Map<String, dynamic>> search(String query, {String type = 'all', int page = 1, int limit = 20}) async {
    try {
      print('ApiService: Searching for "$query" (type: $type)...');
      print('ApiService: Access token: ${_accessToken != null ? "Present" : "Missing"}');
      
      final url = '$baseUrl/search?q=${Uri.encodeComponent(query)}&type=$type&page=$page&limit=$limit';
      print('ApiService: Search URL: $url');
      print('ApiService: Headers: $_headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('ApiService: Search response status: ${response.statusCode}');
      final previewLen = response.body.length < 200 ? response.body.length : 200;
      print('ApiService: Search response body: ${response.body.substring(0, previewLen)}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to search');
      }
    } catch (e) {
      print('ApiService: Exception: $e');
      throw Exception('Failed to search: $e');
    }
  }

  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    try {
      final url = '$baseUrl/search/users?q=${Uri.encodeComponent(query)}&limit=$limit';
      print('ApiService: Search users URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> usersData = data['users'] ?? [];
        return usersData.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
