import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityMessage {
  final String id;
  final String title;
  final String content;
  final String type;
  final DateTime createdAt;

  CommunityMessage({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  factory CommunityMessage.fromMap(Map<String, dynamic> map) {
    return CommunityMessage(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? map['sender_name'] ?? 'Broadcast Announcement',
      content: map['content'] ?? map['message'] ?? '',
      type: map['type'] ?? map['sender_role'] ?? 'all',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class CommunityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<CommunityMessage>> getMessagesStream() {
    return _supabase
        .from('ticket_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((m) => CommunityMessage.fromMap(m)).toList());
  }

  Future<List<CommunityMessage>> getMessages() async {
    final response = await _supabase
        .from('ticket_messages')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((m) => CommunityMessage.fromMap(m)).toList();
  }

}

final communityServiceProvider = Provider((ref) => CommunityService());

final communityMessagesProvider = FutureProvider<List<CommunityMessage>>((ref) async {
  return ref.watch(communityServiceProvider).getMessages();
});
