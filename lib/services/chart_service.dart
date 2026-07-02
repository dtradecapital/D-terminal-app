import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';

class CandleData {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  /// Returns null if any required field is missing/null so the caller can skip it.
  static CandleData? tryFromJson(Map<String, dynamic> json) {
    try {
      final dt = json['datetime']?.toString();
      final o  = json['open']?.toString();
      final h  = json['high']?.toString();
      final l  = json['low']?.toString();
      final c  = json['close']?.toString();

      if (dt == null || o == null || h == null || l == null || c == null) {
        return null;
      }

      return CandleData(
        timestamp: DateTime.parse(dt),
        open:  double.parse(o),
        high:  double.parse(h),
        low:   double.parse(l),
        close: double.parse(c),
      );
    } catch (_) {
      return null;
    }
  }
}

class ChartService {
  final Dio _dio = Dio();

  Future<List<CandleData>> fetchTimeSeries({
    required String symbol,
    String interval = '5min',
    int outputSize = 30,
  }) async {
    try {
      final response = await _dio.get(
        'https://api.twelvedata.com/time_series',
        queryParameters: {
          'symbol': symbol,
          'interval': interval,
          'apikey': ApiConstants.twelveDataApiKey,
          'outputsize': outputSize,
        },
      );

      if (response.statusCode == 200) {
        if (response.data['status'] == 'error') {
          throw Exception(response.data['message'] ?? 'Unknown API error');
        }
        final List<dynamic> values = response.data['values'] ?? [];
        // Filter out any candles that fail to parse (null fields, bad data, etc.)
        return values
            .map((v) => CandleData.tryFromJson(v as Map<String, dynamic>))
            .whereType<CandleData>()
            .toList()
            .reversed
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      return [];
    }
  }
}

final chartServiceProvider = Provider((ref) => ChartService());

final timeSeriesProvider =
    FutureProvider.family<List<CandleData>, String>((ref, key) async {
  // key format: "SYMBOL|interval", e.g. "XAU/USD|5min"
  final parts = key.split('|');
  final symbol = parts[0];
  final interval = parts.length > 1 ? parts[1] : '5min';
  final service = ref.watch(chartServiceProvider);
  return service.fetchTimeSeries(symbol: symbol, interval: interval);
});
