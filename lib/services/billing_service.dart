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
      plan: json['plan_type']?.toString() ?? 'ZERO',
      amount: json['amount']?.toString() ?? '0',
      method: json['payment_method']?.toString() ?? 'N/A',
      status: json['payment_status']?.toString() ?? 'PENDING',
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
          .from('payments')
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
          .eq('user_email', user.email ?? '')
          .maybeSingle();

      if (response == null) return UserSubscription.defaultZero();

      return UserSubscription(
        planName: response['plan_name'] ?? response['plan_type'] ?? 'ZERO',
        status: response['status'] ?? 'ACTIVE',
        expiryDate: response['end_date']?.toString() ?? response['expiry_date']?.toString(),
        auditId: response['transaction_id'] ?? response['id']?.toString() ?? 'DTC-46731',
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
        'sender_id': user.id,
        'sender_name': user.email?.split('@').first.toUpperCase() ?? 'CLIENT',
        'sender_role': 'client',
        'message': 'PAYMENT VERIFICATION REQUEST\nTransaction ID: $transactionId\nAmount: $amount',
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
      final randomTxId = 'tx_${DateTime.now().millisecondsSinceEpoch}_${user.id.substring(0, 4)}';
      await _client.from('payments').insert({
        'user_id': user.id,
        'plan_type': planName,
        'amount': amount,
        'payment_method': 'STRIPE/PAYPAL',
        'payment_status': 'PENDING',
        'transaction_id': randomTxId,
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
    String planType = 'PREMIUM',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      String? imageUrl;
      if (imageBytes != null && imageName != null) {
        try {
          final path = 'audit_${user.id}_${DateTime.now().millisecondsSinceEpoch}_$imageName';
          await _client.storage.from('payment_submissions').uploadBinary(
            path, 
            imageBytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg')
          );
          imageUrl = _client.storage.from('payment_submissions').getPublicUrl(path);
        } catch (storageError) {
          debugPrint('Storage Upload Failed (proceeding without image): $storageError');
          imageUrl = null;
        }
      }

      await _client.from('payment_submissions').insert({
        'user_id': user.id,
        'user_email': user.email,
        'payment_method': method,
        'amount': amount,
        'utr_number': utr,
        'date_of_payment': date,
        'additional_notes': notes,
        'status': 'pending',
        'screenshot_url': imageUrl,
        'plan_type': planType,
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
          .from('payment_submissions')
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
