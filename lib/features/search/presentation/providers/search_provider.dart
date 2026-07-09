import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../tweets/data/models/tweet_model.dart';
import '../models/search_result.dart';

class SearchState {
  final String query;
  final SearchResult result;
  final bool isSearching;
  final String? error;

  const SearchState({
    this.query = '',
    this.result = const SearchResult(),
    this.isSearching = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    SearchResult? result,
    bool? isSearching,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      result: result ?? this.result,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  Timer? _debounceTimer;

  SearchNotifier(this._ref) : super(const SearchState());

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(query: query);

    if (query.trim().isEmpty) {
      state = state.copyWith(result: const SearchResult(), isSearching: false, error: null);
      return;
    }

    state = state.copyWith(isSearching: true, error: null);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final List<UserModel> users = [];
      final List<TweetModel> tweets = [];

      final results = await Future.wait([
        // Search users
        Supabase.instance.client.rpc(
          'search_users',
          params: {
            'p_query': query,
            'p_limit': ApiConstants.searchPageSize,
          },
        ),
        // Search tweets
        Supabase.instance.client.rpc(
          'search_tweets',
          params: {
            'p_query': query,
            'p_user_id': userId,
            'p_limit': ApiConstants.searchPageSize,
            'p_offset': 0,
          },
        ),
      ]);

      // Parse users
      final usersData = results[0] as List<dynamic>;
      for (final u in usersData) {
        users.add(UserModel.fromMinimalJson(u as Map<String, dynamic>));
      }

      // Parse tweets
      final tweetsData = results[1] as List<dynamic>;
      for (final t in tweetsData) {
        tweets.add(TweetModel.fromJson(t as Map<String, dynamic>));
      }

      if (mounted) {
        state = state.copyWith(
          result: SearchResult(users: users, tweets: tweets),
          isSearching: false,
          error: null,
        );
      }

      // Save to search history
      _saveToHistory(query);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSearching: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> _saveToHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];

      // Remove duplicate if exists
      history.remove(query);

      // Add to beginning
      history.insert(0, query);

      // Keep only last 20
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }

      await prefs.setStringList('search_history', history);
    } catch (_) {}
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = state.copyWith(
      query: '',
      result: const SearchResult(),
      isSearching: false,
      error: null,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref);
});

class TrendingHashtagsNotifier extends StateNotifier<AsyncValue<List<TrendingHashtag>>> {
  TrendingHashtagsNotifier() : super(const AsyncValue.loading()) {
    _fetchTrending();
  }

  Future<void> _fetchTrending() async {
    try {
      final response = await Supabase.instance.client.rpc('get_trending_hashtags');
      final List<dynamic> data = response as List<dynamic>;
      final hashtags =
          data.map((e) => TrendingHashtag.fromJson(e as Map<String, dynamic>)).toList();

      state = AsyncValue.data(hashtags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() {
    state = const AsyncValue.loading();
    _fetchTrending();
  }
}

final trendingHashtagsProvider =
    StateNotifierProvider<TrendingHashtagsNotifier, AsyncValue<List<TrendingHashtag>>>(
  (ref) => TrendingHashtagsNotifier(),
);

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super(const []) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      state = history;
    } catch (_) {
      state = [];
    }
  }

  Future<void> removeItem(String query) async {
    final updated = List<String>.from(state)..remove(query);
    state = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', updated);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    state = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
    } catch (_) {}
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});