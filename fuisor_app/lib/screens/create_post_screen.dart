import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/posts_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/hashtag_utils.dart';

class CreatePostScreen extends StatefulWidget {
  final XFile? selectedFile;
  final Uint8List? selectedImageBytes;
  final VideoPlayerController? videoController;

  const CreatePostScreen({
    super.key,
    this.selectedFile,
    this.selectedImageBytes,
    this.videoController,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // Получить токен из AuthProvider
  Future<String?> _getAccessTokenFromAuthProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  Future<void> _createPost() async {
    if (widget.selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final postsProvider = context.read<PostsProvider>();
      final authProvider = context.read<AuthProvider>();

      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('Creating post for user: ${authProvider.currentUser!.username}');
      print('Selected file: ${widget.selectedFile!.path}');
      print('File name: ${widget.selectedFile!.name}');

      String mediaType = 'image';
      Uint8List? mediaBytes = widget.selectedImageBytes;
      String mediaFileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Определяем тип медиа по расширению файла
      if (widget.selectedFile!.path.toLowerCase().contains('.mp4') ||
          widget.selectedFile!.path.toLowerCase().contains('.mov') ||
          widget.selectedFile!.path.toLowerCase().contains('.avi')) {
        mediaType = 'video';
        mediaFileName = 'post_${DateTime.now().millisecondsSinceEpoch}.mp4';
        
        // Для видео читаем файл как байты
        final file = File(widget.selectedFile!.path);
        mediaBytes = await file.readAsBytes();
        print('Video file size: ${mediaBytes.length} bytes');
      } else {
        print('Image file size: ${mediaBytes?.length ?? 0} bytes');
      }

      if (mediaBytes == null) {
        throw Exception('Failed to process media file');
      }

      print('Media type: $mediaType');
      print('Media filename: $mediaFileName');
      print('Caption: ${_captionController.text.trim()}');

      // Получаем токен из AuthProvider
      final accessToken = authProvider.currentUser != null ? 
        await _getAccessTokenFromAuthProvider() : null;
      
      // Hashtags are stored directly in the caption text
      final captionText = _captionController.text.trim();
      
      print('CreatePostScreen: Creating post with caption: $captionText');
      
      await postsProvider.createPost(
        caption: captionText,
        mediaBytes: mediaBytes,
        mediaFileName: mediaFileName,
        mediaType: mediaType,
        accessToken: accessToken,
      );

      print('Post created successfully!');

      if (mounted) {
        // Закрываем все экраны создания поста и возвращаемся к главному экрану
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Color(0xFF0095F6),
          ),
        );
      }
    } catch (e) {
      print('Error creating post: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
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
        title: const Text(
          'New Post',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(EvaIcons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF0095F6),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Share',
                    style: TextStyle(
                      color: Color(0xFF0095F6),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Предпросмотр медиа
          if (widget.selectedFile != null)
            Container(
              height: 300,
              width: double.infinity,
              color: const Color(0xFF1A1A1A),
              child: _buildMediaPreview(),
            ),
          
          // Поле для подписи
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Caption',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: TextStyle(color: Color(0xFF8E8E8E)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF262626)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF262626)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF0095F6)),
                    ),
                    filled: true,
                    fillColor: Color(0xFF1A1A1A),
                  ),
                ),
                
                // Ошибка
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (widget.selectedFile == null) return const SizedBox();

    if (widget.selectedImageBytes != null) {
      return Image.memory(
        widget.selectedImageBytes!,
        fit: BoxFit.cover,
      );
    } else if (widget.videoController != null) {
      return AspectRatio(
        aspectRatio: widget.videoController!.value.aspectRatio,
        child: VideoPlayer(widget.videoController!),
      );
    }

    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0095F6),
      ),
    );
  }
}
