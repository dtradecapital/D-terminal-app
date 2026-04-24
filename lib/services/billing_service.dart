import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentHistory {
  final String id;
  final String date;
  final String plan;
  final String amount;
  final String method;
  final String status;

  PaymentHistory({
    required this.id,
    required this.date,
    required this.plan,
    required this.amount,
    required this.method,
    required this.status,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id']?.toString() ?? '',
      date: json['created_at']?.toString().split('T')[0] ?? '',
      plan: json['plan_name']?.toString() ?? 'ZERO',
      amount: json['amount']?.toString() ?? '0',
      method: json['payment_method']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'PENDING',
    );
  }
}

class UserSubscription {
  final String planName;
  final String status;
  final String? expiryDate;
  final String auditId;

  UserSubscription({
    required this.planName,
    required this.status,
    this.expiryDate,
    required this.auditId,
  });

  factory UserSubscription.defaultZero() {
    return UserSubscription(
      planName: 'ZERO',
      status: 'ACTIVE',
      expiryDate: 'N/A',
      auditId: 'DTC-46731',
    );
  }
}

class BillingService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<PaymentHistory>> getPaymentHistoryStream() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);

    try {
      return _client
          .from('payment_history')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at')
          .map((data) => data.map((json) => PaymentHistory.fromJson(json)).toList())
          .handleError((error) {
            debugPrint('Billing Stream Error: $error');
            return <PaymentHistory>[];
          });
    } catch (e) {
      debugPrint('Billing Stream Init Error: $e');
      return Stream.value([]);
    }
  }

  Future<UserSubscription> getUserSubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) return UserSubscription.defaultZero();

    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return UserSubscription.defaultZero();

      return UserSubscription(
        planName: response['plan_name'] ?? 'ZERO',
        status: response['status'] ?? 'ACTIVE',
        expiryDate: response['expiry_date'],
        auditId: response['audit_id'] ?? 'DTC-46731',
      );
    } catch (e) {
      return UserSubscription.defaultZero();
    }
  }

  Future<bool> requestPaymentVerification(String transactionId, String amount) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client.from('ticket_messages').insert({
        'user_id': user.id,
        'title': 'PAYMENT VERIFICATION REQUEST',
        'content': 'Transaction ID: $transactionId\nAmount: $amount',
        'type': 'SUPPORT',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> buyPlan(String planName, String amount) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client.from('payment_history').insert({
        'user_id': user.id,
        'plan_name': planName,
        'amount': amount,
        'payment_method': 'STRIPE/PAYPAL',
        'status': 'PENDING',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Buy Plan Error: $e');
      return false;
    }
  }

  Future<bool> submitVerification({
    required String method,
    required String amount,
    required String utr,
    required String date,
    String? notes,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      String? imageUrl;
      if (imageBytes != null && imageName != null) {
        final path = 'audit_${user.id}_${DateTime.now().millisecondsSinceEpoch}_$imageName';
        await _client.storage.from('verifications').uploadBinary(
          path, 
          imageBytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg')
        );
        imageUrl = _client.storage.from('verifications').getPublicUrl(path);
      }

      await _client.from('verifications').insert({
        'user_id': user.id,
        'method': method,
        'amount': amount,
        'utr': utr,
        'payment_date': date,
        'notes': notes,
        'status': 'UNDER REVIEW',
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Verification Submit Error: $e');
      return false;
    }
  }

  Stream<String?> getVerificationStatusStream() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value(null);

    try {
      return _client
          .from('verifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .map((data) => data.isEmpty ? null : data.first['status']?.toString());
    } catch (e) {
      return Stream.value(null);
    }
  }
}

final billingServiceProvider = Provider((ref) => BillingService());

final paymentHistoryProvider = StreamProvider<List<PaymentHistory>>((ref) {
  return ref.watch(billingServiceProvider).getPaymentHistoryStream();
});

final userSubscriptionProvider = FutureProvider<UserSubscription>((ref) {
  return ref.watch(billingServiceProvider).getUserSubscription();
});

final verificationStatusProvider = StreamProvider<String?>((ref) {
  return ref.watch(billingServiceProvider).getVerificationStatusStream();
});
