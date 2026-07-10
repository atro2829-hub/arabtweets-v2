import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'الإشعارات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _handleMarkAllRead,
            child: Text(
              'قراءة الكل',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.outline,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'مذكورات'),
          ],
        ),
      ),
      body: notificationsAsync.when(
        loading: () => _buildLoadingSkeleton(theme),
        error: (error, stack) => _buildErrorState(theme, colorScheme, error),
        data: (notifications) {
          final filteredNotifications = _currentTab == 0
              ? notifications
              : ref
                  .read(notificationsProvider.notifier)
                  .getMentions(notifications);

          if (filteredNotifications.isEmpty) {
            return _buildEmptyState(theme, colorScheme);
          }

          final grouped = _groupNotifications(filteredNotifications);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            color: colorScheme.primary,
            child: _buildGroupedList(grouped),
          );
        },
      ),
    );
  }

  Future<void> _handleMarkAllRead() async {
    await ref.read(markAllReadProvider.notifier).markAllRead();
  }

  Map<String, List<NotificationModel>> _groupNotifications(
      List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    final Map<String, List<NotificationModel>> grouped = {
      'اليوم': [],
      'هذا الأسبوع': [],
      'سابقاً': [],
    };

    for (final notif in notifications) {
      final notifDate = DateTime(
          notif.createdAt.year, notif.createdAt.month, notif.createdAt.day);

      if (notifDate.isAtSameMomentAs(today) || notifDate.isAfter(today)) {
        grouped['اليوم']!.add(notif);
      } else if (notifDate.isAfter(weekAgo)) {
        grouped['هذا الأسبوع']!.add(notif);
      } else {
        grouped['سابقاً']!.add(notif);
      }
    }

    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  Widget _buildGroupedList(
    Map<String, List<NotificationModel>> grouped,
  ) {
    final keys = grouped.keys.toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification &&
            scrollNotification.metrics.pixels ==
                scrollNotification.metrics.maxScrollExtent) {
          ref.read(notificationsProvider.notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          for (final key in keys) ...[
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      key,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final notif = grouped[key]![index];
                  return NotificationCard(
                    notification: notif,
                    onFollowBack: () {
                      ref.read(notificationsProvider.notifier).refresh();
                    },
                  );
                },
                childCount: grouped[key]!.length,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    final isMentionsTab = _currentTab == 1;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMentionsTab
                  ? Icons.alternate_email
                  : Icons.notifications_outlined,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isMentionsTab ? 'لا توجد إشارات' : 'لا توجد إشعارات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMentionsTab
                ? 'لم يشر إليك أحد بعد'
                : 'لا يوجد شيء جديد في الوقت الحالي',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      ThemeData theme, ColorScheme colorScheme, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'حدث خطأ أثناء تحميل الإشعارات',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    final dividerColor = theme.dividerColor;
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: dividerColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: dividerColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200,
                    height: 14,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}