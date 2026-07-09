import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../tweets/data/models/tweet_model.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(userProfileProvider(widget.username));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final profileAsync = ref.read(userProfileProvider(widget.username));
    if (profileAsync.hasValue) {
      final profileId = profileAsync.value!.id;
      ref.invalidate(userTweetsProvider(profileId));
      ref.invalidate(userRepliesProvider(profileId));
      ref.invalidate(userLikesProvider(profileId));
      ref.invalidate(userMediaProvider(profileId));
    }
    _refreshController.refreshCompleted();
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              );
            },
            itemCount: 1,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final profileAsync = ref.watch(userProfileProvider(widget.username));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: profileAsync.when(
          loading: () => _buildShimmerLoading(),
          error: (error, stack) => _buildErrorState(error.toString()),
          data: (profile) => _buildProfileContent(profile, currentUserId),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 150, color: Colors.white),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 200,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 250,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _shimmerBox(80, 16),
                          const SizedBox(width: 24),
                          _shimmerBox(80, 16),
                          const SizedBox(width: 24),
                          _shimmerBox(80, 16),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 48, color: Colors.white),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildShimmerTweet(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildShimmerTweet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(120, 16),
                  const SizedBox(height: 4),
                  _shimmerBox(80, 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _shimmerBox(double.infinity, 16),
          const SizedBox(height: 8),
          _shimmerBox(200, 16),
          const SizedBox(height: 12),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _shimmerBox(60, 14),
              const SizedBox(width: 32),
              _shimmerBox(60, 14),
              const SizedBox(width: 32),
              _shimmerBox(60, 14),
            ],
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error.contains('غير موجود') ? 'المستخدم غير موجود' : 'حدث خطأ',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider(widget.username)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(UserModel profile, String? currentUserId) {
    final isOwnProfile = currentUserId == profile.id;
    final isFollowingAsync = ref.watch(isFollowingProvider(profile.id));
    final toggleFollow = ref.read(toggleFollowProvider.notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                profile.displayName.isNotEmpty ? profile.displayName : '@${profile.username}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                if (isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/edit-profile', arguments: profile);
                    },
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'block') {
                        toastification.show(
                          context: context,
                          type: ToastificationType.info,
                          title: const Text('تم حظر المستخدم'),
                          autoCloseDuration: const Duration(seconds: 2),
                        );
                      } else if (value == 'report') {
                        toastification.show(
                          context: context,
                          type: ToastificationType.info,
                          title: const Text('تم الإبلاغ عن المستخدم'),
                          autoCloseDuration: const Duration(seconds: 2),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'block', child: Text('حظر')),
                      const PopupMenuItem(value: 'report', child: Text('إبلاغ')),
                    ],
                  ),
              ],
            ),

            // Cover image
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: profile.fullCoverUrl.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              if (profile.fullCoverUrl.isNotEmpty) {
                                _openFullScreenImage(profile.fullCoverUrl);
                              }
                            },
                            child: CachedNetworkImage(
                              imageUrl: profile.fullCoverUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                              placeholder: (context, url) => Container(
                                height: 150,
                                color: Colors.grey.shade200,
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 150,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 48, color: Colors.grey),
                              ),
                            ),
                          )
                        : Container(
                            height: 150,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image, size: 48, color: Colors.grey),
                            ),
                          ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: -40,
                    child: GestureDetector(
                      onTap: () {
                        if (profile.fullAvatarUrl.isNotEmpty) {
                          _openFullScreenImage(profile.fullAvatarUrl);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 4,
                          ),
                        ),
                        child: profile.fullAvatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: profile.fullAvatarUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                imageBuilder: (context, imageProvider) =>
                                    CircleAvatar(
                                  radius: 40,
                                  backgroundImage: imageProvider,
                                ),
                                placeholder: (context, url) => const CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey,
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => const CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person, size: 40, color: Colors.white),
                                ),
                              )
                            : const CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, size: 40, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isOwnProfile)
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/edit-profile', arguments: profile);
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            ),
                            child: const Text('تعديل الملف الشخصي'),
                          )
                        else
                          isFollowingAsync.when(
                            data: (isFollowing) => SizedBox(
                              width: 120,
                              child: toggleFollow.state.isLoading
                                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                                  : isFollowing
                                      ? OutlinedButton(
                                          onPressed: () => toggleFollow.toggleFollow(
                                            followerId: currentUserId!,
                                            followingId: profile.id,
                                            currentFollowing: true,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            side: const BorderSide(color: Colors.grey),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          child: const Text('متابَع'),
                                        )
                                      : FilledButton(
                                          onPressed: () => toggleFollow.toggleFollow(
                                            followerId: currentUserId!,
                                            followingId: profile.id,
                                            currentFollowing: false,
                                          ),
                                          style: FilledButton.styleFrom(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                          ),
                                          child: const Text('متابعة'),
                                        ),
                            ),
                            loading: () => const SizedBox(width: 120, height: 36, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Display name with verified badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (profile.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            profile.verificationType == 'gold'
                                ? Icons.verified
                                : Icons.check_circle,
                            color: profile.verificationType == 'gold'
                                ? Colors.amber
                                : Colors.blue,
                            size: 20,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      '@${profile.username}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                    ),

                    // Bio
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        profile.bio,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Location, website, join date
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (profile.location.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(profile.location, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            ],
                          ),
                        if (profile.website.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(profile.website, style: TextStyle(color: Colors.blue, fontSize: 14)),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.formatJoinDate(DateTime.now()),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        _buildStatItem(
                          label: 'متابَعين',
                          count: profile.followingCount,
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _buildStatItem(
                          label: 'متابِعون',
                          count: profile.followersCount,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProfileTabDelegate(
                tabController: _tabController,
              ),
            ),

            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTweetsTab(profile.id),
                  _buildRepliesTab(profile.id),
                  _buildLikesTab(profile.id),
                  _buildMediaTab(profile.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required int count, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            Formatters.formatArabicCount(count),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildTweetsTab(String userId) {
    final tweetsAsync = ref.watch(userTweetsProvider(userId));

    return tweetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ في تحميل التغريدات')),
      data: (tweets) {
        if (tweets.isEmpty) {
          return _buildEmptyState('لا توجد تغريدات بعد', 'عند نشر تغريدة ستظهر هنا');
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: tweets.length,
          itemBuilder: (context, index) => _buildTweetCard(tweets[index]),
        );
      },
    );
  }

  Widget _buildRepliesTab(String userId) {
    final repliesAsync = ref.watch(userRepliesProvider(userId));

    return repliesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ في تحميل الردود')),
      data: (replies) {
        if (replies.isEmpty) {
          return _buildEmptyState('لا توجد ردود بعد', 'الردود على تغريدات المستخدمين ستظهر هنا');
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: replies.length,
          itemBuilder: (context, index) => _buildTweetCard(replies[index]),
        );
      },
    );
  }

  Widget _buildLikesTab(String userId) {
    final likesAsync = ref.watch(userLikesProvider(userId));

    return likesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ في تحميل الإعجابات')),
      data: (tweets) {
        if (tweets.isEmpty) {
          return _buildEmptyState('لا توجد إعجابات بعد', 'عند الإعجاب بتغريدة ستظهر هنا');
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: tweets.length,
          itemBuilder: (context, index) => _buildTweetCard(tweets[index]),
        );
      },
    );
  }

  Widget _buildMediaTab(String userId) {
    final mediaAsync = ref.watch(userMediaProvider(userId));

    return mediaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ في تحميل الوسائط')),
      data: (tweets) {
        if (tweets.isEmpty) {
          return _buildEmptyState('لا توجد وسائط بعد', 'التغريدات التي تحتوي على صور أو فيديو ستظهر هنا');
        }
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: tweets.expand((t) => t.fullMediaUrls).length,
          itemBuilder: (context, index) {
            final allUrls = tweets.expand((t) => t.fullMediaUrls).toList();
            final url = allUrls[index];
            return GestureDetector(
              onTap: () => _openFullScreenImage(url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTweetCard(TweetModel tweet) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                tweet.fullAvatarUrl.isNotEmpty
                    ? CircleAvatar(
                        radius: 22,
                        backgroundImage: CachedNetworkImageProvider(tweet.fullAvatarUrl),
                      )
                    : const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tweet.displayName ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tweet.isVerified == true) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle, size: 16, color: Colors.blue),
                          ],
                          const SizedBox(width: 4),
                          Text(
                            '@${tweet.username ?? ''}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '· ${Formatters.timeAgo(tweet.createdAt)}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Content text
                      Text(
                        tweet.content,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                      // Media
                      if (tweet.fullMediaUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: tweet.fullMediaUrls.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 180,
                              color: Colors.grey.shade200,
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 180,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                      // Action row
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.comment_outlined,
                            count: tweet.repliesCount,
                            onTap: () {},
                          ),
                          const SizedBox(width: 32),
                          _buildActionButton(
                            icon: Icons.repeat,
                            count: tweet.retweetsCount,
                            onTap: () {},
                            isActive: tweet.isRetweeted,
                          ),
                          const SizedBox(width: 32),
                          _buildActionButton(
                            icon: tweet.isLiked ? Icons.favorite : Icons.favorite_border,
                            count: tweet.likesCount,
                            onTap: () {},
                            isActive: tweet.isLiked,
                            activeColor: Colors.red,
                          ),
                          const SizedBox(width: 32),
                          _buildActionButton(
                            icon: Icons.bar_chart,
                            count: tweet.viewsCount,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 60),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    final color = isActive ? (activeColor ?? Theme.of(context).primaryColor) : Colors.grey.shade500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                Formatters.formatArabicCount(count),
                style: TextStyle(color: color, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _ProfileTabDelegate({required this.tabController});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorColor: Colors.black,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'تغريدات'),
          Tab(text: 'ردود'),
          Tab(text: 'إعجابات'),
          Tab(text: 'وسائط'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileTabDelegate oldDelegate) {
    return tabController != oldDelegate.tabController;
  }
}