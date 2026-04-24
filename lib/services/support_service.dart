import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String category;
  final String status;
  final DateTime createdAt;
  final String? description;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.category,
    required this.status,
    required this.createdAt,
    this.description,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      userId: json['user_id'],
      subject: json['subject'],
      category: json['category'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      description: json['description'],
    );
  }
}

class SupportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SupportTicket>> getUserTickets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => SupportTicket.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      return [];
    }
  }

  Future<bool> createTicket(String subject, String category, String description) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase.from('support_tickets').insert({
        'user_id': user.id,
        'subject': subject,
        'category': category,
        'description': description,
        'status': 'OPEN',
      });
      return true;
    } catch (e) {
      debugPrint('Error creating ticket: $e');
      return false;
    }
  }
}

final supportServiceProvider = Provider((ref) => SupportService());

final userTicketsProvider = FutureProvider<List<SupportTicket>>((ref) async {
  return ref.watch(supportServiceProvider).getUserTickets();
});
