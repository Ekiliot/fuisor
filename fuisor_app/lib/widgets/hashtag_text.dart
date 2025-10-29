import 'package:flutter/material.dart';

class HashtagText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? hashtagStyle;
  final Function(String hashtag)? onHashtagTap;

  const HashtagText({
    super.key,
    required this.text,
    this.style,
    this.hashtagStyle,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(r'#[а-яёА-ЯЁa-zA-Z0-9_]+');
    final matches = regex.allMatches(text);
    
    if (matches.isEmpty) {
      return Text(text, style: style);
    }

    final List<Widget> widgets = [];
    int lastIndex = 0;

    for (final match in matches) {
      // Add text before hashtag
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        if (beforeText.isNotEmpty) {
          widgets.add(Text(beforeText, style: style));
        }
      }

      // Add hashtag as clickable widget
      final hashtag = match.group(0)!;
      widgets.add(
        GestureDetector(
          onTap: () {
            print('HashtagText: Hashtag tapped: $hashtag');
            if (onHashtagTap != null) {
              onHashtagTap!(hashtag.substring(1)); // Remove # symbol
            }
          },
          child: Text(
            hashtag,
            style: hashtagStyle ?? const TextStyle(
              color: Color(0xFF0095F6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        widgets.add(Text(remainingText, style: style));
      }
    }

    return Wrap(children: widgets);
  }
}
