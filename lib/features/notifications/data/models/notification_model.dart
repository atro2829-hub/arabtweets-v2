import 'package:flutter/material.dart';
import 'package:adentweet/core/constants/api_constants.dart';

enum NotificationType {
  like('like'),
  retweet('retweet'),
  follow('follow'),
  reply('reply'),
  mention('mention'),
  message('message');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.like,
    );
  }
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final bool isRead;
  final String message;
  final DateTime createdAt;
  final String? fromUserId;
  final String? fromUsername;
  final String? fromAvatarUrl;
  final String? fromDisplayName;
  final String? tweetId;

  NotificationModel({
    required this.id,
    required this.type,
    required this.isRead,
    required this.message,
    required this.createdAt,
    this.fromUserId,
    this.fromUsername,
    this.fromAvatarUrl,
    this.fromDisplayName,
    this.tweetId,
  });

  String get fromFullAvatarUrl {
    if (fromAvatarUrl == null || fromAvatarUrl!.isEmpty) return ';
    return ApiConstants.getAvatarUrl(fromAvatarUrl!);
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.retweet:
        return Icons.repeat;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.reply:
        return Icons.reply;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
    }
  }

  Color get typeIconColor {
    switch (type) {
      case NotificationType.like:
        return const Color(0xFFE0245E);
      case NotificationType.retweet:
        return const Color(0xFF17BF63);
      case NotificationType.follow:
        return const Color(0xFF1D9BF0);
      case NotificationType.reply:
        return const Color(0xFF1D9BF0);
      case NotificationType.mention:
        return const Color(0xFF1D9BF0);
      case NotificationType.message:
        return const Color(0xFF1D9BF0);
    }
  }

  String get actionText {
    switch (type) {
      case NotificationType.like:
        return 'أعجب بتعليقك';
      case NotificationType.retweet:
        return 'أعاد نشر تغريدتك';
      case NotificationType.follow:
        return 'تابعك';
      case NotificationType.reply:
        return 'رد على تغريدتك';
      case NotificationType.mention:
        return 'أشار إليك';
      case NotificationType.message:
        return 'أرسل لك رسالة';
    }
  }

  Color get typeIconBgColor {
    switch (type) {
      case NotificationType.like:
        return const Color(0xFFE0245E).withValues(alpha: 0.1);
      case NotificationType.retweet:
        return const Color(0xFF17BF63).withValues(alpha: 0.1);
      case NotificationType.follow:
        return const Color(0xFF1D9BF0).withValues(alpha: 0.1);
      case NotificationType.reply:
        return const Color(0xFF1D9BF0).withValues(alpha: 0.1);
      case NotificationType.mention:
        return const Color(0xFF1D9BF0).withValues(alpha: 0.1);
      case NotificationType.message:
        return const Color(0xFF1D9BF0).withValues(alpha: 0.1);
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: NotificationType.fromString(json['type'] as String? ?? 'like'),
      isRead: json['is_read'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      fromUserId: json['from_user_id'] as String?,
      fromUsername: json['from_username'] as String?,
      fromAvatarUrl: json['from_avatar_url'] as String?,
      fromDisplayName: json['from_display_name'] as String?,
      tweetId: json['tweet_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'is_read': isRead,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'from_user_id': fromUserId,
      'from_username': fromUsername,
      'from_avatar_url': fromAvatarUrl,
      'from_display_name': fromDisplayName,
      'tweet_id': tweetId,
    };
  }
}