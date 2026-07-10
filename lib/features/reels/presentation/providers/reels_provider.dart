import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../data/models/reel_model.dart';

class ReelsState {
  final List<ReelModel> reels;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final String? error;

  const ReelsState({
    this.reels = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.offset = 0,
    this.error,
  });

  ReelsState copyWith({
    List<ReelModel>? reels,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    String? error,
  }) {
    return ReelsState(
      reels: reels ?? this.reels,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      error: error,
    );
  }
}

class ReelsNotifier extends StateNotifier<ReelsState> {
  final Ref _ref;

  ReelsNotifier(this._ref) : super(const ReelsState()) {
    _init();
  }

  void _init() {
    fetchReels();
  }

  Future<void> fetchReels({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, offset: 0, error: null);
    } else if (state.isLoading) {
      return;
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final response = await Supabase.instance.client.rpc(
        'get_reels',
        params: {
          'p_user_id': userId,
          'p_limit': ApiConstants.reelsPageSize,
          'p_offset': 0,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      final reels = data.map((e) => ReelModel.fromJson(e as Map<String, dynamic>)).toList();

      if (mounted) {
        state = state.copyWith(
          reels: reels,
          isLoading: false,
          hasMore: reels.length >= ApiConstants.reelsPageSize,
          offset: reels.length,
          error: null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> fetchMoreReels() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final response = await Supabase.instance.client.rpc(
        'get_reels',
        params: {
          'p_user_id': userId,
          'p_limit': ApiConstants.reelsPageSize,
          'p_offset': state.offset,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      final newReels = data.map((e) => ReelModel.fromJson(e as Map<String, dynamic>)).toList();

      if (mounted) {
        state = state.copyWith(
          reels: [...state.reels, ...newReels],
          isLoadingMore: false,
          hasMore: newReels.length >= ApiConstants.reelsPageSize,
          offset: state.offset + newReels.length,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }

  void reset() {
    state = const ReelsState();
    fetchReels();
  }
}

final reelsProvider = StateNotifierProvider<ReelsNotifier, ReelsState>((ref) {
  return ReelsNotifier(ref);
});

class ToggleReelLikeState {
  final bool isLoading;
  final String? error;

  const ToggleReelLikeState({this.isLoading = false, this.error});

  ToggleReelLikeState copyWith({bool? isLoading, String? error}) {
    return ToggleReelLikeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ToggleReelLikeNotifier extends StateNotifier<ToggleReelLikeState> {
  final Ref _ref;

  ToggleReelLikeNotifier(this._ref) : super(const ToggleReelLikeState());

  Future<void> toggleLike(String reelId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final reelsState = _ref.read(reelsProvider);
    final reelIndex = reelsState.reels.indexWhere((r) => r.id == reelId);
    if (reelIndex == -1) return;

    final originalReel = reelsState.reels[reelIndex];
    final wasLiked = originalReel.isLiked;

    // Optimistic update
    _ref.read(reelsProvider.notifier).state = reelsState.copyWith(
      reels: List<ReelModel>.from(reelsState.reels)
        ..[reelIndex] = originalReel.copyWith(
          isLiked: !wasLiked,
          likesCount: wasLiked
              ? (originalReel.likesCount - 1).clamp(0, double.maxFinite).toInt()
              : originalReel.likesCount + 1,
        ),
    );

    state = const ToggleReelLikeState(isLoading: true);

    try {
      await Supabase.instance.client.rpc(
        'toggle_reel_like',
        params: {
          'p_user_id': userId,
          'p_reel_id': reelId,
        },
      );

      if (mounted) {
        state = const ToggleReelLikeState();
      }
    } catch (e) {
      // Revert optimistic update on error
      final currentState = _ref.read(reelsProvider);
      final idx = currentState.reels.indexWhere((r) => r.id == reelId);
      if (idx != -1) {
        _ref.read(reelsProvider.notifier).state = currentState.copyWith(
          reels: List<ReelModel>.from(currentState.reels)
            ..[idx] = originalReel,
        );
      }

      if (mounted) {
        state = ToggleReelLikeState(error: e.toString());
      }
    }
  }
}

final toggleReelLikeProvider =
    StateNotifierProvider<ToggleReelLikeNotifier, ToggleReelLikeState>((ref) {
  return ToggleReelLikeNotifier(ref);
});

class ReelComment {
  final String id;
  final String reelId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final bool isVerified;

  const ReelComment({
    required this.id,
    required this.reelId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
  });

  factory ReelComment.fromJson(Map<String, dynamic> json) {
    return ReelComment(
      id: json['id'] as String,
      reelId: json['reel_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      displayName: (json['display_name'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
    );
  }
}

final reelCommentsProvider =
    FutureProvider.family<List<ReelComment>, String>((ref, reelId) async {
  try {
    final response = await Supabase.instance.client
        .from('reel_comments')
        .select(
            '*, profiles!reel_comments_user_id_fkey(display_name, username, avatar_url, is_verified)')
        .eq('reel_id', reelId)
        .order('created_at', ascending: true)
        .limit(20);

    return (response as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      final profile = map['profiles'] as Map<String, dynamic>?;
      return ReelComment(
        id: map['id'] as String,
        reelId: map['reel_id'] as String,
        userId: map['user_id'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        displayName: profile?['display_name'] as String? ?? '',
        username: profile?['username'] as String? ?? '',
        avatarUrl: profile?['avatar_url'] as String?,
        isVerified: (profile?['is_verified'] as bool?) ?? false,
      );
    }).toList();
  } catch (e) {
    throw Exception('Failed to load comments: $e');
  }
});