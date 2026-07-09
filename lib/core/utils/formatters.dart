import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class Formatters {
  static String formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      final value = count / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
    }
    final value = count / 1000000;
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}M';
  }

  static String formatArabicCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      final value = count / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
    }
    final value = count / 1000000;
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}M';
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '${_arabicNumber(mins)} د';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${_arabicNumber(hours)} س';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '${_arabicNumber(days)} أسبوع';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${_arabicNumber(weeks)} أسبوع';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${_arabicNumber(months)} شهر';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${_arabicNumber(years)} سنة';
    }
  }

  static String _arabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) {
      final idx = int.tryParse(d);
      return idx != null ? arabicDigits[idx] : d;
    }).join();
  }

  static TextSpan buildFormattedText(
    String text, {
    required TextStyle baseStyle,
    required TextStyle linkStyle,
    void Function(String)? onHashtagTap,
    void Function(String)? onMentionTap,
    void Function(String)? onUrlTap,
  }) {
    final List<TextSpan> spans = [];
    final regex = RegExp(
      r'(https?:\/\/[^\s]+)|(#\S+)|(@\S+)',
    );

    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;

      if (matchedText.startsWith('http')) {
        spans.add(TextSpan(
          text: matchedText,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = onUrlTap != null ? () => onUrlTap(matchedText) : null,
        ));
      } else if (matchedText.startsWith('#')) {
        final hashtag = matchedText.substring(1);
        spans.add(TextSpan(
          text: matchedText,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = onHashtagTap != null ? () => onHashtagTap(hashtag) : null,
        ));
      } else if (matchedText.startsWith('@')) {
        final mention = matchedText.substring(1);
        spans.add(TextSpan(
          text: matchedText,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = onMentionTap != null ? () => onMentionTap(mention) : null,
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    if (spans.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    return TextSpan(children: spans);
  }

  static String formatDateFull(DateTime date) {
    const arabicMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${date.day} ${arabicMonths[date.month - 1]} ${date.year}';
  }

  static String formatJoinDate(DateTime date) {
    const arabicMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return 'انضم في ${arabicMonths[date.month - 1]} ${date.year}';
  }
}