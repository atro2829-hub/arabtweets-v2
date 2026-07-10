import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:adentweet/core/constants/api_constants.dart';
import 'package:adentweet/features/auth/data/models/user_model.dart';
import 'package:adentweet/features/tweets/data/models/tweet_model.dart';

// ─── User Profile Provider (AsyncNotifier) ─────────────────────────────────

final userProfileProvider =
    AsyncNotifierProvider.family<UserProfileNotifier, UserModel, String>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends FamilyAsyncNotifier<UserModel, String> {
  @override
  Future<UserModel> build(String username) async {
    final client = Supabase.instance.client;
    final response = await client.rpc('get_user_profile', params: {
      'p_username': username,
    });

    final data = response as List<dynamic>;
    if (data.isEmpty) {
      throw Exception('المستخدم غير موجود');
    }

    final profile = UserModel.fromJson(data.first as Map<String, dynamic>);
    // Parse created_at from the profile
    return profile;
  }
}

// ─── Is Following Provider ────────────────────────────────────────────────

final isFollowingProvider =
    FutureProvider.family.autoDispose<bool, String>((ref, userId) async {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  if (currentUserId == null || currentUserId == userId) return false;

  final response = await Supabase.instance.client
      .from('follows')
      .select()
      .eq('follower_id', currentUserId)
      .eq('following_id', userId)
      .maybeSingle();

  return response != null;
});

// ─── Toggle Follow Provider ───────────────────────────────────────────────

class ToggleFollowState {
  final bool isFollowing;
  final bool isLoading;

  ToggleFollowState({required this.isFollowing, this.isLoading = false});

