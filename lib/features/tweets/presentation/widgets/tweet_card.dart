import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/tweet_model.dart';
import '../providers/tweets_provider.dart';
import 'media_grid.dart';

class TweetCard extends ConsumerStatefulWidget {
  final TweetModel tweet;
  final bool showRetweetHeader;
  final VoidCallback? onReply;
  final VoidCallback? onTweetUpdated;

  const TweetCard({
    super.key,
    required this.tweet,
    this.showRetweetHeader = false,
    this.onReply,
    this.onTweetUpdated,
  });

  @override
  ConsumerState<TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends ConsumerState<TweetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _likeScaleAnimation;

  bool _isAnimatingLike = false;
  bool _isAnimatingRetweet = false;
  bool _isAnimatingBookmark = false;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _onLikeTap() {
    final notifier = ref.read(toggleLikeProvider(widget.tweet.id).notifier);
    notifier.toggleLike(widget.tweet.id);

    if (!_isAnimatingLike) {
      _isAnimatingLike = true;
      if (!widget.tweet.isLiked) {
        HapticFeedback.lightImpact();
        _likeController.forward().then((_) {
          _likeController.reverse().then((_) {
            _isAnimatingLike = false;
          });
        });
      } else {
        _isAnimatingLike = false;
      }
    }

    widget.onTweetUpdated?.call();
  }

  void _onRetweetTap() {
    final notifier =
        ref.read(toggleRetweetProvider(widget.tweet.id).notifier);
    notifier.toggleRetweet(widget.tweet.id);

    if (!_isAnimatingRetweet) {
      _isAnimatingRetweet = true;
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 300), () {
        _isAnimatingRetweet = false;
      });
    }

    widget.onTweetUpdated?.call();
  }

  void _onBookmarkTap() {
    final notifier =
        ref.read(toggleBookmarkProvider(widget.tweet.id).notifier);
    notifier.toggleBookmark(widget.tweet.id);

    if (!_isAnimatingBookmark) {
      _isAnimatingBookmark = true;
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 300), () {
        _isAnimatingBookmark = false;
      });
    }

    widget.onTweetUpdated?.call();
  }

  void _onShareTap() {
    final url = '${ApiConstants.supabaseUrl}/tweet/${widget.tweet.id}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ رابط التغريدة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToDetail() {
    context.push('/tweet/${widget.tweet.id}');
  }

  void _navigateToProfile(String username) {
    context.push('/profile/$username');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: _navigateToDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reposted by header
          if (widget.showRetweetHeader && widget.tweet.retweetedByUsername != null)
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 4, top: 8),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/svg/retweet.svg',
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(
                      colorScheme.outline,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'أعد نشر ${widget.tweet.retweetedByUsername!}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Reply to header
          if (widget.tweet.replyToUsername != null)
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 2),
              child: Row(
                children: [
                  Text(
                    'الرد على ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  Text(
                    '@${widget.tweet.replyToUsername}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => _navigateToProfile(widget.tweet.authorUsername),
                  child: _TweetAvatar(
                    avatarUrl: widget.tweet.authorFullAvatarUrl,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row
                      _AuthorRow(tweet: widget.tweet),
                      const SizedBox(height: 2),
                      // Tweet text
                      _TweetText(content: widget.tweet.content),
                      // Media
                      if (widget.tweet.hasMedia)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: MediaGrid(
                            mediaUrls: widget.tweet.fullMediaUrls,
                            mediaType: widget.tweet.mediaType,
                            isGif: widget.tweet.isGif,
                          ),
                        ),
                      // Action bar
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 16),
                        child: _ActionBar(
                          tweet: widget.tweet,
                          likeScaleAnimation: _likeScaleAnimation,
                          onReply: () {
                            widget.onReply?.call();
                          },
                          onRetweet: _onRetweetTap,
                          onLike: _onLikeTap,
                          onBookmark: _onBookmarkTap,
                          onShare: _onShareTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

class _TweetAvatar extends StatelessWidget {
  final String avatarUrl;

  const _TweetAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: ClipOval(
        child: avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (context, _) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.outline,
                    size: 20,
                  ),
                ),
                errorWidget: (context, _, __) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.outline,
                    size: 20,
                  ),
                ),
              )
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.outline,
                  size: 20,
                ),
              ),
      ),
    );
  }
}

// ─── Author Row ──────────────────────────────────────────────────────────────

class _AuthorRow extends ConsumerWidget {
  final TweetModel tweet;

