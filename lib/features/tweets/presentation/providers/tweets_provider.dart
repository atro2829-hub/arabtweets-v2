import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:adentweet/core/constants/api_constants.dart';
import 'package:adentweet/features/tweets/data/models/tweet_model.dart';

final _supabase = Supabase.instance.client;
const _uuid = Uuid();

// ─── Helper: current user ID ────────────────────────────────────────────────

String? _currentUserId() {
  return _supabase.auth.currentUser?.id;
}

// ─── Feed Provider ──────────────────────────────────────────────────────────

class FeedState {
  final List<TweetModel> tweets;
  final bool hasMore;
  final bool isLoadingMore;

  const FeedState({
    this.tweets = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  FeedState copyWith({
    List<TweetModel>? tweets,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return FeedState(
      tweets: tweets ?? this.tweets,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class FeedNotifier extends AsyncNotifier<FeedState> {
  @override
  Future<FeedState> build() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const FeedState();
    }

    final data = await _supabase.rpc(
      'get_feed',
      params: {
        'p_user_id': userId,
        'p_limit': ApiConstants.feedPageSize,
        'p_offset': 0,
      },
    ).then<List<Map<String, dynamic>>>((res) {
      if (res == null) return [];
      return (res as List).cast<Map<String, dynamic>>();
    });

    final tweets = data.map((e) => TweetModel.fromJson(e)).toList();

    return FeedState(
      tweets: tweets,
      hasMore: tweets.length >= ApiConstants.feedPageSize,
    );
  }

  Future<void> refresh() async {
    final userId = _currentUserId();
    if (userId == null) return;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final data = await _supabase.rpc(
        'get_feed',
        params: {
          'p_user_id': userId,
          'p_limit': ApiConstants.feedPageSize,
          'p_offset': 0,
        },
      ).then<List<Map<String, dynamic>>>((res) {
        if (res == null) return [];
        return (res as List).cast<Map<String, dynamic>>();
      });

      final tweets = data.map((e) => TweetModel.fromJson(e)).toList();

      return FeedState(
        tweets: tweets,
        hasMore: tweets.length >= ApiConstants.feedPageSize,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final userId = _currentUserId();
    if (userId == null) return;

    try {
      final data = await _supabase.rpc(
        'get_feed',
        params: {
          'p_user_id': userId,
          'p_limit': ApiConstants.feedPageSize,
          'p_offset': current.tweets.length,
        },
      ).then<List<Map<String, dynamic>>>((res) {
        if (res == null) return [];
        return (res as List).cast<Map<String, dynamic>>();
      });

      final newTweets = data.map((e) => TweetModel.fromJson(e)).toList();
      final allTweets = [...current.tweets, ...newTweets];

      state = AsyncData(current.copyWith(
        tweets: allTweets,
        hasMore: newTweets.length >= ApiConstants.feedPageSize,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  void prependTweet(TweetModel tweet) {
    final current = state.valueOrNull;
    if (current == null) return;

    final existing = current.tweets.any((t) => t.id == tweet.id);
    if (existing) return;

    state = AsyncData(current.copyWith(
      tweets: [tweet, ...current.tweets],
    ));
  }
}

final feedProvider = AsyncNotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);

// ─── Tweet Detail Provider ──────────────────────────────────────────────────

class TweetDetailState {
  final TweetModel? tweet;
  final List<TweetModel> replies;
  final bool hasMoreReplies;
  final bool isLoadingMoreReplies;

  const TweetDetailState({
    this.tweet,
    this.replies = const [],
    this.hasMoreReplies = true,
    this.isLoadingMoreReplies = false,
  });

  TweetDetailState copyWith({
    TweetModel? tweet,
    List<TweetModel>? replies,
    bool? hasMoreReplies,
    bool? isLoadingMoreReplies,
  }) {
    return TweetDetailState(
      tweet: tweet ?? this.tweet,
      replies: replies ?? this.replies,
      hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
      isLoadingMoreReplies: isLoadingMoreReplies ?? this.isLoadingMoreReplies,
    );
  }
}

class TweetDetailNotifier extends FamilyAsyncNotifier<TweetDetailState, String> {
  @override
  Future<TweetDetailState> build(String arg) async {
    final userId = _currentUserId();

    final responses = await Future.wait([
      _fetchTweet(arg, userId),
      _fetchReplies(arg, userId, 0),
    ]);

    final tweet = responses[0] as TweetModel?;
    final replies = responses[1] as List<TweetModel>;

    return TweetDetailState(
      tweet: tweet,
      replies: replies,
      hasMoreReplies: replies.length >= ApiConstants.feedPageSize,
    );
  }

  Future<TweetModel?> _fetchTweet(String tweetId, String? userId) async {
    try {
      final data = await _supabase
          .from('tweets')
          .select('''
            id, user_id, content, media_urls, media_type,
            quote_tweet_id, reply_to_id, reply_to_user_id,
            is_pinned, views_count, likes_count, retweets_count,
            replies_count, bookmarks_count, created_at, updated_at,
            profiles!id (
              id, display_name, username, avatar_url, is_verified, verification_type
            )
          ''')
          .eq('id', tweetId)
          .single();

      final json = Map<String, dynamic>.from(data as Map);
      if (json['profiles'] != null && json['profiles'] is Map) {
        final profile = Map<String, dynamic>.from(json['profiles'] as Map);
        json['user_id'] = profile['id'];
        json['display_name'] = profile['display_name'];
        json['username'] = profile['username'];
        json['avatar_url'] = profile['avatar_url'];
        json['is_verified'] = profile['is_verified'];
        json['verification_type'] = profile['verification_type'];
      }

      bool isLiked = false;
      bool isRetweeted = false;
      bool isBookmarked = false;

      if (userId != null) {
        final results = await Future.wait([
          _supabase
              .from('likes')
              .select('id')
              .eq('user_id', userId)
              .eq('tweet_id', tweetId)
              .maybeSingle(),
          _supabase
              .from('retweets')
              .select('id')
              .eq('user_id', userId)
              .eq('tweet_id', tweetId)
              .maybeSingle(),
          _supabase
              .from('bookmarks')
              .select('id')
              .eq('user_id', userId)
              .eq('tweet_id', tweetId)
              .maybeSingle(),
        ]);

        isLiked = results[0] != null;
        isRetweeted = results[1] != null;
        isBookmarked = results[2] != null;
      }

      json['is_liked'] = isLiked;
      json['is_retweeted'] = isRetweeted;
      json['is_bookmarked'] = isBookmarked;

      return TweetModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<List<TweetModel>> _fetchReplies(
    String tweetId,
    String? userId,
    int offset,
  ) async {
    try {
      final data = await _supabase.rpc(
        'get_tweet_replies',
        params: {
          'p_tweet_id': tweetId,
          'p_user_id': userId,
          'p_limit': ApiConstants.feedPageSize,
          'p_offset': offset,
        },
      ).then<List<Map<String, dynamic>>>((res) {
        if (res == null) return [];
        return (res as List).cast<Map<String, dynamic>>();
      });

      return data.map((e) => TweetModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> loadMoreReplies() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMoreReplies || current.isLoadingMoreReplies) return;

    state = AsyncData(current.copyWith(isLoadingMoreReplies: true));

    final userId = _currentUserId();
    final newReplies = await _fetchReplies(
      arg,
      userId,
      current.replies.length,
    );

    final allReplies = [...current.replies, ...newReplies];

    state = AsyncData(current.copyWith(
      replies: allReplies,
      hasMoreReplies: newReplies.length >= ApiConstants.feedPageSize,
      isLoadingMoreReplies: false,
    ));
  }

  void addReply(TweetModel reply) {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(
      replies: [reply, ...current.replies],
      tweet: current.tweet?.copyWith(
        repliesCount: current.tweet!.repliesCount + 1,
      ),
    ));
  }

  void updateTweetInteraction({
    required String tweetId,
    bool? isLiked,
    int? likesCount,
    bool? isRetweeted,
    int? retweetsCount,
    bool? isBookmarked,
    int? bookmarksCount,
  }) {
    final current = state.valueOrNull;
    if (current == null || current.tweet?.id != tweetId) return;

    state = AsyncData(current.copyWith(
      tweet: current.tweet!.copyWith(
        isLiked: isLiked ?? current.tweet!.isLiked,
        likesCount: likesCount ?? current.tweet!.likesCount,
        isRetweeted: isRetweeted ?? current.tweet!.isRetweeted,
        retweetsCount: retweetsCount ?? current.tweet!.retweetsCount,
        isBookmarked: isBookmarked ?? current.tweet!.isBookmarked,
        bookmarksCount: bookmarksCount ?? current.tweet!.bookmarksCount,
      ),
    ));
  }
}

final tweetDetailProvider =
    AsyncNotifierProvider.family<TweetDetailNotifier, TweetDetailState, String>(
  TweetDetailNotifier.new,
);

// ─── Create Tweet Provider ──────────────────────────────────────────────────

class CreateTweetState {
  final bool isLoading;
  final String? error;

  const CreateTweetState({
    this.isLoading = false,
    this.error,
  });

  CreateTweetState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CreateTweetState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CreateTweetNotifier extends Notifier<CreateTweetState> {
  @override
  CreateTweetState build() {
    return const CreateTweetState();
  }

  Future<TweetModel?> createTweet({
    required String content,
    List<XFile>? mediaFiles,
    String mediaType = 'none',
    String? quoteTweetId,
    String? replyToId,
    String? replyToUserId,
  }) async {
    final userId = _currentUserId();
    if (userId == null) return null;

    state = const CreateTweetState(isLoading: true);

    try {
      List<String> uploadedMediaUrls = [];

      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (final file in mediaFiles) {
          final path = await _uploadMedia(file, userId);
          if (path != null) {
            uploadedMediaUrls.add(path);
          }
        }
      }

      final actualMediaType = uploadedMediaUrls.isNotEmpty
          ? mediaType
          : 'none';

      final tweetId = await _supabase.rpc(
        'create_tweet',
        params: {
          'p_user_id': userId,
          'p_content': content,
          'p_media_urls': uploadedMediaUrls.isNotEmpty
              ? uploadedMediaUrls
              : [],
          'p_media_type': actualMediaType,
          'p_quote_tweet_id': quoteTweetId,
          'p_reply_to_id': replyToId,
          'p_reply_to_user_id': replyToUserId,
        },
      );

      state = const CreateTweetState();

      if (tweetId == null) return null;

      final userData = await _supabase
          .from('profiles')
          .select('id, display_name, username, avatar_url, is_verified, verification_type')
          .eq('id', userId)
          .single();

      final json = Map<String, dynamic>.from(userData as Map);
      json['id'] = tweetId as String;
      json['user_id'] = userId;
      json['content'] = content;
      json['media_urls'] = uploadedMediaUrls;
      json['media_type'] = actualMediaType;
      json['quote_tweet_id'] = quoteTweetId;
      json['reply_to_id'] = replyToId;
      json['reply_to_user_id'] = replyToUserId;
      json['is_pinned'] = false;
      json['views_count'] = 0;
      json['likes_count'] = 0;
      json['retweets_count'] = 0;
      json['replies_count'] = 0;
      json['bookmarks_count'] = 0;
      json['created_at'] = DateTime.now().toIso8601String();
      json['is_liked'] = false;
      json['is_retweeted'] = false;
      json['is_bookmarked'] = false;

      return TweetModel.fromJson(json);
    } catch (e) {
      state = CreateTweetState(error: e.toString());
      return null;
    }
  }

  Future<String?> _uploadMedia(XFile file, String userId) async {
    try {
      final fileBytes = await file.readAsBytes();
      final ext = p.extension(file.path).toLowerCase();
      final fileName = '${_uuid.v4()}$ext';
      final storagePath = 'tweets/$userId/$fileName';

      await _supabase.storage
          .from(ApiConstants.mediaBucket)
          .uploadBinary(storagePath, fileBytes);

      return storagePath;
    } catch (e) {
      return null;
    }
  }

  void reset() {
    state = const CreateTweetState();
  }
}

final createTweetProvider =
    NotifierProvider<CreateTweetNotifier, CreateTweetState>(
  CreateTweetNotifier.new,
);

// ─── Toggle Like Provider ───────────────────────────────────────────────────

class ToggleLikeNotifier extends FamilyAsyncNotifier<bool, String> {
  @override
  Future<bool> build(String arg) async {
    return false;
  }

  Future<void> toggleLike(String tweetId) async {
    final userId = _currentUserId();
    if (userId == null) return;

    final currentTweetLiked = state.valueOrNull ?? false;
    final optimisticValue = !currentTweetLiked;

    state = AsyncData(optimisticValue);

    try {
      final result = await _supabase.rpc(
        'toggle_like',
        params: {
          'p_user_id': userId,
          'p_tweet_id': tweetId,
        },
      );

      state = AsyncData(result as bool? ?? currentTweetLiked);
    } catch (_) {
      state = AsyncData(currentTweetLiked);
    }
  }
}

final toggleLikeProvider =
    AsyncNotifierProvider.family<ToggleLikeNotifier, bool, String>(
  ToggleLikeNotifier.new,
);

// ─── Toggle Retweet Provider ────────────────────────────────────────────────

class ToggleRetweetNotifier extends FamilyAsyncNotifier<bool, String> {
  @override
  Future<bool> build(String arg) async {
    return false;
  }

  Future<void> toggleRetweet(String tweetId) async {
    final userId = _currentUserId();
    if (userId == null) return;

    final currentRetweeted = state.valueOrNull ?? false;
    final optimisticValue = !currentRetweeted;

    state = AsyncData(optimisticValue);

    try {
      final result = await _supabase.rpc(
        'toggle_retweet',
        params: {
          'p_user_id': userId,
          'p_tweet_id': tweetId,
        },
      );

      state = AsyncData(result as bool? ?? currentRetweeted);
    } catch (_) {
      state = AsyncData(currentRetweeted);
    }
  }
}

final toggleRetweetProvider =
    AsyncNotifierProvider.family<ToggleRetweetNotifier, bool, String>(
  ToggleRetweetNotifier.new,
);

// ─── Toggle Bookmark Provider ───────────────────────────────────────────────

class ToggleBookmarkNotifier extends FamilyAsyncNotifier<bool, String> {
  @override
  Future<bool> build(String arg) async {
    return false;
  }

  Future<void> toggleBookmark(String tweetId) async {
    final userId = _currentUserId();
    if (userId == null) return;

    final currentBookmarked = state.valueOrNull ?? false;
    final optimisticValue = !currentBookmarked;

    state = AsyncData(optimisticValue);

    try {
      final result = await _supabase.rpc(
        'toggle_bookmark',
        params: {
          'p_user_id': userId,
          'p_tweet_id': tweetId,
        },
      );

      state = AsyncData(result as bool? ?? currentBookmarked);
    } catch (_) {
      state = AsyncData(currentBookmarked);
    }
  }
}

final toggleBookmarkProvider =
    AsyncNotifierProvider.family<ToggleBookmarkNotifier, bool, String>(
  ToggleBookmarkNotifier.new,
);

// ─── User Tweets Provider ───────────────────────────────────────────────────

class UserTweetsState {
  final List<TweetModel> tweets;
  final bool hasMore;
  final bool isLoadingMore;

  const UserTweetsState({
    this.tweets = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  UserTweetsState copyWith({
    List<TweetModel>? tweets,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return UserTweetsState(
      tweets: tweets ?? this.tweets,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class UserTweetsNotifier extends FamilyAsyncNotifier<UserTweetsState, String> {
  @override
  Future<UserTweetsState> build(String arg) async {
    final userId = _currentUserId();

    final data = await _supabase.rpc(
      'get_user_tweets',
      params: {
        'p_user_id': arg,
        'p_current_user_id': userId,
        'p_limit': ApiConstants.feedPageSize,
        'p_offset': 0,
      },
    ).then<List<Map<String, dynamic>>>((res) {
      if (res == null) return [];
      return (res as List).cast<Map<String, dynamic>>();
    });

    final tweets = data.map((e) => TweetModel.fromJson(e)).toList();

    return UserTweetsState(
      tweets: tweets,
      hasMore: tweets.length >= ApiConstants.feedPageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final userId = _currentUserId();
    if (userId == null) return;

    try {
      final data = await _supabase.rpc(
        'get_user_tweets',
        params: {
          'p_user_id': arg,
          'p_current_user_id': userId,
          'p_limit': ApiConstants.feedPageSize,
          'p_offset': current.tweets.length,
        },
      ).then<List<Map<String, dynamic>>>((res) {
        if (res == null) return [];
        return (res as List).cast<Map<String, dynamic>>();
      });

      final newTweets = data.map((e) => TweetModel.fromJson(e)).toList();
      final allTweets = [...current.tweets, ...newTweets];

      state = AsyncData(current.copyWith(
        tweets: allTweets,
        hasMore: newTweets.length >= ApiConstants.feedPageSize,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final userTweetsProvider =
    AsyncNotifierProvider.family<UserTweetsNotifier, UserTweetsState, String>(
  UserTweetsNotifier.new,
);

// ─── Bookmarked Tweets Provider ─────────────────────────────────────────────

class BookmarkedTweetsState {
  final List<TweetModel> tweets;
  final bool hasMore;
  final bool isLoadingMore;

  const BookmarkedTweetsState({
    this.tweets = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  BookmarkedTweetsState copyWith({
    List<TweetModel>? tweets,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return BookmarkedTweetsState(
      tweets: tweets ?? this.tweets,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class BookmarkedTweetsNotifier extends AsyncNotifier<BookmarkedTweetsState> {
  @override
  Future<BookmarkedTweetsState> build() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const BookmarkedTweetsState();
    }

    return _fetchBookmarks(userId, 0);
  }

  Future<BookmarkedTweetsState> _fetchBookmarks(
    String userId,
    int offset,
  ) async {
    try {
      final bookmarkData = await _supabase
          .from('bookmarks')
          .select('tweet_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + ApiConstants.feedPageSize - 1);

      final bookmarks = List<Map<String, dynamic>>.from(bookmarkData as List);
      if (bookmarks.isEmpty) {
        return BookmarkedTweetsState(tweets: [], hasMore: false);
      }

      final tweetIds = bookmarks.map((b) => b['tweet_id'] as String).toList();

      final tweetsData = await _supabase
          .from('tweets')
          .select('''
            id, user_id, content, media_urls, media_type,
            quote_tweet_id, reply_to_id, reply_to_user_id,
            is_pinned, views_count, likes_count, retweets_count,
            replies_count, bookmarks_count, created_at, updated_at,
            profiles!id (
              id, display_name, username, avatar_url, is_verified, verification_type
            )
          ''')
          .inFilter('id', tweetIds);

      final tweets = <TweetModel>[];

      for (final row in tweetsData) {
        final json = Map<String, dynamic>.from(row as Map);
        if (json['profiles'] != null && json['profiles'] is Map) {
          final profile = Map<String, dynamic>.from(json['profiles'] as Map);
          json['display_name'] = profile['display_name'];
          json['username'] = profile['username'];
          json['avatar_url'] = profile['avatar_url'];
          json['is_verified'] = profile['is_verified'];
          json['verification_type'] = profile['verification_type'];
        }
        json['is_liked'] = false;
        json['is_retweeted'] = false;
        json['is_bookmarked'] = true;
        tweets.add(TweetModel.fromJson(json));
      }

      // Sort bookmarks by their bookmark order
      final bookmarkOrder = {for (var i = 0; i < tweetIds.length; i++) tweetIds[i]: i};
      tweets.sort((a, b) =>
          (bookmarkOrder[a.id] ?? 0).compareTo(bookmarkOrder[b.id] ?? 0));

      return BookmarkedTweetsState(
        tweets: tweets,
        hasMore: bookmarks.length >= ApiConstants.feedPageSize,
      );
    } catch (_) {
      return const BookmarkedTweetsState();
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final userId = _currentUserId();
    if (userId == null) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final newState = await _fetchBookmarks(userId, current.tweets.length);
    final allTweets = [...current.tweets, ...newState.tweets];

    state = AsyncData(current.copyWith(
      tweets: allTweets,
      hasMore: newState.hasMore,
      isLoadingMore: false,
    ));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    final userId = _currentUserId();
    if (userId == null) {
      state = const AsyncData(BookmarkedTweetsState());
      return;
    }

    state = await AsyncValue.guard(() => _fetchBookmarks(userId, 0));
  }
}

final bookmarkedTweetsProvider =
    AsyncNotifierProvider<BookmarkedTweetsNotifier, BookmarkedTweetsState>(
  BookmarkedTweetsNotifier.new,
);