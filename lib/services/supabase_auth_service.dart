import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static const _webClientId = '681249716756-utm6v4jofdpsj7v0j3uhvktdgo5gavt8.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'openid',
    ],
  );

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

  /// Sign in with Google
  static Future<void> signInWithGoogle() async {
    // Generate a secure random nonce for Web/Mobile ID token flow
    // In a real app, use a proper crypto-random nonce. 
    // Supabase signInWithIdToken validates the nonce in the ID token.

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw 'Google Sign-in cancelled by user';
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'Google Sign-in failed: ID Token is null. Check Google Console Settings.';
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
      // On some platforms, you might need to pass the nonce if the ID token was generated with one
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

    await _supabase.from('trade').insert({
      'user_id': user.id,
      'symbol': symbol,
      'type': type,
      'amount': amount,
      'price': price,
    });
  }

  /// Send a password reset email
  static Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Sign out from Supabase
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get current session
  static Session? get currentSession => _supabase.auth.currentSession;

  /// Get current user
  static User? get currentUser => _supabase.auth.currentUser;
}
