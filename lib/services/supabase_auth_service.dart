import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../screens/auth_gate.dart';

class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Email and Password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with Email and Password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google via Supabase OAuth (browser-based, no SHA-1 needed)
  static Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
    );
  }

  /// Sign in with Discord using OAuth
  static Future<bool> signInWithDiscord() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.discord,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
    );
  }

  /// Get current user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  /// Record a new trade
  static Future<void> placeTrade({
    required String symbol,
    required String type,
    required double amount,
    required double price,
  }) async {
    final user = currentUser;
    if (user == null) return;

    await _supabase.from('trades').insert({
      'user_id': user.id,
      'symbol': symbol,
      'trade_type': type,
      'volume': amount,
      'entry_price': price,
      'ticket': 'T-${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  /// Send a password reset email
  static Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Sign out from Supabase
  static Future<void> signOut() async {
    try {
      AuthGate.devBypassNotifier.value = false;
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  /// Get current session
  static Session? get currentSession => _supabase.auth.currentSession;

  /// Get current user
  static User? get currentUser => _supabase.auth.currentUser;
}
