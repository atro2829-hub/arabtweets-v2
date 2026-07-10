import 'package:adentweet/core/constants/api_constants.dart';

class UserModel {
  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? location;
  final String? website;
  final bool isVerified;
  final String? verificationType;
  final bool isAdmin;
  final bool isBanned;
  final int followersCount;
  final int followingCount;
  final int tweetsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.location,
    this.website,
    this.isVerified = false,
    this.verificationType,
    this.isAdmin = false,
    this.isBanned = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.tweetsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAvatarUrl => ApiConstants.getAvatarUrl(avatarUrl);

  String get fullCoverUrl => ApiConstants.getCoverUrl(coverUrl);

  String get displayHandle => '@$username';

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verificationType: json['verification_type'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      isBanned: json['is_banned'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      tweetsCount: json['tweets_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'bio': bio,
      'location': location,
      'website': website,
      'is_verified': isVerified,
      'verification_type': verificationType,
      'is_admin': isAdmin,
      'is_banned': isBanned,
      'followers_count': followersCount,
      'following_count': followingCount,
      'tweets_count': tweetsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? location,
    String? website,
    bool? isVerified,
    String? verificationType,
    bool? isAdmin,
    bool? isBanned,
    int? followersCount,
    int? followingCount,
    int? tweetsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      isVerified: isVerified ?? this.isVerified,
      verificationType: verificationType ?? this.verificationType,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      tweetsCount: tweetsCount ?? this.tweetsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, displayName: $displayName, username: $username, '
        'isVerified: $isVerified, isAdmin: $isAdmin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}