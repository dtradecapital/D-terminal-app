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

  factory CandleData.fromJson(Map<String, dynamic> json) {
    return CandleData(
      timestamp: DateTime.parse(json['datetime']),
      open: double.parse(json['open']),
      high: double.parse(json['high']),
      low: double.parse(json['low']),
      close: double.parse(json['close']),
    );
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
          throw Exception(response.data['message']);
        }
        final List<dynamic> values = response.data['values'];
        return values.map((v) => CandleData.fromJson(v)).toList().reversed.toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      return [];
    }
  }
}

final chartServiceProvider = Provider((ref) => ChartService());

final timeSeriesProvider = FutureProvider.family<List<CandleData>, String>((ref, symbol) async {
  final service = ref.watch(chartServiceProvider);
  return service.fetchTimeSeries(symbol: symbol);
});
