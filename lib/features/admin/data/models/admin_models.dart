class AdminStatsModel {
  final int totalUsers;
  final int totalTweets;
  final int totalReports;
  final int totalReels;
  final int todayUsers;
  final int todayTweets;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalTweets,
    required this.totalReports,
    required this.totalReels,
    required this.todayUsers,
    required this.todayTweets,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalUsers: json['total_users'] as int? ?? 0,
      totalTweets: json['total_tweets'] as int? ?? 0,
      totalReports: json['total_reports'] as int? ?? 0,
      totalReels: json['total_reels'] as int? ?? 0,
      todayUsers: json['today_users'] as int? ?? 0,
      todayTweets: json['today_tweets'] as int? ?? 0,
    );
  }
}

class AdminUserModel {
  final String id;
  final String displayName;
  final String username;
  final String? email;
  final bool isVerified;
  final bool isAdmin;
  final bool isBanned;
  final int followersCount;
  final int tweetsCount;
  final DateTime createdAt;

  AdminUserModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.email,
    required this.isVerified,
    required this.isAdmin,
    required this.isBanned,
    required this.followersCount,
    required this.tweetsCount,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      isBanned: json['is_banned'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      tweetsCount: json['tweets_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  AdminUserModel copyWith({
    bool? isVerified,
    bool? isAdmin,
    bool? isBanned,
  }) {
    return AdminUserModel(
      id: id,
      displayName: displayName,
      username: username,
      email: email,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      followersCount: followersCount,
      tweetsCount: tweetsCount,
      createdAt: createdAt,
    );
  }
}

class AdminReportModel {
  final String id;
  final String reporterId;
  final String? targetUserId;
  final String? tweetId;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? reporterUsername;

  AdminReportModel({
    required this.id,
    required this.reporterId,
    this.targetUserId,
    this.tweetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporterUsername,
  });

  factory AdminReportModel.fromJson(Map<String, dynamic> json) {
    return AdminReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      targetUserId: json['target_user_id'] as String?,
      tweetId: json['tweet_id'] as String?,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      reporterUsername: json['reporter_username'] as String?,
    );
  }

  AdminReportModel copyWith({
    String? status,
  }) {
    return AdminReportModel(
      id: id,
      reporterId: reporterId,
      targetUserId: targetUserId,
      tweetId: tweetId,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
      reporterUsername: reporterUsername,
    );
  }
}