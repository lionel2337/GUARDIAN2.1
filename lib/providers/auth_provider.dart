/// Authentication provider — manages user sign-in state via Riverpod.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';
import '../services/local_database_service.dart';
import '../services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _supa = SupabaseService.instance;
  final _db = LocalDatabaseService.instance;
  StreamSubscription? _authSub;

  void _init() {
    // Check if already signed in.
    final currentUser = _supa.currentUser;
    if (currentUser != null) {
      _setUserFromSupabase(currentUser);
    }

    // Listen for auth changes.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _setUserFromSupabase(user);
      } else {
        state = const AuthState();
      }
    });
  }

  void _setUserFromSupabase(User user) {
    final appUser = AppUser(
      id: user.id,
      email: user.email,
      phone: user.userMetadata?['phone'] as String?,
      fullName:
          user.userMetadata?['full_name'] as String? ?? 'Anonymous',
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _db.upsertUser(appUser);
    state = AuthState(
      user: appUser,
      isAuthenticated: true,
    );
  }

  /// Sign in anonymously.
  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supa.signInAnonymously();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supa.signInWithEmail(email, password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new account.
  Future<void> signUp(
      String email, String password, String fullName, String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supa.signUp(email, password, fullName, phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _supa.signOut();
    state = const AuthState();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

/// Convenience provider for the current user ID.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.id;
});
