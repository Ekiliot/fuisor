import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class SafeAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final IconData fallbackIcon;
  final Color iconColor;

  const SafeAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor = const Color(0xFF262626),
    this.fallbackIcon = EvaIcons.personOutline,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                // Используем URL как cacheKey для правильного кэширования
                cacheKey: imageUrl!,
                // Добавляем дополнительные заголовки для лучшей совместимости
                httpHeaders: const {
                  'Accept': 'image/*',
                  'Cache-Control': 'no-cache',
                },
                placeholder: (context, url) => Container(
                  width: radius * 2,
                  height: radius * 2,
                  color: backgroundColor,
                  child: Icon(
                    fallbackIcon,
                    size: radius,
                    color: iconColor,
                  ),
                ),
                errorWidget: (context, url, error) {
                  print('Avatar load error for $url: $error');
                  
                  // Если это ошибка декодирования, попробуем другой подход
                  if (error.toString().contains('EncodingError') || 
                      error.toString().contains('cannot be decoded')) {
                    print('Image decoding error detected, showing fallback icon');
                  }
                  
                  return Container(
                    width: radius * 2,
                    height: radius * 2,
                    color: backgroundColor,
                    child: Icon(
                      fallbackIcon,
                      size: radius,
                      color: iconColor,
                    ),
                  );
                },
              ),
            )
          : Icon(
              fallbackIcon,
              size: radius,
              color: iconColor,
            ),
    );
  }
}
