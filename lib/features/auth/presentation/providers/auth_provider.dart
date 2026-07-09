import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/user_model.dart';

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

final currentUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) {
    return event.session?.user;
  });
});

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserModel?>(
        () => UserProfileNotifier());

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'display_name': displayName.trim(),
          'username': username.trim().toLowerCase(),
        },
      );
      state = const AuthState(isSuccess: true);
    } on AuthException catch (e) {
      state = AuthState(error: _translateError(e.message));
    } on PostgrestException catch (e) {
      state = AuthState(error: _translateError(e.message));
    } catch (e) {
      state = AuthState(error: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      state = const AuthState(isSuccess: true);
    } on AuthException catch (e) {
      state = AuthState(error: _translateError(e.message));
    } catch (e) {
      state = AuthState(error: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.');
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = const AuthState();
  }

  Future<void> resetPassword({required String email}) async {
    state = const AuthState(isLoading: true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.trim(),
      );
      state = const AuthState(isSuccess: true);
    } on AuthException catch (e) {
      state = AuthState(error: _translateError(e.message));
    } catch (e) {
      state = AuthState(error: 'حدث خطأ في إرسال البريد. يرجى المحاولة مرة أخرى.');
    }
  }

  void clearState() {
    state = const AuthState();
  }

  void clearError() {
    state = state.value?.copyWith(clearError: true) ?? const AuthState();
  }

  String _translateError(String message) {
    if (message.contains('Invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (message.contains('Email not confirmed')) {
      return 'يرجى تأكيد البريد الإلكتروني أولاً';
    }
    if (message.contains('User already registered') ||
        message.contains('already registered')) {
      return 'البريد الإلكتروني مسجل مسبقاً';
    }
    if (message.contains('Password should be at least')) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'تم تجاوز عدد المحاولات. يرجى الانتظار قليلاً';
    }
    if (message.contains('Network') || message.contains('socket')) {
      return 'خطأ في الاتصال بالشبكة';
    }
    if (message.contains('duplicate') || message.contains('unique')) {
      return 'اسم المستخدم أو البريد الإلكتروني مستخدم مسبقاً';
    }
    return message;
  }
}

class UserProfileNotifier extends AsyncNotifier<UserModel?> {
  @override
  UserModel? build() {
    _init();
    return null;
  }

  Future<void> _init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await loadUserProfile(user.id);
  }

  Future<void> loadUserProfile(String userId) async {
    state = const AsyncLoading();
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      state = AsyncData(UserModel.fromJson(response));
    } on PostgrestException catch (e) {
      state = AsyncError(e, StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final profile = UserModel.fromJson(response);
      state = AsyncData(profile);
      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .single();

      return response['is_admin'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = const AsyncData(null);
      return;
    }
    await loadUserProfile(user.id);
  }
}