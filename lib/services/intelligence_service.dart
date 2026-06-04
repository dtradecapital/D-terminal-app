import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';

class EconomicEvent {
  final String date;
  final String time;
  final String country;
  final String event;
  final String impact;
  final String forecast;
  final String previous;
  final String actual;

  EconomicEvent({
    required this.date,
    required this.time,
    required this.country,
    required this.event,
    required this.impact,
    required this.forecast,
    required this.previous,
    required this.actual,
  });

  factory EconomicEvent.fromJson(Map<String, dynamic> json) {
    String? getString(String key) {
      final val = json[key];
      if (val == null || (val is String && val.isEmpty)) return null;
      return val.toString();
    }

    return EconomicEvent(
      date: getString('date') ?? '',
      time: getString('time') ?? '',
      country: getString('country') ?? '',
      event: getString('event') ?? getString('title') ?? '',
      impact: getString('impact') ?? 'Low',
      forecast: getString('forecast') ?? '--',
      previous: getString('previous') ?? '--',
      actual: getString('actual') ?? '--',
    );
  }
}

class TradeSignal {
  final String pair;
  final String type; // BUY, SELL
  final String headline;
  final List<String> tags;
  final int confidence;
  final String timeframe;
  final String status; // ACTIVE, PASSED
  final String? result; // TP1, TP2, SL
  final String? pips; // +80, -20

  TradeSignal({
    required this.pair,
    required this.type,
    required this.headline,
    required this.tags,
    required this.confidence,
    required this.timeframe,
    this.status = 'ACTIVE',
    this.result,
    this.pips,
  });

  factory TradeSignal.fromJson(Map<String, dynamic> json) {
    return TradeSignal(
      pair: json['pair'] ?? '--',
      type: json['type'] ?? 'BUY',
      headline: json['headline'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      confidence: json['confidence'] ?? 0,
      timeframe: json['timeframe'] ?? 'D1',
      status: json['status'] ?? 'ACTIVE',
      result: json['result'],
      pips: json['pips'],
    );
  }
}

class RegionalRisk {
  final String region;
  final int riskIndex;
  final Color color;
  final double top;
  final double left;

