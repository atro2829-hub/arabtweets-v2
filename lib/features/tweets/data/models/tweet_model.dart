import '../../../../../core/constants/api_constants.dart';
import '../../../auth/data/models/user_model.dart';

class TweetModel {
  final String id;
  final String userId;
  final String content;
  final List<String> mediaUrls;
  final String mediaType;
  final String? quoteTweetId;
  final String? replyToId;
  final String? replyToUserId;
  final bool isPinned;
  final int viewsCount;
  final int likesCount;
  final int retweetsCount;
  final int repliesCount;
  final int bookmarksCount;
  final DateTime createdAt;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final bool? isVerified;
  final String? verificationType;
  final bool isLiked;
  final bool isRetweeted;
  final bool isBookmarked;

  TweetModel({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrls = const [],
    this.mediaType = 'none',
    this.quoteTweetId,
    this.replyToId,
    this.replyToUserId,
    this.isPinned = false,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.retweetsCount = 0,
    this.repliesCount = 0,
    this.bookmarksCount = 0,
    required this.createdAt,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.isVerified,
    this.verificationType,
    this.isLiked = false,
    this.isRetweeted = false,
    this.isBookmarked = false,
  });

  // Author convenience getters
  String get authorUsername => username ?? '';
  String get authorDisplayName => displayName ?? '';
  String get authorFullAvatarUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return '';
    return ApiConstants.getAvatarUrl(avatarUrl!);
  }
  bool get authorIsVerified => isVerified ?? false;
  String get authorVerificationType => verificationType ?? 'none';

  // Media convenience getters
  bool get hasMedia => mediaUrls.isNotEmpty && mediaType != 'none';
  bool get isGif => mediaType == 'gif';
  bool get isVideo => mediaType == 'video';
  bool get hasQuoteTweet => quoteTweetId != null;
  bool get isReply => replyToId != null;

  String get fullAvatarUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return '';
    return ApiConstants.getAvatarUrl(avatarUrl!);
  }

  List<String> get fullMediaUrls {
    return mediaUrls.map((url) => ApiConstants.getMediaUrl(url)).toList();
  }

  factory TweetModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media_urls'];
    List<String> parsedMediaUrls;
    if (rawMedia is List) {
      parsedMediaUrls = rawMedia.map((e) => e.toString()).toList();
    } else {
      parsedMediaUrls = [];
    }

    return TweetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      mediaUrls: parsedMediaUrls,
      mediaType: json['media_type'] as String? ?? 'none',
      quoteTweetId: json['quote_tweet_id'] as String?,
      replyToId: json['reply_to_id'] as String?,
      replyToUserId: json['reply_to_user_id'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      viewsCount: json['views_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      retweetsCount: json['retweets_count'] as int? ?? 0,
      repliesCount: json['replies_count'] as int? ?? 0,
      bookmarksCount: json['bookmarks_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      displayName: json['display_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool?,
      verificationType: json['verification_type'] as String?,
      isLiked: json['is_liked'] as bool? ?? false,
      isRetweeted: json['is_retweeted'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
    );
  }

  TweetModel copyWith({
    bool? isLiked,
    bool? isRetweeted,
    bool? isBookmarked,
    int? likesCount,
    int? retweetsCount,
    int? repliesCount,
  }) {
    return TweetModel(
      id: id,
      userId: userId,
      content: content,
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      quoteTweetId: quoteTweetId,
      replyToId: replyToId,
      replyToUserId: replyToUserId,
      isPinned: isPinned,
      viewsCount: viewsCount,
      likesCount: likesCount ?? this.likesCount,
      retweetsCount: retweetsCount ?? this.retweetsCount,
      repliesCount: repliesCount ?? this.repliesCount,
      bookmarksCount: bookmarksCount,
      createdAt: createdAt,
      displayName: displayName,
      username: username,
      avatarUrl: avatarUrl,
      isVerified: isVerified,
      verificationType: verificationType,
      isLiked: isLiked ?? this.isLiked,
      isRetweeted: isRetweeted ?? this.isRetweeted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}