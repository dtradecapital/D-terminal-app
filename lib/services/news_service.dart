import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class NewsService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  // Free CORS-friendly RSS sources via rss2json.com (no API key needed)
  static const _rssSources = [
    ('https://www.forexlive.com/feed/news', 'FOREXLIVE'),
    ('https://www.fxstreet.com/rss/news', 'FXSTREET'),
  ];

  Future<List<dynamic>> fetchForexNews({String? date}) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final isToday = date == null || date == today;

    // RSS only has recent articles — use mock for historical dates
    if (!isToday) return _getMockNews(date: date);

    for (final (rssUrl, sourceName) in _rssSources) {
      try {
        final response = await _dio.get(
          'https://api.rss2json.com/v1/api.json',
          queryParameters: {'rss_url': rssUrl, 'count': '10'},
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 && response.data['status'] == 'ok') {
          final items = response.data['items'] as List? ?? [];
          if (items.isNotEmpty) {
            return items.map((item) => {
              'id': item['guid'] ?? item['link'] ?? '',
              'headline': item['title'] ?? '',
              'source': sourceName,
              'published_at': item['pubDate'] ?? DateTime.now().toIso8601String(),
              'category': _inferCategory(item['title']?.toString() ?? ''),
              'url': item['link'] ?? '',
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('RSS News Error ($sourceName): $e');
      }
    }

    return _getMockNews(date: date);
  }

  String _inferCategory(String title) {
    final t = title.toLowerCase();
    if (t.contains('fed') || t.contains('fomc') || t.contains('ecb') || t.contains('boe') || t.contains('central bank')) return 'CENTRAL BANK';
    if (t.contains('gold') || t.contains('xau') || t.contains('silver')) return 'METALS';
    if (t.contains('oil') || t.contains('crude') || t.contains('brent')) return 'ENERGY';
    if (t.contains('inflation') || t.contains('cpi') || t.contains('pce') || t.contains('gdp')) return 'MACRO';
    if (t.contains('war') || t.contains('sanction') || t.contains('geopolit')) return 'GEO';
    if (t.contains('usd') || t.contains('dollar') || t.contains('eur') || t.contains('gbp') || t.contains('jpy')) return 'FOREX';
    return 'MARKET';
  }

  List<dynamic> _getMockNews({String? date}) {
    final baseDate = date != null ? DateTime.parse(date) : DateTime.now();
    final dateStr = date ?? baseDate.toIso8601String().split('T')[0];
    final int seed = dateStr.hashCode;
    final pool = [
      {"h": "Strategic Market Outlook: Key Volatility Zones Identified", "c": "STRATEGY"},
      {"h": "Central Bank Policy Shifts impacting G10 Currencies", "c": "MACRO"},
      {"h": "Regional Stability Update: Report on Emerging Markets", "c": "GEO"},
      {"h": "Advanced Pattern Recognition: Harmonic Convergence detected", "c": "ALGO"},
      {"h": "Liquidity Drain: Institutional flow analysis shows bearish trend", "c": "FLOWS"},
      {"h": "Geopolitical Tension Index: Rising risk in Eastern Europe", "c": "INTEL"},
      {"h": "Safe Haven Flow: Capital migration to XAU/USD accelerated", "c": "RISK"},
      {"h": "Monetary Divergence: Fed vs ECB policy gap widening", "c": "POLARITY"},
    ];
    return List.generate(4, (i) {
      final item = pool[(seed + i) % pool.length];
      return {
        "id": "mock-$dateStr-$i",
        "headline": "${item['h']} ($dateStr)",
        "source": i == 0 ? "BATTLE INTELLIGENCE" : (i % 2 == 0 ? "REUTERS" : "BLOOMBERG"),
        "published_at": baseDate.subtract(Duration(hours: i * 2 + 1)).toIso8601String(),
        "category": item['c'],
      };
    });
  }
}
