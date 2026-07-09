import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/data/models/user_model.dart';

class UserSearchCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onFollow;
  final VoidCallback? onTap;

  const UserSearchCard({
    super.key,
    required this.user,
    this.onFollow,
    this.onTap,
  });

  @override
  State<UserSearchCard> createState() => _UserSearchCardState();
}

class _UserSearchCardState extends State<UserSearchCard> {
  bool _isLoadingFollow = false;
  bool? _isFollowing;

  bool get _isOwnProfile {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return currentUserId != null && currentUserId == widget.user.id;
  }

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    if (_isOwnProfile) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('follows')
          .select()
          .eq('follower_id', currentUserId)
          .eq('following_id', widget.user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isFollowing = response != null;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleFollow() async {
    if (_isLoadingFollow || _isOwnProfile) return;

    setState(() => _isLoadingFollow = true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final result = await Supabase.instance.client.rpc(
        'toggle_follow',
        params: {
          'p_follower_id': currentUserId,
          'p_following_id': widget.user.id,
        },
      );

      if (mounted) {
        setState(() {
          _isFollowing = result as bool;
          _isLoadingFollow = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingFollow = false);
      }
    }
  }

  String _truncateBio(String bio, int maxLength) {
    if (bio.length <= maxLength) return bio;
    return '${bio.substring(0, maxLength)}...';
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = widget.user.fullAvatarUrl;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: widget.onTap,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        widget.user.displayName.isNotEmpty
                            ? widget.user.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.user.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.user.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: widget.user.verificationType == 'gold'
                              ? Colors.amber
                              : theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${widget.user.username}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.user.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _truncateBio(widget.user.bio, 60),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCount(widget.user.followersCount)} متابع',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Follow button
            if (!_isOwnProfile)
              SizedBox(
                height: 34,
                child: _isLoadingFollow
                    ? const SizedBox(
                        width: 34,
                        height: 34,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : FilledButton.tonal(
                        onPressed: _handleFollow,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: (_isFollowing == true)
                              ? theme.colorScheme.surfaceContainerHighest
                              : null,
                          foregroundColor: (_isFollowing == true)
                              ? theme.colorScheme.onSurface
                              : null,
                        ),
                        child: Text(
                          (_isFollowing == true) ? 'متابَع' : 'متابعة',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}