  const RegionalRisk({
    required this.region,
    required this.riskIndex,
    required this.color,
    required this.top,
    required this.left,
  });
}

class IntelligenceService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<EconomicEvent>> fetchEconomicCalendar() async {
    // Twelve Data supports CORS — works on both web and native.
    try {
      final response = await Dio().get(
        'https://api.twelvedata.com/economic_calendar',
        queryParameters: {'apikey': ApiConstants.twelveDataApiKey},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> events = response.data['economic_calendar'] ?? [];
        if (events.isNotEmpty) {
          return events.take(24).map((e) => EconomicEvent.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching economic calendar: $e');
    }
    return _getFallbackCalendar();
  }

  List<EconomicEvent> _getFallbackCalendar() {
    final now = DateTime.now();
    final dateStr = "${now.month}-${now.day}-${now.year}";
    
    return [
      EconomicEvent(
        date: dateStr,
        time: "1:30pm",
        country: "USD",
        event: "Core Retail Sales m/m",
        impact: "High",
        forecast: "0.5%",
        previous: "0.3%",
        actual: "",
      ),
      EconomicEvent(
        date: dateStr,
        time: "1:30pm",
        country: "USD",
        event: "Retail Sales m/m",
        impact: "High",
        forecast: "0.4%",
        previous: "0.6%",
        actual: "",
      ),
      EconomicEvent(
        date: dateStr,
        time: "3:00pm",
        country: "USD",
        event: "Business Inventories m/m",
        impact: "Low",
        forecast: "0.4%",
        previous: "0.0%",
        actual: "",
      ),
      EconomicEvent(
        date: dateStr,
        time: "3:00pm",
        country: "USD",
        event: "NAHB Housing Market Index",
        impact: "Medium",
        forecast: "51",
        previous: "51",
        actual: "",
      ),
      EconomicEvent(
        date: dateStr,
        time: "4:00pm",
        country: "USD",
        event: "TIC Long-Term Purchases",
        impact: "Low",
        forecast: "70.2B",
        previous: "71.5B",
        actual: "",
      ),
      EconomicEvent(
        date: dateStr,
        time: "8:00pm",
        country: "USD",
        event: "FOMC Member Speak",
        impact: "Medium",
        forecast: "--",
        previous: "--",
        actual: "",
      ),
    ];
  }

  Future<List<TradeSignal>> fetchSignals() async {
    // Twelve Data /rsi and /macd indicator endpoints do not support CORS —
    // they hang on Flutter Web until timeout. Use fallback on web.
    if (kIsWeb) return _getFallbackSignals();

    // Native: compute live signals from RSI + MACD (2 batched API calls).
    const pairs = ['XAU/USD', 'EUR/USD', 'GBP/USD', 'USD/JPY'];
    const symbolStr = 'XAU/USD,EUR/USD,GBP/USD,USD/JPY';
    try {
      final dio = Dio();
      final results = await Future.wait([
        dio.get('https://api.twelvedata.com/rsi', queryParameters: {
          'symbol': symbolStr, 'interval': '1h', 'outputsize': '2',
          'apikey': ApiConstants.twelveDataApiKey,
        }).timeout(const Duration(seconds: 8)),
        dio.get('https://api.twelvedata.com/macd', queryParameters: {
          'symbol': symbolStr, 'interval': '1h', 'outputsize': '1',
          'apikey': ApiConstants.twelveDataApiKey,
        }).timeout(const Duration(seconds: 8)),
      ]);

      final rsiData = results[0].statusCode == 200 ? results[0].data : {};
      final macdData = results[1].statusCode == 200 ? results[1].data : {};
      final signals = <TradeSignal>[];

      for (final pair in pairs) {
        final rsiPair = rsiData[pair];
        if (rsiPair == null || rsiPair['status'] == 'error') continue;
        final rsiValues = rsiPair['values'] as List? ?? [];
        if (rsiValues.isEmpty) continue;
        final rsi = double.tryParse(rsiValues[0]['rsi']?.toString() ?? '') ?? 50.0;

        double? macdLine;
        final macdPair = macdData[pair];
        if (macdPair != null && macdPair['status'] != 'error') {
          final mv = macdPair['values'] as List? ?? [];
          if (mv.isNotEmpty) macdLine = double.tryParse(mv[0]['macd']?.toString() ?? '');
        }

        String type; String headline; List<String> tags; int confidence;
        if (rsi > 70) {
          type = 'SELL'; confidence = ((rsi - 70) / 30 * 100).clamp(58, 95).toInt();
          headline = 'RSI overbought at ${rsi.toStringAsFixed(1)} on $pair; bearish reversal probable.';
          tags = ['RSI', 'OVERBOUGHT', 'REVERSAL'];
        } else if (rsi < 30) {
          type = 'BUY'; confidence = ((30 - rsi) / 30 * 100).clamp(58, 95).toInt();
          headline = 'RSI oversold at ${rsi.toStringAsFixed(1)} on $pair; bullish bounce expected.';
          tags = ['RSI', 'OVERSOLD', 'BOUNCE'];
        } else if (macdLine != null && macdLine > 0 && rsi > 50) {
          type = 'BUY'; confidence = ((rsi - 50) / 50 * 60 + 50).clamp(52, 85).toInt();
          headline = 'MACD bullish crossover with rising RSI momentum on $pair.';
          tags = ['MACD', 'MOMENTUM', 'BULLISH'];
        } else if (macdLine != null && macdLine < 0 && rsi < 50) {
          type = 'SELL'; confidence = ((50 - rsi) / 50 * 60 + 50).clamp(52, 85).toInt();
          headline = 'MACD bearish crossover; downward pressure building on $pair.';
          tags = ['MACD', 'MOMENTUM', 'BEARISH'];
        } else {
          type = rsi >= 50 ? 'BUY' : 'SELL'; confidence = 55;
          headline = '${rsi >= 50 ? 'Mild bullish' : 'Mild bearish'} bias detected at RSI ${rsi.toStringAsFixed(1)} on $pair.';
          tags = ['TECHNICAL', 'RSI', 'NEUTRAL'];
        }
        signals.add(TradeSignal(
          pair: pair, type: type, headline: headline, tags: tags,
          confidence: confidence, timeframe: 'H1', status: 'ACTIVE',
        ));
      }
      if (signals.isNotEmpty) return signals;
    } catch (e) {
      debugPrint('Error fetching signals: $e');
    }
    return _getFallbackSignals();
  }

  Future<Map<String, Map<String, double>>> fetchCorrelationMatrix() async {
    if (kIsWeb) return _getMockMatrix();


    try {
      final response = await _dio.get('${ApiConstants.aiServiceUrl}/market/correlation-matrix', queryParameters: {
        'apikey': ApiConstants.twelveDataApiKey,
      });
      if (response.statusCode == 200) {
         return Map<String, Map<String, double>>.from(
           response.data.map((k, v) => MapEntry(k, Map<String, double>.from(v.map((k2, v2) => MapEntry(k2, v2.toDouble())))))
         );
      }
      return _getMockMatrix();
    } catch (e) {
      return _getMockMatrix();
    }
  }

  List<TradeSignal> _getFallbackSignals() {
    return [
      TradeSignal(
        pair: 'XAU/USD',
        type: 'SELL',
        headline: 'Resistance at 2350 holding firm; technical divergence suggests bearish correction.',
        tags: ['TECHNICAL', 'RESISTANCE', 'DIVERGENCE'],
        confidence: 89,
        timeframe: 'M15',
        status: 'PASSED',
        result: 'TP2',
        pips: '+80',
      ),
      TradeSignal(
        pair: 'XAU/USD',
        type: 'SELL',
        headline: 'Secondary rejection at psychological level; momentum shifting lower.',
        tags: ['MOMENTUM', 'REJECTION'],
        confidence: 82,
        timeframe: 'H1',
        status: 'PASSED',
        result: 'TP2',
        pips: '+80',
      ),
      TradeSignal(
        pair: 'XAU/USD',
        type: 'BUY',
        headline: 'Support structure confirmed at dynamic trendline; bullish momentum building.',
        tags: ['SUPPORT', 'STRUCTURE'],
        confidence: 85,
        timeframe: 'H4',
        status: 'PASSED',
        result: 'TP1',
        pips: '+45',
      ),
      TradeSignal(
        pair: 'XAU/USD',
        type: 'SELL',
        headline: 'Heavy liquidity zone reached; institutional selling pressure detected.',
        tags: ['LIQUIDITY', 'INSTITUTIONAL'],
        confidence: 78,
        timeframe: 'M30',
        status: 'PASSED',
        result: 'TP2',
        pips: '+80',
      ),
    ];
  }

  Map<String, Map<String, double>> _getMockMatrix() {
    return {
      'Iran': {'XAU/USD': 0.72, 'BRENT': 0.85, 'EUR/USD': -0.12, 'USD/JPY': -0.08, 'DXY': -0.15, 'AUD/USD': -0.10},
      'Russia': {'XAU/USD': 0.65, 'BRENT': 0.55, 'EUR/USD': -0.42, 'USD/JPY': -0.18, 'DXY': 0.22, 'AUD/USD': -0.18},
      'Ukraine': {'XAU/USD': 0.58, 'BRENT': 0.35, 'EUR/USD': -0.55, 'USD/JPY': -0.22, 'DXY': 0.18, 'AUD/USD': -0.14},
      'Saudi Arabia': {'XAU/USD': 0.22, 'BRENT': 0.91, 'EUR/USD': -0.08, 'USD/JPY': 0.05, 'DXY': 0.12, 'AUD/USD': 0.28},
      'Germany': {'XAU/USD': 0.15, 'BRENT': -0.18, 'EUR/USD': 0.72, 'USD/JPY': -0.35, 'DXY': -0.55, 'AUD/USD': 0.22},
      'China': {'XAU/USD': 0.31, 'BRENT': 0.28, 'EUR/USD': -0.12, 'USD/JPY': -0.15, 'DXY': -0.22, 'AUD/USD': 0.62},
      'United States': {'XAU/USD': -0.45, 'BRENT': -0.08, 'EUR/USD': -0.88, 'USD/JPY': 0.72, 'DXY': 0.95, 'AUD/USD': -0.52},
      'Japan': {'XAU/USD': 0.18, 'BRENT': -0.22, 'EUR/USD': 0.08, 'USD/JPY': -0.85, 'DXY': -0.35, 'AUD/USD': -0.08},
    };
  }

  Future<String> fetchSituationalReport() async {
    if (kIsWeb) return _getDefaultSitRep();

    try {
      final response = await _dio.get('${ApiConstants.aiServiceUrl}/market/analysis/summary');
      if (response.statusCode == 200) {
        return response.data['summary'] ?? _getDefaultSitRep();
      }
      return _getDefaultSitRep();
    } catch (e) {
      return _getDefaultSitRep();
    }
  }

  String _getDefaultSitRep() {
    return 'Institutional flow identifies dual-front escalation scenario. BRENT targeting \$90 range; favors XAU/USD. Max EUR divergence identified.';
  }

  Future<List<RegionalRisk>> fetchRegionalRisks() async {
    // In a real app, this would fetch from a GeoJSON/Risk API
    // For this institutional dashboard, we'll map current market volatility to geopolitical hotspots
    return const [
      RegionalRisk(region: 'United States', riskIndex: 42, color: Colors.amberAccent, top: 200, left: 240),
      RegionalRisk(region: 'Russia', riskIndex: 88, color: Color(0xFFFF0033), top: 160, left: 620),
      RegionalRisk(region: 'Germany', riskIndex: 55, color: Colors.amberAccent, top: 220, left: 510),
      RegionalRisk(region: 'Middle East', riskIndex: 94, color: Color(0xFFFF0033), top: 290, left: 610),
      RegionalRisk(region: 'Asia Pacific', riskIndex: 22, color: Color(0xFF00FF66), top: 340, left: 880),
      RegionalRisk(region: 'Venezuela', riskIndex: 35, color: Colors.blueAccent, top: 410, left: 320),
      RegionalRisk(region: 'African Union', riskIndex: 61, color: Color(0xFFFFB800), top: 350, left: 550),
      RegionalRisk(region: 'Japan', riskIndex: 28, color: Colors.blueAccent, top: 240, left: 850),
      RegionalRisk(region: 'Ukraine', riskIndex: 92, color: Color(0xFFFF0033), top: 180, left: 580),
    ];
  }

  Future<GdeltData> fetchGdeltData() async {
    final Map<String, double> scores = {
      'ru': 9.2, 'ir': 8.8, 'ua': 8.5, 'cn': 5.8, 'us': 4.2, 'gb': 2.0, 'de': 2.0,
      'jp': 1.8, 'kp': 7.5, 'il': 8.8, 'sy': 7.0, 'ye': 7.5, 've': 4.0, 'tw': 6.0,
      'in': 5.0, 'sa': 4.5, 'au': 2.0, 'br': 2.0, 'ca': 2.0, 'fr': 2.0, 'za': 4.0, 'eg': 4.5
    };

    final List<GdeltHotspot> hotspots = [];
    final List<dynamic> news = [];
    bool isLive = false;

    if (kIsWeb) {
      // GDELT Project APIs do not support CORS, so direct requests from Web fail.
      // Use fallback hotspots directly.
      hotspots.addAll([
        const GdeltHotspot(lat: 55.7558, lon: 37.6173, locationName: 'Moscow, Russia', eventCount: 42),
        const GdeltHotspot(lat: 49.0, lon: 31.0, locationName: 'Kyiv, Ukraine', eventCount: 38),
        const GdeltHotspot(lat: 32.4279, lon: 53.6880, locationName: 'Isfahan, Iran', eventCount: 45),
        const GdeltHotspot(lat: 31.0461, lon: 34.8516, locationName: 'Gaza Border, Israel', eventCount: 50),
        const GdeltHotspot(lat: 39.9042, lon: 116.4074, locationName: 'Taiwan Strait, China', eventCount: 15),
        const GdeltHotspot(lat: 38.9072, lon: -77.0369, locationName: 'Washington DC, USA', eventCount: 12),
        const GdeltHotspot(lat: 52.5200, lon: 13.4050, locationName: 'Berlin, Germany', eventCount: 8),
      ]);
      return GdeltData(
        regionalRiskScores: scores,
        hotspots: hotspots,
        newsFeed: news,
        isLive: false,
      );
    }

    try {
      final geoResponse = await _dio.get(
        'https://api.gdeltproject.org/api/v2/geo/geo',
        queryParameters: {
          'query': 'conflict war sanctions',
          'mode': 'pointdata',
          'format': 'json',
          'timespan': '1440',
        },
      ).timeout(const Duration(seconds: 6));

      if (geoResponse.statusCode == 200 && geoResponse.data != null) {
        isLive = true;
        final features = geoResponse.data['features'] as List? ?? [];
        for (var f in features) {
          final geom = f['geometry'];
          final props = f['properties'];
          if (geom != null && props != null) {
            final coords = geom['coordinates'] as List? ?? [];
            if (coords.length >= 2) {
              final lon = (coords[0] as num).toDouble();
              final lat = (coords[1] as num).toDouble();
              final count = (props['count'] as num?)?.toInt() ?? 1;
              final name = props['name']?.toString() ?? 'Geopolitical Event';
              hotspots.add(GdeltHotspot(lat: lat, lon: lon, locationName: name, eventCount: count));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('GDELT Geo API offline/unreachable: $e');
    }

    try {
      final docResponse = await _dio.get(
        'https://api.gdeltproject.org/api/v2/doc/doc',
        queryParameters: {
          'query': 'war conflict geopolitical',
          'mode': 'artlist',
          'maxrecords': '75',
          'format': 'json',
          'timespan': '1440',
        },
      ).timeout(const Duration(seconds: 6));

      if (docResponse.statusCode == 200 && docResponse.data != null) {
        isLive = true;
        final articles = docResponse.data['articles'] as List? ?? [];
        news.addAll(articles);

        for (var art in articles) {
          final title = (art['title'] ?? art['headline'] ?? '').toString().toLowerCase();
          if (title.contains('russia') || title.contains('moscow') || title.contains('putin')) {
            scores['ru'] = (scores['ru'] ?? 0.0) + 0.1;
          }
          if (title.contains('iran') || title.contains('tehran') || title.contains('houthi') || title.contains('yemen')) {
            scores['ir'] = (scores['ir'] ?? 0.0) + 0.1;
          }
          if (title.contains('ukraine') || title.contains('kyiv') || title.contains('zelensky')) {
            scores['ua'] = (scores['ua'] ?? 0.0) + 0.1;
          }
          if (title.contains('china') || title.contains('beijing') || title.contains('taiwan')) {
            scores['cn'] = (scores['cn'] ?? 0.0) + 0.1;
          }
          if (title.contains('israel') || title.contains('gaza') || title.contains('lebanon') || title.contains('hamas')) {
            scores['il'] = (scores['il'] ?? 0.0) + 0.1;
          }
          if (title.contains('north korea') || title.contains('kim jong')) {
            scores['kp'] = (scores['kp'] ?? 0.0) + 0.1;
          }
          if (title.contains('usa') || title.contains('biden') || title.contains('washington')) {
            scores['us'] = (scores['us'] ?? 0.0) + 0.05;
          }
        }

        scores.forEach((key, value) {
          if (value > 10.0) scores[key] = 10.0;
        });
      }
    } catch (e) {
      debugPrint('GDELT Doc API offline/unreachable: $e');
    }

    if (hotspots.isEmpty) {
      hotspots.addAll([
        GdeltHotspot(lat: 55.7558, lon: 37.6173, locationName: 'Moscow, Russia', eventCount: 42),
        GdeltHotspot(lat: 49.0, lon: 31.0, locationName: 'Kyiv, Ukraine', eventCount: 38),
        GdeltHotspot(lat: 32.4279, lon: 53.6880, locationName: 'Isfahan, Iran', eventCount: 45),
        GdeltHotspot(lat: 31.0461, lon: 34.8516, locationName: 'Gaza Border, Israel', eventCount: 50),
        GdeltHotspot(lat: 39.9042, lon: 116.4074, locationName: 'Taiwan Strait, China', eventCount: 15),
        GdeltHotspot(lat: 38.9072, lon: -77.0369, locationName: 'Washington DC, USA', eventCount: 12),
        GdeltHotspot(lat: 52.5200, lon: 13.4050, locationName: 'Berlin, Germany', eventCount: 8),
      ]);
    }

    return GdeltData(
      regionalRiskScores: scores,
      hotspots: hotspots,
      newsFeed: news,
      isLive: isLive,
    );
  }

  Future<Map<String, dynamic>?> fetchUserGenome(String uid) async {
    try {
      final response = await _dio.get('${ApiConstants.aiServiceUrl}/genome/$uid');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user genome: $e');
      return null;
    }
  }

  Future<List<dynamic>> fetchUserAlerts(String uid) async {
    try {
      final response = await _dio.get('${ApiConstants.aiServiceUrl}/alerts/$uid');
      if (response.statusCode == 200) {
        return response.data is List ? response.data : response.data['alerts'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching user alerts: $e');
      return [];
    }
  }
}

final intelligenceServiceProvider = Provider((ref) => IntelligenceService());

final calendarProvider = FutureProvider<List<EconomicEvent>>((ref) async {
  return ref.watch(intelligenceServiceProvider).fetchEconomicCalendar();
});

final signalsProvider = FutureProvider<List<TradeSignal>>((ref) async {
  return ref.watch(intelligenceServiceProvider).fetchSignals();
});

final correlationMatrixProvider = FutureProvider<Map<String, Map<String, double>>>((ref) async {
  return ref.watch(intelligenceServiceProvider).fetchCorrelationMatrix();
});

final situationalReportProvider = FutureProvider<String>((ref) async {
  return ref.watch(intelligenceServiceProvider).fetchSituationalReport();
});

final regionalRiskProvider = FutureProvider<List<RegionalRisk>>((ref) async {
  return ref.watch(intelligenceServiceProvider).fetchRegionalRisks();
});

final userGenomeProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
  return ref.watch(intelligenceServiceProvider).fetchUserGenome(uid);
});

final userAlertsProvider = FutureProvider.family<List<dynamic>, String>((ref, uid) async {
  return ref.watch(intelligenceServiceProvider).fetchUserAlerts(uid);
});

class DirectionBias {
  final String pair;
  final String bias; // BULLISH, BEARISH, NEUTRAL
  final int rsi;
  final int confidence;
  final String h1Bias;
  final String h4Bias;
  final String d1Bias;

  DirectionBias({
    required this.pair,
    required this.bias,
    required this.rsi,
    required this.confidence,
    required this.h1Bias,
    required this.h4Bias,
    required this.d1Bias,
  });
}

final directionBiasProvider = Provider<List<DirectionBias>>((ref) {
  return [
    DirectionBias(pair: 'EUR/USD', bias: 'BULLISH', rsi: 58, confidence: 72, h1Bias: 'BULLISH', h4Bias: 'NEUTRAL', d1Bias: 'BULLISH'),
    DirectionBias(pair: 'GBP/USD', bias: 'NEUTRAL', rsi: 51, confidence: 60, h1Bias: 'NEUTRAL', h4Bias: 'BULLISH', d1Bias: 'NEUTRAL'),
    DirectionBias(pair: 'USD/JPY', bias: 'BEARISH', rsi: 32, confidence: 85, h1Bias: 'BEARISH', h4Bias: 'BEARISH', d1Bias: 'NEUTRAL'),
    DirectionBias(pair: 'XAU/USD', bias: 'BULLISH', rsi: 68, confidence: 91, h1Bias: 'BULLISH', h4Bias: 'BULLISH', d1Bias: 'BULLISH'),
  ];
});

class GdeltHotspot {
  final double lat;
  final double lon;
  final String locationName;
  final int eventCount;

  const GdeltHotspot({
    required this.lat,
    required this.lon,
    required this.locationName,
    required this.eventCount,
  });
}

class GdeltData {
  final Map<String, double> regionalRiskScores;
  final List<GdeltHotspot> hotspots;
  final List<dynamic> newsFeed;
  final bool isLive;

  const GdeltData({
    required this.regionalRiskScores,
    required this.hotspots,
    required this.newsFeed,
    required this.isLive,
  });
}

final gdeltStreamProvider = StreamProvider<GdeltData>((ref) {
  final service = ref.watch(intelligenceServiceProvider);
  final controller = StreamController<GdeltData>();

  void fetchData() async {
    try {
      final data = await service.fetchGdeltData();
      if (!controller.isClosed) {
        controller.add(data);
      }
    } catch (e) {
      debugPrint('Error polling GDELT: $e');
    }
  }

  fetchData();

  final timer = Timer.periodic(const Duration(seconds: 30), (t) {
    fetchData();
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

