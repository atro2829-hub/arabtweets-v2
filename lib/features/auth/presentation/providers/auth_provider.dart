import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

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

class AuthNotifier extends Notifier<AuthState> {
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
      state = const AuthState(error: 'حدث خطأ غير متوقع');
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
      state = const AuthState(error: 'حدث خطأ غير متوقع');
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
      state = const AuthState(error: 'حدث خطأ في إرسال البريد');
    }
  }

  void clearState() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _translateError(String? message) {
    if (message == null) return 'حدث خطأ غير متوقع';
    if (message.contains('Invalid login')) return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    if (message.contains('already registered')) return 'هذا البريد مسجل مسبقاً';
    if (message.contains('Password should be')) return 'كلمة المرور ضعيفة جداً';
    if (message.contains('Network')) return 'لا يوجد اتصال بالإنترنت';
    return message;
  }
}

class UserProfileNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      state = AsyncValue.data(UserModel.fromJson(data));
    } catch (e) {
      // keep current state on error
    }
  }

  Future<bool> isAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .single();
      return data['is_admin'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }
}