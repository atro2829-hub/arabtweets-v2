import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adentweet/features/admin/data/models/admin_models.dart';

// ─── Is Admin Provider (reads from DB!) ───────────────────────────────────

final isAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;

  final response = await Supabase.instance.client
      .from('profiles')
      .select('is_admin')
      .eq('id', userId)
      .single();

  return response['is_admin'] as bool? ?? false;
});

// ─── Admin Stats Provider ─────────────────────────────────────────────────

final adminStatsProvider =
    AsyncNotifierProvider<AdminStatsNotifier, AdminStatsModel>(
  AdminStatsNotifier.new,
);

class AdminStatsNotifier extends AsyncNotifier<AdminStatsModel> {
  @override
  Future<AdminStatsModel> build() async {
    final response = await Supabase.instance.client.rpc('get_admin_stats');
    final data = response as Map<String, dynamic>;
    return AdminStatsModel.fromJson(data);
  }
}

// ─── All Users Provider ───────────────────────────────────────────────────

final allUsersProvider =
    AsyncNotifierProvider<AllUsersNotifier, List<AdminUserModel>>(
  AllUsersNotifier.new,
);

class AllUsersNotifier extends AsyncNotifier<List<AdminUserModel>> {
  @override
  Future<List<AdminUserModel>> build() async {
    return _fetchUsers();
  }

  Future<List<AdminUserModel>> _fetchUsers({int limit = 50, int offset = 0}) async {
    final response = await Supabase.instance.client.rpc('get_all_users', params: {
      'p_limit': limit,
      'p_offset': offset,
    });

    final data = response as List<dynamic>;
    return data
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _fetchUsers());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull ?? [];
    try {
      final more = await _fetchUsers(offset: current.length);
      state = AsyncData([...current, ...more]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ─── All Reports Provider ─────────────────────────────────────────────────

final allReportsProvider =
    AsyncNotifierProvider<AllReportsNotifier, List<AdminReportModel>>(
  AllReportsNotifier.new,
);

class AllReportsNotifier extends AsyncNotifier<List<AdminReportModel>> {
  @override
  Future<List<AdminReportModel>> build() async {
    return _fetchReports();
  }

  Future<List<AdminReportModel>> _fetchReports({int limit = 50, int offset = 0}) async {
    final response = await Supabase.instance.client.rpc('get_all_reports', params: {
      'p_limit': limit,
      'p_offset': offset,
    });

    final data = response as List<dynamic>;
    return data
        .map((e) => AdminReportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _fetchReports());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull ?? [];
    try {
      final more = await _fetchReports(offset: current.length);
      state = AsyncData([...current, ...more]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ─── Admin Actions Provider ───────────────────────────────────────────────

class AdminActionsState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AdminActionsState({this.isLoading = false, this.error, this.successMessage});

  AdminActionsState copyWith({bool? isLoading, String? error, String? successMessage}) {
    return AdminActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

final adminActionsProvider =
    NotifierProvider<AdminActionsNotifier, AdminActionsState>(
  AdminActionsNotifier.new,
);

class AdminActionsNotifier extends Notifier<AdminActionsState> {
  @override
  AdminActionsState build() {
    return AdminActionsState();
  }

  Future<bool> deleteTweet(String tweetId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await Supabase.instance.client
          .from('tweets')
          .delete()
          .eq('id', tweetId);
      state = state.copyWith(isLoading: false, successMessage: 'تم حذف التغريدة');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'فشل حذف التغريدة: ${e.toString()}');
      return false;
    }
  }

  Future<bool> banUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_banned': true})
          .eq('id', userId);
      state = state.copyWith(isLoading: false, successMessage: 'تم حظر المستخدم');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'فشل حظر المستخدم: ${e.toString()}');
      return false;
    }
  }

  Future<bool> unbanUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_banned': false})
          .eq('id', userId);
      state = state.copyWith(isLoading: false, successMessage: 'تم إلغاء حظر المستخدم');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'فشل إلغاء الحظر: ${e.toString()}');
      return false;
    }
  }

  Future<bool> toggleVerified(String userId, bool currentValue) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'is_verified': !currentValue,
            'verification_type': !currentValue ? 'blue' : 'none',
          })
          .eq('id', userId);
      final msg = !currentValue ? 'تم تأكيد الحساب' : 'تم إلغاء التأكيد';
      state = state.copyWith(isLoading: false, successMessage: msg);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'فشل تحديث التأكيد: ${e.toString()}');
      return false;
    }
  }

  Future<bool> toggleAdmin(String userId, bool currentValue) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_admin': !currentValue})
          .eq('id', userId);
      final msg = !currentValue ? 'تم تعيين المدير' : 'تم إزالة المدير';
      state = state.copyWith(isLoading: false, successMessage: msg);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'فشل تحديث الصلاحية: ${e.toString()}');
      return false;
    }
  }

  Future<bool> dismissReport(String reportId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await Supabase.instance.client
          .from('reports')
          .update({'status': 'dismissed'})
          .eq('id', reportId);
      state = state.copyWith(isLoading: false, successMessage: 'تم رفض البلاغ');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'فشل رفض البلاغ: ${e.toString()}');
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}