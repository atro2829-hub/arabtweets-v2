import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onFollowBack;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onFollowBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : colorScheme.primary.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: notification.typeIconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.typeIcon,
                  size: 16,
                  color: notification.typeIconColor,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (notification.fromUserId != null) {
                  context.push('/profile/${notification.fromUserId}');
                }
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: notification.fromFullAvatarUrl.isNotEmpty
                    ? NetworkImage(notification.fromFullAvatarUrl)
                    : null,
                child: notification.fromFullAvatarUrl.isEmpty
                    ? Text(
                        (notification.fromDisplayName?.isNotEmpty ?? false)
                            ? notification.fromDisplayName![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: notification.fromDisplayName ?? 'مستخدم',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (notification.fromUsername != null)
                          TextSpan(
                            text: ' @${notification.fromUsername}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        TextSpan(
                          text: ' · ${notification.actionText}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeAgo(notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  if (notification.tweetId != null &&
                      notification.type != NotificationType.follow &&
                      notification.type != NotificationType.message &&
                      notification.message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (notification.type == NotificationType.follow)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: _FollowBackButton(
                  fromUserId: notification.fromUserId,
                  onFollowBack: onFollowBack,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    switch (notification.type) {
      case NotificationType.follow:
        if (notification.fromUserId != null) {
          context.push('/profile/${notification.fromUserId}');
        }
        break;
      case NotificationType.message:
        context.push('/messages');
        break;
      case NotificationType.like:
      case NotificationType.retweet:
      case NotificationType.reply:
      case NotificationType.mention:
        if (notification.tweetId != null) {
          context.push('/tweet/${notification.tweetId}');
        }
        break;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return '${mins}د';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '${hours}س';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}أيام';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}أسابيع';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '${months}أشهر';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _FollowBackButton extends StatefulWidget {
  final String? fromUserId;
  final VoidCallback? onFollowBack;

  const _FollowBackButton({this.fromUserId, this.onFollowBack});

  @override
  State<_FollowBackButton> createState() => _FollowBackButtonState();
}

class _FollowBackButtonState extends State<_FollowBackButton> {
  bool _isFollowing = false;
  bool _isLoading = false;

  Future<void> _toggleFollow() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || widget.fromUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (!_isFollowing) {
        await Supabase.instance.client.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': widget.fromUserId,
        });
      } else {
        await Supabase.instance.client
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', widget.fromUserId!);
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      widget.onFollowBack?.call();
    } catch (_) {
      // Silently fail
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _toggleFollow,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              _isFollowing ? Colors.transparent : colorScheme.primary,
          foregroundColor:
              _isFollowing ? colorScheme.onSurface : colorScheme.onPrimary,
          side: _isFollowing
              ? BorderSide(color: theme.dividerColor, width: 1)
              : BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _isFollowing
                      ? colorScheme.onSurface
                      : colorScheme.onPrimary,
                ),
              )
            : Text(
                _isFollowing ? 'متابَع' : 'متابعة',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}