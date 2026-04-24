import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/news_service.dart';

final newsServiceProvider = Provider((ref) => NewsService());
// socketServiceProvider is exported from socket_service.dart

final forexNewsProvider = FutureProvider.family<List<dynamic>, String?>((ref, date) async {
  final newsService = ref.watch(newsServiceProvider);
  return newsService.fetchForexNews(date: date);
});
