import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:adentweet/core/constants/api_constants.dart';
import 'package:adentweet/features/tweets/presentation/widgets/tweet_card.dart';
import 'package:adentweet/features/search/data/models/search_result.dart';
import 'package:adentweet/features/search/presentation/providers/search_provider.dart';
import 'package:adentweet/features/search/presentation/widgets/user_search_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(searchProvider.notifier).onQueryChanged(query);
  }

  void _onHashtagTap(String tag) {
    final query = '#$tag';
    _searchController.text = query;
    ref.read(searchProvider.notifier).onQueryChanged(query);
    _searchFocusNode.unfocus();
  }

  void _onHistoryTap(String query) {
    _searchController.text = query;
    ref.read(searchProvider.notifier).onQueryChanged(query);
    _searchFocusNode.unfocus();
  }

  Future<void> _toggleFollow(String targetUserId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == targetUserId) return;

    try {
      await Supabase.instance.client.rpc(
        'toggle_follow',
        params: {
          'p_follower_id': currentUserId,
          'p_following_id': targetUserId,
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);
    final hasQuery = searchState.query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchField(theme),
        bottom: hasQuery
            ? TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'الأشخاص'),
                  Tab(text: 'التغريدات'),
                  Tab(text: 'الأكثر رواجاً'),
                ],
              )
            : null,
        actions: [
          if (hasQuery)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                ref.read(searchProvider.notifier).clearSearch();
                _searchFocusNode.requestFocus();
              },
            ),
        ],
      ),
      body: hasQuery ? _buildSearchResults(searchState) : _buildInitialContent(),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(fontSize: 15),
        textDirection: TextDirection.rtl,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'ابحث في AdenTweet',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    if (searchState.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء البحث',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _onSearchChanged(searchState.query),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (searchState.result.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'لم يتم العثور على نتائج لـ "${searchState.query}"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPeopleTab(searchState),
        _buildTweetsTab(searchState),
        _buildTrendingTab(),
      ],
    );
  }

  Widget _buildPeopleTab(SearchState searchState) {
    final users = searchState.result.users;

    if (users.isEmpty) {
      return _buildEmptyTab('لم يتم العثور على أشخاص');
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final user = users[index];
        return UserSearchCard(
          user: user,
          onFollow: () => _toggleFollow(user.id),
          onTap: () {},
        );
      },
    );
  }

  Widget _buildTweetsTab(SearchState searchState) {
    final tweets = searchState.result.tweets;

    if (tweets.isEmpty) {
      return _buildEmptyTab('لم يتم العثور على تغريدات');
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: tweets.length,
      itemBuilder: (context, index) {
        final tweet = tweets[index];
        return TweetCard(
          tweet: tweet,
          onReply: () {},
        );
      },
    );
  }

  Widget _buildTrendingTab() {
    return _buildTrendingContent();
  }

  Widget _buildInitialContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search history
          _buildSearchHistory(),
          const Divider(height: 1),
          // Trending
          _buildTrendingContent(),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    final history = ref.watch(searchHistoryProvider);

    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عمليات البحث الأخيرة',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(searchHistoryProvider.notifier).clearAll(),
                child: Text(
                  'مسح الكل',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...history.map((query) {
          return ListTile(
            leading: const Icon(Icons.history, size: 20),
            title: Text(
              query,
              style: Theme.of(context).textTheme.bodyMedium,
              textDirection: TextDirection.rtl,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () =>
                  ref.read(searchHistoryProvider.notifier).removeItem(query),
            ),
            onTap: () => _onHistoryTap(query),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          );
        }),
      ],
    );
  }

  Widget _buildTrendingContent() {
    final trendingAsync = ref.watch(trendingHashtagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'الأكثر رواجاً',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        trendingAsync.when(
          data: (hashtags) {
            if (hashtags.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'لا توجد وسوم رائجة حالياً',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              );
            }

            return Column(
              children: hashtags.map((hashtag) {
                return _buildTrendingItem(hashtag);
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'فشل تحميل الوسوم الرائجة',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingItem(TrendingHashtag hashtag) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _onHashtagTap(hashtag.tag),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${hashtag.tag}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatCount(hashtag.count)} تغريدة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.trending_up,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count <= 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}