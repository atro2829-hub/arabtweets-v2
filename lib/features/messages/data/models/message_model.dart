import '../../../../../core/constants/api_constants.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final String mediaType;
  final String? replyToId;
  final bool isRead;
  final DateTime createdAt;
  final String? senderUsername;
  final String? senderAvatarUrl;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    required this.mediaType,
    this.replyToId,
    required this.isRead,
    required this.createdAt,
    this.senderUsername,
    this.senderAvatarUrl,
  });

  String get senderFullAvatarUrl {
    if (senderAvatarUrl == null || senderAvatarUrl!.isEmpty) return ';
    return ApiConstants.getAvatarUrl(senderAvatarUrl!);
  }

  bool get hasMedia => mediaType != 'none' && mediaUrl != null && mediaUrl!.isNotEmpty;

  bool get isImage => mediaType == 'image';

  bool get isVideo => mediaType == 'video';

  bool get isAudio => mediaType == 'audio';

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String? ?? '',
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String? ?? 'none',
      replyToId: json['reply_to_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderUsername: json['sender_username'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'reply_to_id': replyToId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'sender_username': senderUsername,
      'sender_avatar_url': senderAvatarUrl,
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? mediaUrl,
    String? mediaType,
    String? replyToId,
    bool? isRead,
    DateTime? createdAt,
    String? senderUsername,
    String? senderAvatarUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      replyToId: replyToId ?? this.replyToId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderUsername: senderUsername ?? this.senderUsername,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }
}