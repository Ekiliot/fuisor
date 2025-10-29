import 'package:cached_network_image/cached_network_image.dart';

class ImageCacheUtils {
  /// Очищает весь кэш изображений
  static Future<void> clearImageCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      print('Image cache cleared successfully');
    } catch (e) {
      print('Error clearing image cache: $e');
    }
  }
  
  /// Очищает кэш для конкретного URL
  static Future<void> clearImageCacheForUrl(String url) async {
    try {
      await CachedNetworkImage.evictFromCache(url);
      print('Image cache cleared for URL: $url');
    } catch (e) {
      print('Error clearing image cache for URL $url: $e');
    }
  }
}
