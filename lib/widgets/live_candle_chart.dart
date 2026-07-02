import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart' as cs;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chart_service.dart';
import '../widgets/shared.dart';

class LiveCandleChart extends ConsumerWidget {
  final String symbol;
  final String interval;
  const LiveCandleChart({
    super.key,
    required this.symbol,
    this.interval = '5min',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Key on both symbol + interval so provider refetches on either change
    final chartDataAsync = ref.watch(timeSeriesProvider('$symbol|$interval'));

    return chartDataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(
            child: Text('No chart data available',
                style: TextStyle(color: Colors.white54)),
          );
        }

        // ChartService reverses to oldest-first; Candlesticks wants newest-first.
        final candles = data
            .map((d) => cs.Candle(
                  date: d.timestamp,
                  high: d.high,
                  low: d.low,
                  open: d.open,
                  close: d.close,
                  volume: 100,
                ))
            .toList()
            .reversed
            .toList();

        return cs.Candlesticks(candles: candles);
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: gold)),
      error: (err, stack) => Center(
          child: Text('Error: $err',
              style: const TextStyle(color: Colors.redAccent))),
    );
  }
}
