import 'package:adentweet/features/auth/data/models/user_model.dart';
import 'package:adentweet/core/constants/api_constants.dart';

class ReelModel {
  final String id;
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final int duration;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  final UserModel? author;
  final bool isLiked;

  const ReelModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption = '',
    this.duration = 0,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    required this.createdAt,
    this.author,
    this.isLiked = false,
  });

  String get fullVideoUrl => ApiConstants.getReelUrl(videoUrl);

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    UserModel? author;
    if (json['username'] != null) {
      author = UserModel(
        id: json['user_id'] as String,
        displayName: (json['display_name'] as String?) ?? '',
        username: json['username'] as String,
        avatarUrl: json['avatar_url'] as String?,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return ReelModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      videoUrl: (json['video_url'] as String?) ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: (json['caption'] as String?) ?? '',
      duration: (json['duration'] as int?) ?? 0,
      viewsCount: (json['views_count'] as int?) ?? 0,
      likesCount: (json['likes_count'] as int?) ?? 0,
      commentsCount: (json['comments_count'] as int?) ?? 0,
      sharesCount: (json['shares_count'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      author: author,
      isLiked: (json['is_liked'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'duration': duration,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'created_at': createdAt.toIso8601String(),
      'is_liked': isLiked,
    };
  }

  ReelModel copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? duration,
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    DateTime? createdAt,
    UserModel? author,
    bool? isLiked,
  }) {
    return ReelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      duration: duration ?? this.duration,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}