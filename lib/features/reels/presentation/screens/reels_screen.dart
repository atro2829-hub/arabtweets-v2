import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:adentweet/core/constants/api_constants.dart';
import 'package:adentweet/features/reels/data/models/reel_model.dart';
import 'package:adentweet/features/reels/presentation/providers/reels_provider.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _isPlaying = {};
  String? _currentReelId;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page?.round() ?? 0;
    final reelsState = ref.read(reelsProvider);
    if (page >= 0 && page < reelsState.reels.length) {
      final newReelId = reelsState.reels[page].id;
      if (newReelId != _currentReelId) {
        _pauseCurrentVideo();
        _currentReelId = newReelId;
        _playVideo(newReelId);

        // Preload next video
        if (page + 1 < reelsState.reels.length) {
          _preloadVideo(
              reelsState.reels[page + 1].id, reelsState.reels[page + 1].fullVideoUrl);
        }

        // Load more when nearing the end
        if (page >= reelsState.reels.length - 2 && reelsState.hasMore) {
          ref.read(reelsProvider.notifier).fetchMoreReels();
        }
      }
    }
  }

  void _preloadVideo(String reelId, String url) {
    if (url.isEmpty || _videoControllers.containsKey(reelId)) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoControllers[reelId] = controller;
    controller.initialize().catchError((_) {});
  }

  void _playVideo(String reelId) async {
    final controller = _videoControllers[reelId];
    if (controller == null) {
      final reelsState = ref.read(reelsProvider);
      final reel = reelsState.reels.where((r) => r.id == reelId).firstOrNull;
      if (reel == null || reel.fullVideoUrl.isEmpty) return;

      final newController =
          VideoPlayerController.networkUrl(Uri.parse(reel.fullVideoUrl));
      _videoControllers[reelId] = newController;

      try {
        await newController.initialize();
        if (mounted) {
          await newController.setLooping(true);
          await newController.play();
          setState(() {
            _isPlaying[reelId] = true;
          });
        }
      } catch (_) {
        // Video failed to load
      }
      return;
    }

    if (controller.value.isInitialized) {
      controller.setLooping(true);
      controller.play();
      setState(() {
        _isPlaying[reelId] = true;
      });
    }
  }

  void _pauseCurrentVideo() {
    if (_currentReelId != null) {
      final controller = _videoControllers[_currentReelId];
      if (controller != null && controller.value.isInitialized) {
        controller.pause();
        setState(() {
          _isPlaying[_currentReelId!] = false;
        });
      }
    }
  }

  void _togglePlayPause(String reelId) {
    final controller = _videoControllers[reelId];
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
      setState(() {
        _isPlaying[reelId] = false;
      });
    } else {
      controller.play();
      setState(() {
        _isPlaying[reelId] = true;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  Future<void> _onShare(ReelModel reel) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reel.caption.isNotEmpty ? reel.caption : 'شاهد هذا الريل!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _onToggleFollow(String targetUserId) async {
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

  void _showCommentsSheet(BuildContext context, ReelModel reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(reelId: reel.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reelsState = ref.watch(reelsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: _buildBody(reelsState),
      ),
    );
  }

  Widget _buildBody(ReelsState reelsState) {
    if (reelsState.isLoading && reelsState.reels.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (reelsState.error != null && reelsState.reels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء التحميل',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(reelsProvider.notifier).fetchReels(refresh: true),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (reelsState.reels.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد ريلز بعد',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: reelsState.reels.length + (reelsState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= reelsState.reels.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final reel = reelsState.reels[index];
        return _ReelPage(
          reel: reel,
          videoController: _videoControllers[reel.id],
          isPlaying: _isPlaying[reel.id] ?? false,
          onTogglePlayPause: () => _togglePlayPause(reel.id),
          onLike: () =>
              ref.read(toggleReelLikeProvider.notifier).toggleLike(reel.id),
          onComment: () => _showCommentsSheet(context, reel),
          onShare: () => _onShare(reel),
          onBookmark: () {},
          onFollow: () => _onToggleFollow(reel.userId),
          onProfileTap: () {},
        );
      },
    );
  }
}

class _ReelPage extends StatelessWidget {
  final ReelModel reel;
  final VideoPlayerController? videoController;
  final bool isPlaying;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;
  final VoidCallback onFollow;
  final VoidCallback onProfileTap;

  const _ReelPage({
    required this.reel,
    this.videoController,
    required this.isPlaying,
    required this.onTogglePlayPause,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
    required this.onFollow,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTogglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoPlayer(),

          if (!isPlaying && videoController?.value.isInitialized == true)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white, size: 64),
            ),

          if (videoController == null || !videoController!.value.isInitialized)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          Positioned(
            left: 0,
            right: 60,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAuthorInfo(),
                  if (reel.caption.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      reel.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          Positioned(
            right: 8,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatarButton(context),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(reel.likesCount),
                  color: reel.isLiked ? Colors.red : Colors.white,
                  onTap: onLike,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(reel.commentsCount),
                  color: Colors.white,
                  onTap: onComment,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.send_outlined,
                  label: _formatCount(reel.sharesCount),
                  color: Colors.white,
                  onTap: onShare,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.bookmark_border,
                  label: '',
                  color: Colors.white,
                  onTap: onBookmark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (videoController == null || !videoController!.value.isInitialized) {
      if (reel.thumbnailUrl != null && reel.thumbnailUrl!.isNotEmpty) {
        final thumbUrl = ApiConstants.getReelUrl(reel.thumbnailUrl);
        return CachedNetworkImage(
          imageUrl: thumbUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(color: Colors.black),
        );
      }
      return Container(color: Colors.black);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: videoController!.value.size.width,
          height: videoController!.value.size.height,
          child: VideoPlayer(videoController!),
        ),
      ),
    );
  }

  Widget _buildAvatarButton(BuildContext context) {
    final author = reel.author;
    final avatarUrl = author?.fullAvatarUrl ??? '';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnReel = author?.id == currentUserId;

    return Column(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        (author?.displayName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              if (!isOwnReel)
                Positioned(
                  bottom: -6,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onFollow,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child:
                          const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (author?.isVerified == true)
          const Icon(Icons.verified, color: Colors.blue, size: 16),
      ],
    );
  }

  Widget _buildAuthorInfo() {
    final author = reel.author;
    final displayName = author?.displayName ??? '';
    final username = author?.username ??? '';

    return GestureDetector(
      onTap: onProfileTap,
      child: Row(
        children: [
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (author?.isVerified == true) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
          const SizedBox(width: 6),
          Text(
            '@$username',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ],
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

class _CommentsSheet extends ConsumerStatefulWidget {
  final String reelId;

  const _CommentsSheet({required this.reelId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _commentController.clear();

    try {
      await Supabase.instance.client.from('reel_comments').insert({
        'reel_id': widget.reelId,
        'user_id': userId,
        'content': content,
      });

      ref.invalidate(reelCommentsProvider(widget.reelId));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(reelCommentsProvider(widget.reelId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'التعليقات',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد تعليقات بعد',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _CommentItem(comment: comment);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (error, _) => Center(
                child: const Text(
                  'حدث خطأ',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'أضف تعليقاً...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              textDirection: TextDirection.rtl,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _submitComment,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final ReelComment comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiConstants.getAvatarUrl(comment.avatarUrl);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade800,
          backgroundImage:
              avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? Text(
                  comment.displayName.isNotEmpty
                      ? comment.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (comment.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 14),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    '@${comment.username}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.content,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}