import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(adminStatsProvider);
    if (_tabController.index == 0) {
      ref.invalidate(allUsersProvider);
    } else {
      ref.invalidate(allReportsProvider);
    }
    _refreshController.refreshCompleted();
  }

  void _showActionFeedback() {
    final actionState = ref.read(adminActionsProvider);
    if (actionState.successMessage != null) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text(actionState.successMessage!),
        autoCloseDuration: const Duration(seconds: 2),
      );
      ref.read(adminActionsProvider.notifier).clearMessages();
    } else if (actionState.error != null) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(actionState.error!),
        autoCloseDuration: const Duration(seconds: 3),
      );
      ref.read(adminActionsProvider.notifier).clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      loading: () => const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: Text('حدث خطأ')),
        ),
      ),
      data: (isAdmin) {
        if (!isAdmin) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppBar(title: const Text('لوحة التحكم')),
              body: const Center(
                child: Text(
                  'ليس لديك صلاحية الوصول',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return _buildDashboard();
      },
    );
  }

  Widget _buildDashboard() {
    final statsAsync = ref.watch(adminStatsProvider);
    final actions = ref.read(adminActionsProvider.notifier);

    // Listen for action feedback
    ref.listen(adminActionsProvider, (previous, next) {
      if (next.successMessage != null || next.error != null) {
        _showActionFeedback();
        // Refresh data after action
        ref.invalidate(allUsersProvider);
        ref.invalidate(allReportsProvider);
        ref.invalidate(adminStatsProvider);
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'لوحة التحكم',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // Stats cards
              SliverToBoxAdapter(
                child: statsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('خطأ: $e'),
                  ),
                  data: (stats) => _buildStatsCards(stats),
                ),
              ),

              // Tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _AdminTabDelegate(tabController: _tabController),
              ),

              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUsersTab(),
                    _buildReportsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(AdminStatsModel stats) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('إجمالي المستخدمين', stats.totalUsers.toString(), Icons.people, Colors.blue),
              const SizedBox(width: 8),
              _buildStatCard('إجمالي التغريدات', stats.totalTweets.toString(), Icons.chat_bubble_outline, Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard('البلاغات', stats.totalReports.toString(), Icons.report, Colors.orange),
              const SizedBox(width: 8),
              _buildStatCard('الريلز', stats.totalReels.toString(), Icons.videocam, Colors.purple),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard('مستخدمون جدد اليوم', stats.todayUsers.toString(), Icons.person_add, Colors.teal),
              const SizedBox(width: 8),
              _buildStatCard('تغريدات اليوم', stats.todayTweets.toString(), Icons.edit_note, Colors.amber.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                Formatters.formatArabicCount(int.tryParse(value) ?? 0),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    final usersAsync = ref.watch(allUsersProvider);
    final actionsNotifier = ref.read(adminActionsProvider.notifier);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ في تحميل المستخدمين: $e')),
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('لا يوجد مستخدمون'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserTile(user, actionsNotifier);
          },
        );
      },
    );
  }

  Widget _buildUserTile(AdminUserModel user, AdminActionsNotifier actionsNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and username
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0] : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, size: 16, color: Colors.blue),
                        ],
                        if (user.isAdmin) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'مدير',
                              style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                        if (user.isBanned) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'محظور',
                              style: TextStyle(fontSize: 10, color: Colors.red.shade800),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '@${user.username}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                    if (user.email != null && user.email!.isNotEmpty)
                      Text(
                        user.email!,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stats
          Text(
            '${user.tweetsCount} تغريدة · ${Formatters.formatArabicCount(user.followersCount)} متابع',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: Icon(
                  user.isVerified ? Icons.check_circle : Icons.check_circle_outline,
                  size: 16,
                  color: user.isVerified ? Colors.blue : Colors.grey,
                ),
                label: Text(user.isVerified ? 'إلغاء التأكيد' : 'تأكيد'),
                onPressed: () => actionsNotifier.toggleVerified(user.id, user.isVerified),
              ),
              ActionChip(
                avatar: Icon(
                  user.isAdmin ? Icons.shield : Icons.shield_outlined,
                  size: 16,
                  color: user.isAdmin ? Colors.orange : Colors.grey,
                ),
                label: Text(user.isAdmin ? 'إزالة المدير' : 'تعيين مدير'),
                onPressed: () => actionsNotifier.toggleAdmin(user.id, user.isAdmin),
              ),
              ActionChip(
                avatar: Icon(
                  user.isBanned ? Icons.lock_open : Icons.block,
                  size: 16,
                  color: user.isBanned ? Colors.green : Colors.red,
                ),
                label: Text(user.isBanned ? 'إلغاء الحظر' : 'حظر'),
                onPressed: () {
                  if (user.isBanned) {
                    actionsNotifier.unbanUser(user.id);
                  } else {
                    actionsNotifier.banUser(user.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    final reportsAsync = ref.watch(allReportsProvider);
    final actionsNotifier = ref.read(adminActionsProvider.notifier);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ في تحميل البلاغات: $e')),
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(child: Text('لا توجد بلاغات'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportTile(report, actionsNotifier);
          },
        );
      },
    );
  }

  Widget _buildReportTile(AdminReportModel report, AdminActionsNotifier actionsNotifier) {
    final statusColor = report.status == 'pending'
        ? Colors.orange
        : report.status == 'reviewed'
            ? Colors.blue
            : Colors.grey;

    final statusText = report.status == 'pending'
        ? 'قيد المراجعة'
        : report.status == 'reviewed'
            ? 'تمت المراجعة'
            : 'مرفوض';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.report, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'بلاغ من @${report.reporterUsername ?? "مجهول"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reason
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report.reason,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          // Target info
          if (report.targetUserId != null)
            Text(
              'المستخدم المُبلَغ عنه: ${report.targetUserId!.substring(0, 8)}...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          if (report.tweetId != null)
            Text(
              'تغريدة: ${report.tweetId!.substring(0, 8)}...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          Text(
            Formatters.timeAgo(report.createdAt),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // Action buttons
          Row(
            children: [
              if (report.status == 'pending') ...[
                OutlinedButton(
                  onPressed: () => actionsNotifier.dismissReport(report.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('رفض البلاغ'),
                ),
                const SizedBox(width: 8),
              ],
              if (report.tweetId != null)
                OutlinedButton(
                  onPressed: () => actionsNotifier.deleteTweet(report.tweetId!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('حذف التغريدة'),
                ),
              if (report.tweetId != null) const SizedBox(width: 8),
              if (report.targetUserId != null)
                OutlinedButton(
                  onPressed: () => actionsNotifier.banUser(report.targetUserId!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('حظر المستخدم'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminTabDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _AdminTabDelegate({required this.tabController});

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
          Tab(text: 'المستخدمون'),
          Tab(text: 'البلاغات'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _AdminTabDelegate oldDelegate) {
    return tabController != oldDelegate.tabController;
  }
}