  ToggleFollowState copyWith({bool? isFollowing, bool? isLoading}) {
    return ToggleFollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final toggleFollowProvider = NotifierProvider<ToggleFollowNotifier, ToggleFollowState>(
  ToggleFollowNotifier.new,
);

class ToggleFollowNotifier extends Notifier<ToggleFollowState> {
  @override
  ToggleFollowState build() {
    return ToggleFollowState(isFollowing: false);
  }

  Future<void> toggleFollow({
    required String followerId,
    required String followingId,
    bool currentFollowing = false,
  }) async {
    state = state.copyWith(isLoading: true, isFollowing: !currentFollowing);

    try {
      final result = await Supabase.instance.client.rpc('toggle_follow', params: {
        'p_follower_id': followerId,
        'p_following_id': followingId,
      });

      final nowFollowing = result as bool;
      state = ToggleFollowState(isFollowing: nowFollowing);
    } catch (e) {
      state = state.copyWith(isFollowing: currentFollowing, isLoading: false);
      rethrow;
    }
  }
}

// ─── Edit Profile Provider ────────────────────────────────────────────────

class EditProfileState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  EditProfileState({this.isLoading = false, this.isSuccess = false, this.error});

  EditProfileState copyWith({bool? isLoading, bool? isSuccess, String? error}) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

final editProfileProvider =
    NotifierProvider<EditProfileNotifier, EditProfileState>(
  EditProfileNotifier.new,
);

class EditProfileNotifier extends Notifier<EditProfileState> {
  @override
  EditProfileState build() {
    return EditProfileState();
  }

  Future<void> updateProfile({
    required String userId,
    required String displayName,
    required String username,
    required String bio,
    required String location,
    required String website,
    File? newAvatarFile,
    File? newCoverFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final client = Supabase.instance.client;
      String? avatarPath;
      String? coverPath;

      // Upload new avatar if provided
      if (newAvatarFile != null) {
        final ext = newAvatarFile.path.split('.').last;
        avatarPath = '$userId/${const Uuid().v4()}.$ext';
        await client.storage
            .from(ApiConstants.avatarsBucket)
            .upload(avatarPath, newAvatarFile);
      }

      // Upload new cover if provided
      if (newCoverFile != null) {
        final ext = newCoverFile.path.split('.').last;
        coverPath = '$userId/${const Uuid().v4()}.$ext';
        await client.storage
            .from(ApiConstants.coversBucket)
            .upload(coverPath, newCoverFile);
      }

      // Build update map
      final updateData = <String, dynamic>{
        'display_name': displayName,
        'username': username,
        'bio': bio,
        'location': location,
        'website': website,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (avatarPath != null) {
        updateData['avatar_url'] = avatarPath;
      }
      if (coverPath != null) {
        updateData['cover_url'] = coverPath;
      }

      await client
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = EditProfileState();
  }
}

// ─── User Tweets Provider ─────────────────────────────────────────────────

final userTweetsProvider =
    FutureProvider.family.autoDispose<List<TweetModel>, String>((ref, userId) async {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  final client = Supabase.instance.client;

  final response = await client.rpc('get_user_tweets', params: {
    'p_user_id': userId,
    'p_current_user_id': currentUserId,
    'p_limit': ApiConstants.feedPageSize,
    'p_offset': 0,
  });

  final data = response as List<dynamic>;
  return data
      .map((e) => TweetModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── User Replies Provider ────────────────────────────────────────────────

final userRepliesProvider =
    FutureProvider.family.autoDispose<List<TweetModel>, String>((ref, userId) async {
  final client = Supabase.instance.client;

  final response = await client
      .from('tweets')
      .select('''
        id, user_id, content, media_urls, media_type,
        likes_count, retweets_count, replies_count, views_count,
        bookmarks_count, created_at, reply_to_id, reply_to_user_id,
        profiles!tweets_user_id_fkey(display_name, username, avatar_url, is_verified, verification_type)
      ''')
      .eq('user_id', userId)
      .not('reply_to_id', 'is', null)
      .order('created_at', ascending: false)
      .limit(ApiConstants.feedPageSize);

  final data = response as List<dynamic>;
  return data.map((e) {
    final map = e as Map<String, dynamic>;
    final profile = map['profiles'] as Map<String, dynamic>?;
    return TweetModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String? ?? '',
      mediaUrls: (map['media_urls'] as List<dynamic>?)
              ?.map((url) => url.toString())
              .toList() ??
          [],
      mediaType: map['media_type'] as String? ?? 'none',
      replyToId: map['reply_to_id'] as String?,
      replyToUserId: map['reply_to_user_id'] as String?,
      likesCount: map['likes_count'] as int? ?? 0,
      retweetsCount: map['retweets_count'] as int? ?? 0,
      repliesCount: map['replies_count'] as int? ?? 0,
      viewsCount: map['views_count'] as int? ?? 0,
      bookmarksCount: map['bookmarks_count'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      displayName: profile?['display_name'] as String?,
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      isVerified: profile?['is_verified'] as bool?,
      verificationType: profile?['verification_type'] as String?,
    );
  }).toList();
});

// ─── User Likes Provider ──────────────────────────────────────────────────

final userLikesProvider =
    FutureProvider.family.autoDispose<List<TweetModel>, String>((ref, userId) async {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  final client = Supabase.instance.client;

  final response = await client
      .from('likes')
      .select('''
        tweet_id,
        tweets!likes_tweet_id_fkey(
          id, user_id, content, media_urls, media_type,
          likes_count, retweets_count, replies_count, views_count,
          bookmarks_count, created_at, reply_to_id, reply_to_user_id,
          profiles!tweets_user_id_fkey(display_name, username, avatar_url, is_verified, verification_type)
        )
      ''')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(ApiConstants.feedPageSize);

  final data = response as List<dynamic>;
  return data.map((e) {
    final map = e as Map<String, dynamic>;
    final tweet = map['tweets'] as Map<String, dynamic>;
    final profile = tweet['profiles'] as Map<String, dynamic>?;

    // Check if current user liked this tweet
    bool isLikedByMe = false;
    if (currentUserId != null) {
      isLikedByMe = true; // We know this is from the likes table
    }

    return TweetModel(
      id: tweet['id'] as String,
      userId: tweet['user_id'] as String,
      content: tweet['content'] as String? ?? '',
      mediaUrls: (tweet['media_urls'] as List<dynamic>?)
              ?.map((url) => url.toString())
              .toList() ??
          [],
      mediaType: tweet['media_type'] as String? ?? 'none',
      replyToId: tweet['reply_to_id'] as String?,
      replyToUserId: tweet['reply_to_user_id'] as String?,
      likesCount: tweet['likes_count'] as int? ?? 0,
      retweetsCount: tweet['retweets_count'] as int? ?? 0,
      repliesCount: tweet['replies_count'] as int? ?? 0,
      viewsCount: tweet['views_count'] as int? ?? 0,
      bookmarksCount: tweet['bookmarks_count'] as int? ?? 0,
      createdAt: tweet['created_at'] != null
          ? DateTime.parse(tweet['created_at'] as String)
          : DateTime.now(),
      displayName: profile?['display_name'] as String?,
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      isVerified: profile?['is_verified'] as bool?,
      verificationType: profile?['verification_type'] as String?,
      isLiked: isLikedByMe,
    );
  }).toList();
});

// ─── User Media Provider ──────────────────────────────────────────────────

final userMediaProvider =
    FutureProvider.family.autoDispose<List<TweetModel>, String>((ref, userId) async {
  final client = Supabase.instance.client;

  final response = await client
      .from('tweets')
      .select('''
        id, user_id, content, media_urls, media_type,
        likes_count, retweets_count, replies_count, views_count,
        bookmarks_count, created_at, reply_to_id, reply_to_user_id,
        profiles!tweets_user_id_fkey(display_name, username, avatar_url, is_verified, verification_type)
      ''')
      .eq('user_id', userId)
      .neq('media_urls', '{}')
      .neq('media_type', 'none')
      .order('created_at', ascending: false)
      .limit(ApiConstants.feedPageSize);

  final data = response as List<dynamic>;
  return data.map((e) {
    final map = e as Map<String, dynamic>;
    final profile = map['profiles'] as Map<String, dynamic>?;
    return TweetModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String? ?? '',
      mediaUrls: (map['media_urls'] as List<dynamic>?)
              ?.map((url) => url.toString())
              .toList() ??
          [],
      mediaType: map['media_type'] as String? ?? 'none',
      replyToId: map['reply_to_id'] as String?,
      replyToUserId: map['reply_to_user_id'] as String?,
      likesCount: map['likes_count'] as int? ?? 0,
      retweetsCount: map['retweets_count'] as int? ?? 0,
      repliesCount: map['replies_count'] as int? ?? 0,
      viewsCount: map['views_count'] as int? ?? 0,
      bookmarksCount: map['bookmarks_count'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      displayName: profile?['display_name'] as String?,
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      isVerified: profile?['is_verified'] as bool?,
      verificationType: profile?['verification_type'] as String?,
    );
  }).toList();
});