import 'package:adentweet/core/constants/api_constants.dart';

class ConversationModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String otherUserId;
  final String otherUsername;
  final String? otherAvatarUrl;
  final String otherDisplayName;
  final bool otherIsVerified;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTime,
    required this.otherUserId,
    required this.otherUsername,
    this.otherAvatarUrl,
    required this.otherDisplayName,
    required this.otherIsVerified,
    required this.unreadCount,
  });

  String get otherFullAvatarUrl {
    if (otherAvatarUrl == null || otherAvatarUrl!.isEmpty) return '';
    return ApiConstants.getAvatarUrl(otherAvatarUrl!);
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      otherUserId: json['other_user_id'] as String,
      otherUsername: json['other_username'] as String? ?? '',
      otherAvatarUrl: json['other_avatar_url'] as String?,
      otherDisplayName: json['other_display_name'] as String? ?? '',
      otherIsVerified: json['other_is_verified'] as bool? ?? false,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt.toIso8601String(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'other_user_id': otherUserId,
      'other_username': otherUsername,
      'other_avatar_url': otherAvatarUrl,
      'other_display_name': otherDisplayName,
      'other_is_verified': otherIsVerified,
      'unread_count': unreadCount,
    };
  }
}