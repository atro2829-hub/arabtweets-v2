import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../data/models/notification_model.dart';

final _client = () => Supabase.instance.client;

final _currentUserIdProvider = Provider<String?>((ref) {
  return _client().auth.currentUser?.id;
});

/// Provider for fetching user notifications with pagination
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  bool _hasMore = true;
  RealtimeChannel? _channel;

  @override
  Future<List<NotificationModel>> build() async {
    final userId = _currentUserIdProvider.read(ref);
    if (userId == null) return [];

    _hasMore = true;

    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    _setupRealtime(userId);

    return _fetchNotifications(userId);
  }

  Future<List<NotificationModel>> _fetchNotifications(
    String userId, {
    int offset = 0,
  }) async {
    final response = await _client().rpc('get_user_notifications', params: {
      'user_id': userId,
      'limit': ApiConstants.notificationsPageSize,
      'offset': offset,
    });

    final List<NotificationModel> notifications = [];
    for (final item in response as List) {
      notifications
          .add(NotificationModel.fromJson(item as Map<String, dynamic>));
    }

    if (notifications.length < ApiConstants.notificationsPageSize) {
      _hasMore = false;
    }

    return notifications;
  }

  void _setupRealtime(String userId) {
    _channel?.unsubscribe();

    _channel = _client()
        .channel('user_notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newNotifData = payload.new as Map<String, dynamic>?;
            if (newNotifData == null) return;

            // Fetch full notification with profile data
            _fetchFullNotification(newNotifData['id'] as String);
          },
        )
        .subscribe();
  }

  Future<void> _fetchFullNotification(String notificationId) async {
    try {
      final userId = _currentUserIdProvider.read(ref);
      if (userId == null) return;

      final response = await _client().rpc('get_user_notifications', params: {
        'user_id': userId,
        'limit': 1,
        'offset': 0,
      });

      // Since the RPC doesn't filter by ID, we need to get it from the current list
      // Instead, let's rebuild the list to pick up the new notification
      await refresh();
    } catch (_) {
      // Silently fail, user can pull to refresh
    }
  }

  Future<void> refresh() async {
    final userId = _currentUserIdProvider.read(ref);
    if (userId == null) return;

    state = const AsyncLoading();
    _hasMore = true;
    state = AsyncData(await _fetchNotifications(userId));
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;

    final current = state.valueOrNull ?? [];
    final userId = _currentUserIdProvider.read(ref);
    if (userId == null) return;

    final olderNotifications =
        await _fetchNotifications(userId, offset: current.length);

    if (olderNotifications.isEmpty) {
      _hasMore = false;
      return;
    }

    state = AsyncData([...current, ...olderNotifications]);
  }

  /// Get only mention-type notifications (reply + mention)
  List<NotificationModel> getMentions(List<NotificationModel> all) {
    return all
        .where((n) =>
            n.type == NotificationType.reply ||
            n.type == NotificationType.mention)
        .toList();
  }
}

/// Provider for unread notifications count as a stream
final unreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final userId = _currentUserIdProvider.read(ref);
  if (userId == null) return Stream.value(0);

  final controller = StreamController<int>.broadcast();

  Future<void> fetchCount() async {
    try {
      final result = await _client()
          .rpc('get_unread_notifications_count', params: {'user_id': userId});
      controller.add(result as int? ?? 0);
    } catch (_) {
      controller.add(0);
    }
  }

  fetchCount();

  // Refresh every 10 seconds for real-time feel
  final timer = Timer.periodic(const Duration(seconds: 10), (_) {
    fetchCount();
  });

  // Also set up realtime subscription for instant updates
  final channel = _client()
      .channel('unread_notifs_count_$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) {
          fetchCount();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) {
          fetchCount();
        },
      )
      .subscribe();

  ref.onDispose(() {
    timer.cancel();
    controller.close();
    channel.unsubscribe();
  });

  return controller.stream;
});

/// Provider for marking all notifications as read
final markAllReadProvider =
    AsyncNotifierProvider<MarkAllReadNotifier, void>(MarkAllReadNotifier.new);

class MarkAllReadNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No-op on build
  }

  Future<void> markAllRead() async {
    final userId = _currentUserIdProvider.read(ref);
    if (userId == null) return;

    state = const AsyncLoading();

    try {
      await _client()
          .rpc('mark_notifications_read', params: {'user_id': userId});

      // Refresh notifications list
      ref.read(notificationsProvider.notifier).refresh();

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}