  const _AuthorRow({required this.tweet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Display name
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: () => context.push('/profile/${tweet.authorUsername}'),
                  child: Text(
                    tweet.authorDisplayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (tweet.authorIsVerified) ...[
                const SizedBox(width: 4),
                SvgPicture.asset(
                  tweet.authorVerificationType == 'gold'
                      ? 'assets/icons/svg/verified_gold.svg'
                      : 'assets/icons/svg/verified.svg',
                  width: 18,
                  height: 18,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 4),
        // Username
        Flexible(
          child: GestureDetector(
            onTap: () => context.push('/profile/${tweet.authorUsername}'),
            child: Text(
              '@${tweet.authorUsername}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Time
        Text(
          '· ${_formatTime(tweet.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        const SizedBox(width: 4),
        // More button
        GestureDetector(
          onTap: () => _showMoreOptions(context),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.more_horiz,
              size: 18,
              color: colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) return 'الآن';
    return timeago.format(createdAt, locale: 'ar');
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
                Clipboard.setData(
                  ClipboardData(text: 'tweet/${tweet.id}'),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mute_outlined),
              title: const Text('كتم الحساب'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tweet Text ──────────────────────────────────────────────────────────────

class _TweetText extends StatelessWidget {
  final String content;

  const _TweetText({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.4,
          fontSize: 15,
        ),
        children: _buildSpans(content, colorScheme, context),
      ),
    );
  }

  List<InlineSpan> _buildSpans(
    String text,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(#\S+|@\S+)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final matched = match.group(0)!;
      if (matched.startsWith('#')) {
        spans.add(
          TextSpan(
            text: matched,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else if (matched.startsWith('@')) {
        spans.add(
          TextSpan(
            text: matched,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }
}

// ─── Action Bar ──────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  final TweetModel tweet;
  final Animation<double> likeScaleAnimation;
  final VoidCallback onReply;
  final VoidCallback onRetweet;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onShare;

  const _ActionBar({
    required this.tweet,
    required this.likeScaleAnimation,
    required this.onReply,
    required this.onRetweet,
    required this.onLike,
    required this.onBookmark,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLikedAsync = ref.watch(toggleLikeProvider(tweet.id));
    final isRetweetedAsync = ref.watch(toggleRetweetProvider(tweet.id));
    final isBookmarkedAsync = ref.watch(toggleBookmarkProvider(tweet.id));

    final isLiked = isLikedAsync.valueOrNull ?? tweet.isLiked;
    final isRetweeted = isRetweetedAsync.valueOrNull ?? tweet.isRetweeted;
    final isBookmarked = isBookmarkedAsync.valueOrNull ?? tweet.isBookmarked;

    final likesCount = isLiked
        ? tweet.likesCount + (isLiked != tweet.isLiked ? 1 : 0)
        : (isLiked != tweet.isLiked ? tweet.likesCount - 1 : tweet.likesCount);
    final retweetsCount = isRetweeted
        ? tweet.retweetsCount + (isRetweeted != tweet.isRetweeted ? 1 : 0)
        : (isRetweeted != tweet.isRetweeted
            ? tweet.retweetsCount - 1
            : tweet.retweetsCount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reply
        _ActionButton(
          icon: SvgPicture.asset(
            'assets/icons/svg/comment.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.outline,
              BlendMode.srcIn,
            ),
          ),
          count: tweet.repliesCount,
          activeColor: Theme.of(context).colorScheme.outline,
          onTap: onReply,
        ),
        // Retweet
        _ActionButton(
          icon: SvgPicture.asset(
            'assets/icons/svg/retweet.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              isRetweeted ? Colors.green : Theme.of(context).colorScheme.outline,
              BlendMode.srcIn,
            ),
          ),
          count: retweetsCount < 0 ? 0 : retweetsCount,
          activeColor: Colors.green,
          isActive: isRetweeted,
          onTap: onRetweet,
        ),
        // Like
        GestureDetector(
          onTap: onLike,
          child: Row(
            children: [
              AnimatedBuilder(
                animation: likeScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: likeScaleAnimation.value,
                    child: child,
                  );
                },
                child: isLiked
                    ? SvgPicture.asset(
                        'assets/icons/svg/heart_filled.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          Colors.redAccent,
                          BlendMode.srcIn,
                        ),
                      )
                    : SvgPicture.asset(
                        'assets/icons/svg/heart.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.outline,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
              if (likesCount > 0) ...[
                const SizedBox(width: 4),
                Text(
                  _formatCount(likesCount < 0 ? 0 : likesCount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLiked ? Colors.redAccent : null,
                        fontWeight: isLiked ? FontWeight.w600 : null,
                      ),
                ),
              ],
            ],
          ),
        ),
        // Bookmark
        _ActionButton(
          icon: isBookmarked
              ? SvgPicture.asset(
                  'assets/icons/svg/bookmark_filled.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.blueAccent,
                    BlendMode.srcIn,
                  ),
                )
              : SvgPicture.asset(
                  'assets/icons/svg/bookmark.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.outline,
                    BlendMode.srcIn,
                  ),
                ),
          count: tweet.bookmarksCount,
          activeColor: Colors.blueAccent,
          isActive: isBookmarked,
          onTap: onBookmark,
        ),
        // Share
        GestureDetector(
          onTap: onShare,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: SvgPicture.asset(
              'assets/icons/svg/share.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.outline,
                BlendMode.srcIn,
              ),
            ),
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

// ─── Action Button ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final int count;
  final Color activeColor;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.count,
    required this.activeColor,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: icon,
          ),
          if (count > 0)
            Text(
              _formatCount(count),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isActive ? activeColor : null,
                    fontWeight: isActive ? FontWeight.w600 : null,
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

// ─── Animated Builder ────────────────────────────────────────────────────────

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

// ─── Tweet Card Shimmer ──────────────────────────────────────────────────────

class TweetCardShimmer extends StatelessWidget {
  const TweetCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor =
        Theme.of(context).colorScheme.surfaceContainerHigh;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar shimmer
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                const SizedBox(width: 12),
                // Content shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row
                      Row(
                        children: [
                          Container(
                            width: 100,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Text lines
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (index) => Container(
                            width: 50,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}