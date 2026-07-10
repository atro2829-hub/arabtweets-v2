import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/tweet_model.dart';
import '../providers/tweets_provider.dart';
import '../widgets/compose_tweet_sheet.dart';
import '../widgets/media_grid.dart';
import '../widgets/tweet_card.dart';

class TweetDetailScreen extends ConsumerStatefulWidget {
  final String tweetId;

  const TweetDetailScreen({
    super.key,
    required this.tweetId,
  });

  @override
  ConsumerState<TweetDetailScreen> createState() => _TweetDetailScreenState();
}

class _TweetDetailScreenState extends ConsumerState<TweetDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  bool _showReplyInput = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(tweetDetailProvider(widget.tweetId).notifier).loadMoreReplies();
    }
  }

  void _onReply() async {
    final detailAsync =
        ref.read(tweetDetailProvider(widget.tweetId));

    final tweet = detailAsync.valueOrNull?.tweet;
    if (tweet == null) return;

    final reply = await ComposeTweetSheet.show(
      context,
      replyToId: tweet.id,
      replyToUserId: tweet.userId,
      replyToUsername: tweet.authorUsername,
    );

    if (reply != null && mounted) {
      ref.read(tweetDetailProvider(widget.tweetId).notifier).addReply(reply);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final detailAsync = ref.watch(tweetDetailProvider(widget.tweetId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('التغريدة'),
        centerTitle: false,
      ),
      body: detailAsync.when(
        loading: () => _buildLoadingState(context),
        error: (error, _) => _buildErrorState(context, error.toString()),
        data: (detailState) => _buildContent(context, detailState),
      ),
      bottomNavigationBar: detailAsync.valueOrNull?.tweet != null
          ? _buildReplyBar(context, detailAsync.valueOrNull!.tweet!)
          : null,
    );
  }

  Widget _buildContent(BuildContext context, TweetDetailState detailState) {
    final tweet = detailState.tweet;

    if (tweet == null) {
      return _buildErrorState(context, 'لم يتم العثور على التغريدة');
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tweetDetailProvider(widget.tweetId));
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Main tweet
          SliverToBoxAdapter(
            child: _MainTweetCard(tweet: tweet),
          ),

          // Stats bar
          SliverToBoxAdapter(
            child: _StatsBar(tweet: tweet),
          ),

          // Action buttons (full width)
          SliverToBoxAdapter(
            child: _DetailActionBar(tweet: tweet),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Divider(
              height: 1,
              thickness: 8,
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.1),
            ),
          ),

          // Replies header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '${tweet.repliesCount} رد',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),

          // Replies list
          if (detailState.replies.isEmpty)
            SliverFillRemaining(
              child: _buildNoReplies(context),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= detailState.replies.length) {
                    return const TweetCardShimmer();
                  }
                  return TweetCard(
                    tweet: detailState.replies[index],
                    onReply: () {
                      final replyTweet = detailState.replies[index];
                      ComposeTweetSheet.show(
                        context,
                        replyToId: replyTweet.id,
                        replyToUserId: replyTweet.userId,
                        replyToUsername: replyTweet.authorUsername,
                      );
                    },
                  );
                },
                childCount: detailState.replies.length +
                    (detailState.isLoadingMoreReplies ? 3 : 0),
              ),
            ),

          // Bottom padding for reply bar
          const SliverPadding(padding: EdgeInsets.only(bottom: 64)),
        ],
      ),
    );
  }

  Widget _buildReplyBar(BuildContext context, TweetModel tweet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final avatarUrl = currentUser?.userMetadata?['avatar_url'] as String?;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(ApiConstants.getAvatarUrl(avatarUrl))
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Icon(
                    Icons.person,
                    color: colorScheme.outline,
                    size: 14,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Reply input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _replyController,
                focusNode: _replyFocusNode,
                maxLines: null,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'اكتب ردك...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                  suffixIcon: _replyController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.send, size: 20),
                          onPressed: () {
                            // Quick reply
                            _onReply();
                            _replyController.clear();
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
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
              'حدث خطأ',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
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
                ref.invalidate(tweetDetailProvider(widget.tweetId));
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

  Widget _buildNoReplies(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'كن أول من يرد على هذه التغريدة',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main Tweet Card (full size for detail) ──────────────────────────────────

class _MainTweetCard extends ConsumerWidget {
  final TweetModel tweet;

  const _MainTweetCard({required this.tweet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLikedAsync = ref.watch(toggleLikeProvider(tweet.id));
    final isRetweetedAsync = ref.watch(toggleRetweetProvider(tweet.id));
    final isBookmarkedAsync = ref.watch(toggleBookmarkProvider(tweet.id));

    final isLiked = isLikedAsync.valueOrNull ?? tweet.isLiked;
    final isRetweeted = isRetweetedAsync.valueOrNull ?? tweet.isRetweeted;
    final isBookmarked = isBookmarkedAsync.valueOrNull ?? tweet.isBookmarked;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/profile/${tweet.authorUsername}'),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: tweet.authorFullAvatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(tweet.authorFullAvatarUrl)
                      : null,
                  child: tweet.authorFullAvatarUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: colorScheme.outline,
                          size: 22,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              context.push('/profile/${tweet.authorUsername}'),
                          child: Text(
                            tweet.authorDisplayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tweet.authorIsVerified) ...[
                          const SizedBox(width: 4),
                          SvgPicture.asset(
                            tweet.authorVerificationType == 'gold'
                                ? 'assets/icons/svg/verified_gold.svg'
                                : 'assets/icons/svg/verified.svg',
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ],
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.push('/profile/${tweet.authorUsername}'),
                      child: Text(
                        '@${tweet.authorUsername}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // More
              GestureDetector(
                onTap: () => _showMoreOptions(context),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.more_horiz,
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reply to indicator
          if (tweet.isReply)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    'الرد على تغريدة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  Text(
                    '@${tweet.replyToUserId ?? ""}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Text(
            tweet.content,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              fontSize: 17,
            ),
          ),

          // Media
          if (tweet.hasMedia)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: MediaGrid(
                mediaUrls: tweet.fullMediaUrls,
                mediaType: tweet.mediaType,
                isGif: tweet.isGif,
              ),
            ),

          // Time
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _formatFullDate(tweet.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '${hours}:${minutes} · ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('نسخ رابط التغريدة'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: 'tweet/${tweet.id}'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off_outlined),
              title: const Text('كتم الحساب'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Bar ───────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final TweetModel tweet;

  const _StatsBar({required this.tweet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatItem(count: tweet.retweetsCount, label: 'إعادة نشر'),
          Container(
            width: 1,
            height: 24,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          _StatItem(count: tweet.likesCount, label: 'إعجاب'),
          Container(
            width: 1,
            height: 24,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          _StatItem(count: tweet.bookmarksCount, label: 'مفضلة'),
          Container(
            width: 1,
            height: 24,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          _StatItem(count: tweet.viewsCount, label: 'مشاهدة'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          _formatCount(count),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// ─── Detail Action Bar ───────────────────────────────────────────────────────

class _DetailActionBar extends ConsumerWidget {
  final TweetModel tweet;

  const _DetailActionBar({required this.tweet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Reply
          Expanded(
            child: _DetailActionButton(
              icon: SvgPicture.asset(
                'assets/icons/svg/comment.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  colorScheme.outline,
                  BlendMode.srcIn,
                ),
              ),
              label: _formatCount(tweet.repliesCount),
              onTap: () {
                ComposeTweetSheet.show(
                  context,
                  replyToId: tweet.id,
                  replyToUserId: tweet.userId,
                  replyToUsername: tweet.authorUsername,
                );
              },
            ),
          ),
          // Retweet
          Expanded(
            child: Consumer(builder: (context, ref, _) {
              final isRetweetedAsync = ref.watch(toggleRetweetProvider(tweet.id));
              final isRetweeted = isRetweetedAsync.valueOrNull ?? tweet.isRetweeted;

              return _DetailActionButton(
                icon: SvgPicture.asset(
                  'assets/icons/svg/retweet.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    isRetweeted ? Colors.green : colorScheme.outline,
                    BlendMode.srcIn,
                  ),
                ),
                label: _formatCount(
                  isRetweeted
                      ? tweet.retweetsCount + 1
                      : tweet.retweetsCount,
                ),
                isActive: isRetweeted,
                activeColor: Colors.green,
                onTap: () {
                  ref
                      .read(toggleRetweetProvider(tweet.id).notifier)
                      .toggleRetweet(tweet.id);
                },
              );
            }),
          ),
          // Like
          Expanded(
            child: Consumer(builder: (context, ref, _) {
              final isLikedAsync = ref.watch(toggleLikeProvider(tweet.id));
              final isLiked = isLikedAsync.valueOrNull ?? tweet.isLiked;

              return _DetailActionButton(
                icon: isLiked
                    ? SvgPicture.asset(
                        'assets/icons/svg/heart_filled.svg',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          Colors.redAccent,
                          BlendMode.srcIn,
                        ),
                      )
                    : SvgPicture.asset(
                        'assets/icons/svg/heart.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          colorScheme.outline,
                          BlendMode.srcIn,
                        ),
                      ),
                label: _formatCount(
                  isLiked ? tweet.likesCount + 1 : tweet.likesCount,
                ),
                isActive: isLiked,
                activeColor: Colors.redAccent,
                onTap: () {
                  ref
                      .read(toggleLikeProvider(tweet.id).notifier)
                      .toggleLike(tweet.id);
                },
              );
            }),
          ),
          // Bookmark
          Expanded(
            child: Consumer(builder: (context, ref, _) {
              final isBookmarkedAsync = ref.watch(toggleBookmarkProvider(tweet.id));
              final isBookmarked = isBookmarkedAsync.valueOrNull ?? tweet.isBookmarked;

              return _DetailActionButton(
                icon: isBookmarked
                    ? SvgPicture.asset(
                        'assets/icons/svg/bookmark_filled.svg',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          Colors.blueAccent,
                          BlendMode.srcIn,
                        ),
                      )
                    : SvgPicture.asset(
                        'assets/icons/svg/bookmark.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          colorScheme.outline,
                          BlendMode.srcIn,
                        ),
                      ),
                label: '',
                isActive: isBookmarked,
                activeColor: Colors.blueAccent,
                onTap: () {
                  ref
                      .read(toggleBookmarkProvider(tweet.id).notifier)
                      .toggleBookmark(tweet.id);
                },
              );
            }),
          ),
          // Share
          Expanded(
            child: _DetailActionButton(
              icon: SvgPicture.asset(
                'assets/icons/svg/share.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  colorScheme.outline,
                  BlendMode.srcIn,
                ),
              ),
              label: '',
              onTap: () {
                Clipboard.setData(
                  ClipboardData(
                    text: '${ApiConstants.supabaseUrl}/tweet/${tweet.id}',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ رابط التغريدة'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _DetailActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _DetailActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 4),
            if (label.isNotEmpty)
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive ? activeColor : null,
                  fontWeight: isActive ? FontWeight.w600 : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}