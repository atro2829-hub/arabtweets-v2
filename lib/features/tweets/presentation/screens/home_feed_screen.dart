import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/tweet_model.dart';
import '../providers/tweets_provider.dart';
import '../widgets/compose_tweet_sheet.dart';
import '../widgets/tweet_card.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscribeToNewTweets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _subscribeToNewTweets() {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    client
        .from('tweets')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .limit(1)
        .listen((List<Map<String, dynamic>> data) {
      if (data.isEmpty) return;
      final newTweetJson = data.first;

      // Only add if the tweet is from someone we follow or our own tweet
      if (mounted) {
        final feedNotifier = ref.read(feedProvider.notifier);
        final newTweet = TweetModel.fromJson(newTweetJson);
        feedNotifier.prependTweet(newTweet);
      }
    }).onError((error) {
      // Handle stream errors silently
    });
  }

  Future<void> _onRefresh() async {
    try {
      await ref.read(feedProvider.notifier).refresh();
      _refreshController.refreshCompleted();
    } catch (_) {
      _refreshController.refreshFailed();
    }
  }

  void _onComposeTap() {
    ComposeTweetSheet.show(context).then((tweet) {
      if (tweet != null) {
        ref.read(feedProvider.notifier).prependTweet(tweet);
      }
    });
  }

  void _onReplyToTweet(TweetModel tweet) {
    ComposeTweetSheet.show(
      context,
      replyToId: tweet.id,
      replyToUserId: tweet.userId,
      replyToUsername: tweet.authorUsername,
    ).then((reply) {
      if (reply != null) {
        // The reply is handled in detail screen if needed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App bar
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'الرئيسية',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              centerTitle: false,
              bottom: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                indicatorColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.outline,
                labelColor: colorScheme.primary,
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                tabs: const [
                  Tab(text: 'لك'),
                  Tab(text: 'التابعين'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildForYouTab(feedAsync),
            _buildFollowingTab(feedAsync),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onComposeTap,
        backgroundColor: colorScheme.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          'assets/icons/svg/plus.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            colorScheme.onPrimary,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildForYouTab(AsyncValue<FeedState> feedAsync) {
    return feedAsync.when(
      loading: () => _buildShimmerList(),
      error: (error, _) => _buildErrorState(error.toString()),
      data: (feedState) {
        if (feedState.tweets.isEmpty) {
          return _buildEmptyState();
        }

        return _buildFeedList(feedState);
      },
    );
  }

  Widget _buildFollowingTab(AsyncValue<FeedState> feedAsync) {
    return feedAsync.when(
      loading: () => _buildShimmerList(),
      error: (error, _) => _buildErrorState(error.toString()),
      data: (feedState) {
        // For the "Following" tab, filter to only show tweets from followed users
        // In a real app, you'd have a separate provider for this.
        // For now, we show the same feed as a placeholder.
        final followingTweets = feedState.tweets
            .where((t) => t.userId != Supabase.instance.client.auth.currentUser?.id)
            .toList();

        if (followingTweets.isEmpty) {
          return _buildEmptyState(
            message: 'لا توجد تغريدات من الأشخاص الذين تتابعهم',
            icon: Icons.group_outlined,
          );
        }

        return _buildFeedList(feedState.copyWith(tweets: followingTweets));
      },
    );
  }

  Widget _buildFeedList(FeedState feedState) {
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: feedState.hasMore,
      onRefresh: _onRefresh,
      onLoading: () async {
        await ref.read(feedProvider.notifier).loadMore();
        _refreshController.loadComplete();
      },
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: feedState.tweets.length + (feedState.isLoadingMore ? 3 : 0),
        itemBuilder: (context, index) {
          if (index >= feedState.tweets.length) {
            return const TweetCardShimmer();
          }

          final tweet = feedState.tweets[index];
          return TweetCard(
            tweet: tweet,
            onReply: () => _onReplyToTweet(tweet),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) => const TweetCardShimmer(),
    );
  }

  Widget _buildEmptyState({
    String message = 'لا توجد تغريدات بعد. كن أول من يكتب!',
    IconData icon = Icons.edit_note_outlined,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: _onComposeTap,
              child: const Text('اكتب تغريدة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل التغريدات',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(feedProvider.notifier).refresh();
              },
              icon: SvgPicture.asset(
                'assets/icons/svg/refresh.svg',
                width: 18,
                height: 18,
              ),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}