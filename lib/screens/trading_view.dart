import 'package:flutter/material.dart';
import '../widgets/shared.dart';
import '../widgets/live_candle_chart.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/intelligence_service.dart';

class TradingView extends ConsumerStatefulWidget {
  const TradingView({super.key});

  @override
  ConsumerState<TradingView> createState() => _TradingViewState();
}

class _TradingViewState extends ConsumerState<TradingView> {
  final ScrollController _mainScrollController = ScrollController();
  bool _isPaperConnected = false;
  double _paperBalance = 0;
  String _selectedLot = '0.01';
  int _positionsTabIndex = 0; // 0: Open, 1: History, 2: Pending
  final List<Map<String, dynamic>> _openPositions = [];
  final List<Map<String, dynamic>> _history = [];

  String _selectedOrderType = 'BUY';
  double _stopLoss = 50.0;
  double _takeProfit = 100.0;
  String _selectedSignalTab = 'ALL';
  Set<int>? __expandedSignalIndices;
  Set<int> get _expandedSignalIndices => __expandedSignalIndices ??= {};

  final List<Map<String, dynamic>> _marketWatchItems = [
    {
      'label': 'EU',
      'color': Colors.blueAccent,
      'pair': 'EUR/USD',
      'price': '1.0724',
      'change': '-0.80%',
      'isUp': false
    },
    {
      'label': 'GB',
      'color': Colors.deepPurpleAccent,
      'pair': 'GBP/USD',
      'price': '1.2624',
      'change': '-0.40%',
      'isUp': false
    },
    {
      'label': 'US',
      'color': Colors.white24,
      'pair': 'USD/JPY',
      'price': '152.84',
      'change': '+1.48%',
      'isUp': true
    },
  ];

  final List<Map<String, dynamic>> _allAvailableSymbols = [
    {'pair': 'USD/CHF', 'label': 'CH', 'color': Colors.redAccent},
    {'pair': 'NZD/USD', 'label': 'NZ', 'color': Colors.blue},
    {'pair': 'EUR/GBP', 'label': 'EG', 'color': Colors.green},
    {'pair': 'AUD/USD', 'label': 'AU', 'color': Colors.orange},
    {'pair': 'USD/CAD', 'label': 'CA', 'color': Colors.brown},
    {'pair': 'XAU/USD', 'label': 'XA', 'color': Colors.amber},
    {'pair': 'BTC/USD', 'label': 'BT', 'color': Colors.orangeAccent},
  ];

  late List<Map<String, dynamic>> _signals;

  @override
  void initState() {
    super.initState();
    // _signals will now be fetched from signalsProvider in the build method
  }

  void _showAddSymbolDialog() {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredSymbols = _allAvailableSymbols
              .where((s) =>
                  (s['pair']?.toString().toLowerCase() ?? '')
                  .contains(searchQuery.toLowerCase()))
              .toList();

          return Dialog(
            backgroundColor: const Color(0xFF09080B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ADD SYMBOL',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close,
                            color: Colors.white24, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: gold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      onChanged: (v) => setDialogState(() => searchQuery = v),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search pairs...',
                        hintStyle: TextStyle(color: Colors.white10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredSymbols.length,
                      itemBuilder: (context, index) {
                        final s = filteredSymbols[index];
                        return ListTile(
                          onTap: () {
                            setState(() {
                              if (!_marketWatchItems
                                  .any((item) => item['pair'] == s['pair'])) {
                                _marketWatchItems.add({
                                  'label': s['label'],
                                  'color': s['color'],
                                  'pair': s['pair'],
                                  'price': '0.0000',
                                  'change': '0.00%',
                                  'isUp': true,
                                });
                              }
                            });
                            Navigator.pop(ctx);
                          },
                          title: Text(s['pair'],
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          dense: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBrokerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF131118),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TRADE WITH YOUR BROKER',
                      style: TextStyle(
                          color: gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close,
                          color: Colors.white.withOpacity(0.2), size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Connect your broker to activate live trading',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 10)),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1721),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: Colors.white.withOpacity(0.2), size: 12),
                    const SizedBox(width: 8),
                    Text('Search brokers...',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('UNIVERSAL',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showPaperTradingDialog();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1A1721),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                      color: gold.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4)),
                                  alignment: Alignment.center,
                                  child: const Text('PA',
                                      style: TextStyle(
                                          color: gold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9))),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Paper Trading',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('Virtual • Live',
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            fontSize: 9)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1A1721),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(4)),
                                  alignment: Alignment.center,
                                  child: const Text('CS',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9))),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CSV Upload',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('Import MT5/4',
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            fontSize: 9)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showPaperTradingDialog() {
    final TextEditingController balanceController =
        TextEditingController(text: '100000');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF131118),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PAPER TRADING SIMULATOR',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8)),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(Icons.close,
                            color: Colors.white.withOpacity(0.15), size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('STARTING BALANCE',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A1721),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                      borderRadius: BorderRadius.circular(4)),
                  child: TextField(
                    controller: balanceController,
                    autofocus: true,
                    style: const TextStyle(
                        color: gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  double current =
                                      double.tryParse(balanceController.text) ??
                                          0;
                                  balanceController.text =
                                      (current + 1000).toInt().toString();
                                },
                                child: const Icon(Icons.keyboard_arrow_up,
                                    color: gold, size: 16),
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  double current =
                                      double.tryParse(balanceController.text) ??
                                          0;
                                  if (current >= 1000) {
                                    balanceController.text =
                                        (current - 1000).toInt().toString();
                                  }
                                },
                                child: const Icon(Icons.keyboard_arrow_down,
                                    color: gold, size: 16),
                              ),
                            ),
                          ],
                        ),
                        hintText: 'Enter balance...',
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.08))),
                    cursorColor: gold,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.06)),
                                borderRadius: BorderRadius.circular(6)),
                            alignment: Alignment.center,
                            child: const Text('CANCEL',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPaperConnected = true;
                              _paperBalance =
                                  double.tryParse(balanceController.text) ??
                                      100000;
                            });
                            Navigator.pop(ctx);
                            _showSuccessSnackBar();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: gold,
                                borderRadius: BorderRadius.circular(6)),
                            alignment: Alignment.center,
                            child: const Text('START TRADING',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isDark(context) ? const Color(0xFF0C1B10) : const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(
          side: BorderSide(color: isDark(context) ? const Color(0xFF00FF66) : const Color(0xFF2E7D32)),
          borderRadius: BorderRadius.circular(8)),
      content: Row(
        children: [
          Icon(Icons.check_circle, 
               color: isDark(context) ? const Color(0xFF00FF66) : const Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paper Account Created!',
                  style: TextStyle(
                      color: isDark(context) ? Colors.white : Colors.black, 
                      fontWeight: FontWeight.bold)),
              Text('Starting balance: USD 100,000',
                  style: TextStyle(
                      color: isDark(context) ? Colors.white70 : Colors.black54, 
                      fontSize: 12)),
            ],
          )
        ],
      ),
    ));
  }

  void _showModifyDialog(Map<String, dynamic> pos) {
    double tempSl = double.tryParse(pos['sl']) ?? 50.0;
    double tempTp = double.tryParse(pos['tp']) ?? 100.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF131118),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('MODIFY TRADE: ${pos['id']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Icon(Icons.close,
                                color: Colors.white.withOpacity(0.2), size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _customSliderRow('STOP LOSS', '${tempSl.toInt()} pips',
                        const Color(0xFFFF4D4D), tempSl, (v) {
                      setDialogState(() => tempSl = v);
                    }),
                    const SizedBox(height: 20),
                    _customSliderRow(
                        'TAKE PROFIT', '${tempTp.toInt()} pips', gold, tempTp,
                        (v) {
                      setDialogState(() => tempTp = v);
                    }),
                    const SizedBox(height: 32),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            pos['sl'] = tempSl.toStringAsFixed(2);
                            pos['tp'] = tempTp.toStringAsFixed(2);
                          });
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              color: gold,
                              borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: const Text('SAVE CHANGES',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCloseDialog(Map<String, dynamic> pos) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF131118),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Close Position',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close,
                          color: themeTextDim(context).withOpacity(0.2),
                          size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1721).withOpacity(0.5),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text('SYMBOL',
                                style: TextStyle(
                                    color:
                                        themeTextDim(context).withOpacity(0.2),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900))),
                        Expanded(
                            child: Text('LOT',
                                style: TextStyle(
                                    color:
                                        themeTextDim(context).withOpacity(0.2),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900))),
                        Expanded(
                            child: Text('FLOAT P&L',
                                style: TextStyle(
                                    color:
                                        themeTextDim(context).withOpacity(0.2),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                            child: Text(pos['symbol'],
                                style: const TextStyle(
                                    color: gold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900))),
                        Expanded(
                            child: Text(pos['lot'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900))),
                        Expanded(
                            child: Text(
                                '${pos['pnl'].toString().startsWith('+')
                                        ? ''
                                        : '-'}\$${pos['pnl'].toString().replaceAll('+', '').replaceAll('-', '')}',
                                style: TextStyle(
                                    color: pos['isUp']
                                        ? const Color(0xFF00FF66)
                                        : const Color(0xFFFF4D4D),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Close ${pos['id']} at market price? Irreversible.',
                style: TextStyle(
                    color: themeTextDim(context).withOpacity(0.3),
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.06)),
                              borderRadius: BorderRadius.circular(6)),
                          alignment: Alignment.center,
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          _closePosition(pos);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF231012),
                              border: Border.all(
                                  color:
                                      const Color(0xFFFF4D4D).withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(6)),
                          alignment: Alignment.center,
                          child: const Text('Close at Market',
                              style: TextStyle(
                                  color: Color(0xFFFF4D4D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDisconnectPaperDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF131118),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF4D4D), size: 40),
              const SizedBox(height: 20),
              const Text('Disconnect Account?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                  'This will close all active paper positions and reset your simulator state. Are you sure?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                   Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPaperConnected = false;
                            _openPositions.clear();
                          });
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: const Color(0xFF231012),
                              border: Border.all(
                                  color:
                                      const Color(0xFFFF4D4D).withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: const Text('Disconnect',
                              style: TextStyle(
                                  color: Color(0xFFFF4D4D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _executeTrade() {
    String type = _selectedOrderType;
    if (!_isPaperConnected) {
      _showBrokerDialog(context);
      return;
    }
    setState(() {
      _openPositions.add({
        'id': '#P${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'type': type,
        'symbol': 'XAUUSD',
        'lot': _selectedLot,
        'openPrice': '4557.20',
        'current': '4554.10',
        'sl': _stopLoss.toStringAsFixed(2),
        'tp': _takeProfit.toStringAsFixed(2),
        'pnl': type == 'BUY' ? '+15.20' : '-12.00',
        'duration': '1m',
        'isUp': type == 'BUY',
      });
      _positionsTabIndex = 0; // jump to Open Positions tab
    });

    // Auto-scroll up to the top of the trading section to show positions smoothly
    _mainScrollController.animateTo(
      0, // Scroll to top where the positions list is visible
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOutQuart,
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: gold,
      duration: const Duration(seconds: 2),
      content: Row(
        children: [
          const Icon(Icons.bolt, color: gold),
          const SizedBox(width: 12),
          Text('Trade Executed!',
              style: TextStyle(
                  color: isDark(context) ? Colors.white : Colors.black, 
                  fontWeight: FontWeight.bold)),
        ],
      ),
    ));
  }

  void _closePosition(Map<String, dynamic> pos) {
    setState(() {
      _openPositions.remove(pos);
      // create history map based on pos
      final closedPos = Map<String, dynamic>.from(pos);
      closedPos['closePrice'] = closedPos['current'];
      _history.add(closedPos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _mainScrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildMarketWatch(),
        const SizedBox(height: 16),
        _buildSignals(),
        const SizedBox(height: 16),
        _buildAIAlerts(),
        const SizedBox(height: 24),
        _buildChartSection(),
        const SizedBox(height: 24),
        _buildExecuteTrade(),
      ],
    );
  }

  Widget _buildMarketWatch() {
    return Container(
      decoration: BoxDecoration(
        color: themeSurface(context),
        border: Border.all(color: themeBorder(context)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.diamond, color: gold, size: 14),
                    SizedBox(width: 8),
                    Text('MARKET WATCH',
                        style: TextStyle(
                            color: gold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAddSymbolDialog,
                    borderRadius: BorderRadius.circular(4),
                    hoverColor: gold.withOpacity(0.05),
                    splashColor: gold.withOpacity(0.1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: border.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('+ ADD',
                          style: TextStyle(
                              color: gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: border),
          ..._marketWatchItems.map((item) => _marketWatchItem(
                item['label'],
                item['color'],
                item['pair'],
                item['price'],
                item['change'],
                item['isUp'],
              )),
        ],
      ),
    );
  }

  Widget _marketWatchItem(String label, Color avatarColor, String pair,
      String price, String change, bool isUp) {
    final color = isUp ? const Color(0xFF00FF66) : const Color(0xFFFF0033);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeSection(context), // slightly elevated background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration:
                    BoxDecoration(color: avatarColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(label,
                    style: TextStyle(
                        color: themeText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text(pair,
                  style: TextStyle(
                      color: themeText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: TextStyle(
                      color: themeText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(change, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignals() {
    final signalsAsync = ref.watch(signalsProvider);

    return signalsAsync.when(
      data: (signals) {
        final List<Map<String, dynamic>> mappedSignals = [];
        for (int i = 0; i < signals.length; i++) {
          final s = signals[i];
          mappedSignals.add({
            'index': i,
            'type': s.type ?? 'BUY',
            'pair': s.pair ?? '--',
            'conf': s.confidence > 80 ? 'HIGH' : s.confidence > 60 ? 'MEDIUM' : 'LOW',
            'confidenceRaw': s.confidence,
            'previewColor': s.type == 'BUY' ? const Color(0xFF00FF66) : const Color(0xFFFF0033),
            'status': s.status ?? 'ACTIVE',
            'headline': s.headline ?? '',
            'result': s.result ?? '--',
            'pips': s.pips ?? '--',
            'isExpanded': _expandedSignalIndices.contains(i),
            'isVerified': true,
          });
        }

        final filteredSignals = mappedSignals.where((s) {
          if (_selectedSignalTab == 'ALL') return true;
          if (_selectedSignalTab == 'BUY') return s['type'] == 'BUY';
          if (_selectedSignalTab == 'SELL') return s['type'] == 'SELL';
          if (_selectedSignalTab == 'ACTIVE') return s['status'] == 'ACTIVE';
          return true;
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: themeSurface(context),
            border: Border.all(color: themeBorder(context)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: gold, width: 2))),
                  const SizedBox(width: 8),
                  Text('SIGNALS',
                      style: TextStyle(
                          color: themeText(context),
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  const Icon(Icons.verified, color: gold, size: 14),
                  const SizedBox(width: 4),
                  const Text('API VERIFIED', style: TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _badge('${mappedSignals.length} TOTAL', Colors.white24),
                  const SizedBox(width: 4),
                  _badge(
                      '${mappedSignals.where((s) => s['status'] == 'ACTIVE').length} ACTIVE',
                      Colors.white24),
                  const SizedBox(width: 4),
                  _badge(
                      '${mappedSignals.where((s) => s['status'] == 'PASSED').length} PASSED',
                      const Color(0xFF00FF66)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _signalTab('ALL'),
                  _signalTab('BUY'),
                  _signalTab('SELL'),
                  _signalTab('ACTIVE'),
                ],
              ),
              const SizedBox(height: 16),
              ...filteredSignals.map((s) => _signalRow(s)),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 300,
        decoration: BoxDecoration(color: themeSurface(context), border: Border.all(color: themeBorder(context))),
        child: const Center(child: CircularProgressIndicator(color: gold)),
      ),
      error: (e, stack) => Container(
        height: 100,
        decoration: BoxDecoration(color: themeSurface(context), border: Border.all(color: themeBorder(context))),
        child: const Center(child: Text('SIGNAL ENGINE ERROR', style: TextStyle(color: Colors.redAccent, fontSize: 10))),
      ),
    );
  }

  Widget _badge(String text, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: borderColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text, style: TextStyle(color: borderColor, fontSize: 9)),
    );
  }

  Widget _signalTab(String label) {
    bool isSelected = _selectedSignalTab == label;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _selectedSignalTab = label),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? gold : border),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    color: isSelected ? gold : themeTextDim(context),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _signalRow(Map<String, dynamic> signal) {
    final String type = signal['type']?.toString() ?? 'BUY';
    final String pair = signal['pair']?.toString() ?? '--';
    final String conf = signal['conf']?.toString() ?? 'MEDIUM';
    final String status = signal['status']?.toString() ?? 'ACTIVE';
    final Color typeColor = signal['previewColor'] as Color? ?? gold;
    final bool isExpanded = signal['isExpanded'] == true;
    final bool isPassed = status == 'PASSED';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    final int idx = signal['index'];
                    if (_expandedSignalIndices.contains(idx)) {
                      _expandedSignalIndices.remove(idx);
                    } else {
                      _expandedSignalIndices.add(idx);
                    }
                  });
                },
                hoverColor: gold.withOpacity(0.02),
                splashColor: gold.withOpacity(0.05),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? gold.withOpacity(0.02)
                        : Colors.transparent,
                    border: isExpanded
                        ? const Border(left: BorderSide(color: gold, width: 2))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                border: Border.all(
                                    color: typeColor.withOpacity(0.5))),
                            child: Text(type,
                                style: TextStyle(
                                    color: typeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Text(pair,
                              style: TextStyle(
                                  color: themeText(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                border: Border.all(
                                    color: typeColor.withOpacity(0.5))),
                            child: Text(conf,
                                style: TextStyle(
                                    color: typeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: isPassed ? const Color(0xFF00FF66).withOpacity(0.1) : gold.withOpacity(0.1),
                                border: Border.all(color: isPassed ? const Color(0xFF00FF66).withOpacity(0.5) : gold.withOpacity(0.5))),
                            child: Text(status,
                                style: TextStyle(
                                    color: isPassed ? const Color(0xFF00FF66) : gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeBg(context),
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _signalDetailBox('RESULT', signal['result'] ?? 'TP2',
                            const Color(0xFF00FF66),
                            isDoubleCheck: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _signalDetailBox(
                            'PIPS', signal['pips'] ?? '+80', Colors.white,
                            isYellow: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('View full detail →',
                          style: TextStyle(
                              color: themeTextDim(context).withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _signalDetailBox(String label, String value, Color valueColor,
      {bool isDoubleCheck = false, bool isYellow = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: themeSection(context),
        border: Border.all(color: themeBorder(context).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: themeTextDim(context).withOpacity(0.3), fontSize: 9)),
          Row(
            children: [
              if (isDoubleCheck) ...[
                const Text('✓✓ ',
                    style: TextStyle(
                        color: Color(0xFF00FF66),
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAlerts() {
    return Container(
      decoration: BoxDecoration(
          color: themeSurface(context), border: Border.all(color: themeBorder(context))),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.electric_bolt, color: gold, size: 16),
              SizedBox(width: 8),
              Text('AI ALERTS',
                  style: TextStyle(
                      color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0033).withOpacity(0.05),
              border:
                  Border.all(color: const Color(0xFFFF0033).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenge pattern detected',
                    style: TextStyle(
                        color: Color(0xFFFF0033),
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('04:41',
                    style: TextStyle(color: themeTextDim(context), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      decoration: BoxDecoration(
          color: themeSurface(context), border: Border.all(color: themeBorder(context))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, color: gold, size: 10),
                    const SizedBox(width: 8),
                    Text('XAU/USD',
                        style: TextStyle(
                            color: themeText(context),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('PRICING',
                        style: TextStyle(color: themeTextDim(context), fontSize: 9)),
                    const SizedBox(height: 4),
                    const Text('– 0.00%',
                        style: TextStyle(
                            color: Color(0xFF00FF66),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: border),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _chartTab('1m', true),
                    _chartTab('5m', false),
                    _chartTab('15m', false),
                    _chartTab('1H', false),
                    _chartTab('4H', false),
                    _chartTab('1D', false),
                  ],
                ),
                  Row(
                    children: [
                      Text('SPREAD —',
                          style: TextStyle(color: themeTextDim(context), fontSize: 10)),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, color: Color(0xFF00FF66), size: 8),
                      const SizedBox(width: 4),
                      const Text('LIVE',
                          style: TextStyle(
                              color: Color(0xFF00FF66),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            height: 300,
            color: themeBg(context),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 24, bottom: 44, right: 12),
                  child: LiveCandleChart(symbol: 'EUR/USD'),
                ),
                Positioned(
                  right: 12,
                  top: 40,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: const Color(0xFF00FF66).withOpacity(0.2),
                    child: const Text('4,429.915',
                        style: TextStyle(
                            color: Color(0xFF00FF66),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 40,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: const Color(0xFF00FF66).withOpacity(0.2),
                    child: const Text('1.14K',
                        style: TextStyle(
                            color: Color(0xFF00FF66),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: border),
          // Chart Bottom Tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _bottomTab('OPEN POSITIONS', 0,
                        badge: _openPositions.length.toString()),
                    const SizedBox(width: 24),
                    _bottomTab('HISTORY', 1),
                    const SizedBox(width: 24),
                    _bottomTab('PENDING ORDERS', 2),
                  ],
                ),
                Row(
                  children: [
                    _filterTab('ALL', true),
                    _filterTab('BUY', false),
                    _filterTab('SELL', false),
                  ],
                ),
              ],
            ),
          ),
          _buildPositionsList(),
        ],
      ),
    );
  }

  Widget _chartTab(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(
              color: active ? const Color(0xFF00FF66) : Colors.transparent)),
      child: Text(text,
          style: TextStyle(
              color: active ? const Color(0xFF00FF66) : themeTextDim(context),
              fontSize: 11)),
    );
  }

  Widget _filterTab(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(border: Border.all(color: active ? gold : border)),
      child: Text(text,
          style:
              TextStyle(color: active ? gold : themeTextDim(context), fontSize: 10)),
    );
  }

  Widget _buildExecuteTrade() {
    return Container(
      decoration: BoxDecoration(
          color: themeSurface(context), border: Border.all(color: themeBorder(context))),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.electric_bolt, color: gold, size: 16),
              SizedBox(width: 8),
              Text('EXECUTE TRADE',
                  style: TextStyle(
                      color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: themeBg(context),
                borderRadius: BorderRadius.circular(12)),
            child: _isPaperConnected
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.circle,
                                  color: Color(0xFF00FF66), size: 8),
                              const SizedBox(width: 8),
                              Text('PAPER TRADING',
                                  style: TextStyle(
                                      color: themeTextDim(context),
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _showDisconnectPaperDialog,
                              child: Icon(Icons.logout,
                                  color: themeTextDim(context).withOpacity(0.5),
                                  size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('DTrade Paper®',
                          style: TextStyle(
                              color: themeText(context),
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Balance: \$${_paperBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: gold,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.electric_bolt,
                              color: Color(0xFFFF0033), size: 12),
                          const SizedBox(width: 8),
                          Text('NO MT5 CONNECTED',
                              style: TextStyle(
                                  color: themeTextDim(context),
                                  fontSize: 11,
                                  letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _showBrokerDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                border: Border.all(color: border)),
                            child: Text('+ ADD ACCOUNT',
                                style: TextStyle(
                                    color: themeTextDim(context), fontSize: 10)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _selectedOrderType == 'BUY'
                      ? const Color(0xFF00FF66)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    onTap: () => setState(() => _selectedOrderType = 'BUY'),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: _selectedOrderType == 'BUY'
                                  ? Colors.transparent
                                  : const Color(0xFF00FF66).withOpacity(0.3),
                              width: 1.5),
                          borderRadius: BorderRadius.circular(4)),
                      alignment: Alignment.center,
                      child: Text('▲ BUY',
                          style: TextStyle(
                              color: _selectedOrderType == 'BUY'
                                  ? Colors.black
                                  : const Color(0xFF00FF66),
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Material(
                  color: _selectedOrderType == 'SELL'
                      ? const Color(0xFFFF0033)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    onTap: () => setState(() => _selectedOrderType = 'SELL'),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: _selectedOrderType == 'SELL'
                                  ? Colors.transparent
                                  : const Color(0xFFFF0033).withOpacity(0.3),
                              width: 1.5),
                          borderRadius: BorderRadius.circular(4)),
                      alignment: Alignment.center,
                      child: Text('▼ SELL',
                          style: TextStyle(
                              color: _selectedOrderType == 'SELL'
                                  ? Colors.black
                                  : const Color(0xFFFF0033),
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LOT SIZE',
                  style: TextStyle(
                      color: themeTextDim(context), fontSize: 10, letterSpacing: 1.5)),
              Text(_selectedLot,
                  style: const TextStyle(
                      color: gold, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _lotSizeBox('0.01'),
              _lotSizeBox('0.05'),
              _lotSizeBox('0.1'),
              _lotSizeBox('0.2'),
              _lotSizeBox('0.3'),
              _lotSizeBox('0.5'),
              _lotSizeBox('1'),
              _lotSizeBox('2'),
            ],
          ),
          const SizedBox(height: 32),
          _customSliderRow(
              'STOP LOSS',
              '${_stopLoss.toInt()} pips',
              const Color(0xFFFF0033),
              _stopLoss,
              (v) => setState(() => _stopLoss = v)),
          const SizedBox(height: 24),
          _customSliderRow('TAKE PROFIT', '${_takeProfit.toInt()} pips', gold,
              _takeProfit, (v) => setState(() => _takeProfit = v)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
                color: themeBg(context),
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(children: [
                  Text('RISK',
                      style: TextStyle(color: themeTextDim(context), fontSize: 10)),
                  const SizedBox(height: 8),
                  const Text('0.0%',
                      style: TextStyle(
                          color: Color(0xFFFF0033),
                          fontSize: 13,
                          fontWeight: FontWeight.bold))
                ]),
                Column(children: [
                  Text('REWARD',
                      style: TextStyle(color: themeTextDim(context), fontSize: 10)),
                  const SizedBox(height: 8),
                  Text('0.0%',
                      style: TextStyle(
                          color: themeText(context),
                          fontSize: 13,
                          fontWeight: FontWeight.bold))
                ]),
                Column(children: [
                  Text('RATIO',
                      style: TextStyle(color: themeTextDim(context), fontSize: 10)),
                  const SizedBox(height: 8),
                  const Text('1:2.0',
                      style: TextStyle(
                          color: gold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold))
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.circle, color: gold, size: 8),
                const SizedBox(width: 8),
                Text('NEURAL ANALYSIS',
                    style: TextStyle(
                        color: themeTextDim(context), fontSize: 10, letterSpacing: 1))
              ]),
              Text('INACTIVE',
                  style: TextStyle(color: themeTextDim(context).withOpacity(0.5), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 32),
          Material(
            color: gold,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: _executeTrade,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: const Text('EXECUTE TRADE',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lotSizeBox(String size) {
    final active = _selectedLot == size;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedLot = size),
        child: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: themeSection(context),
              border: Border.all(color: active ? gold : themeBorder(context)),
              borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: Text(size,
              style: TextStyle(
                  color: active ? gold : themeTextDim(context),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _customSliderRow(String label, String value, Color activeColor,
      double currentVal, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: themeTextDim(context), fontSize: 10, letterSpacing: 1.5)),
            Text(value,
                style: TextStyle(
                    color: activeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbColor: Colors.blueAccent,
            activeTrackColor: activeColor,
            inactiveTrackColor: border,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
              value: currentVal, min: 0.0, max: 1000.0, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _bottomTab(String title, int index, {String? badge}) {
    final active = _positionsTabIndex == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _positionsTabIndex = index),
        child: Column(
          children: [
            Row(
              children: [
                Text(title,
                    style: TextStyle(
                        color: active ? gold : themeTextDim(context),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: active ? gold : themeTextDim(context))),
                      child: Text(badge,
                          style: TextStyle(
                              color: active ? gold : themeTextDim(context),
                              fontSize: 9))),
                ]
              ],
            ),
            const SizedBox(height: 6),
            Container(height: 2, width: active ? 100 : 0, color: gold),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionsList() {
    if (_positionsTabIndex == 0) {
      if (_openPositions.isEmpty) {
        return Column(
          children: [
            const SizedBox(height: 32),
            Text('NO OPEN POSITIONS',
                style: TextStyle(
                    color: themeTextDim(context).withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('SELECT AN ACCOUNT TO BEGIN',
                style: TextStyle(
                    color: themeTextDim(context).withOpacity(0.3), fontSize: 9, letterSpacing: 1)),
            const SizedBox(height: 48),
          ],
        );
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 860, // Fixed width to accommodate all columns (824px) + padding
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _tableHeader('SYMBOL', width: 150),
                    _tableHeader('TYPE', width: 60),
                    _tableHeader('LOT', width: 60),
                    _tableHeader('OPEN', width: 80),
                    _tableHeader('CURRENT', width: 80),
                    _tableHeader('SL', width: 60),
                    _tableHeader('TP', width: 60),
                    _tableHeader('P&L', width: 80),
                    _tableHeader('DUR', width: 60),
                    SizedBox(
                        width: 130,
                        child: Text('ACTIONS',
                            style: TextStyle(
                                color: themeTextDim(context), fontSize: 9),
                            textAlign: TextAlign.right)),
                  ],
                ),
              ),
              Container(height: 1, color: border),
              ..._openPositions.map((pos) => _positionRow(pos)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } else if (_positionsTabIndex == 1) {
      if (_history.isEmpty) {
        return const Column(
          children: [
            SizedBox(height: 32),
            Text('NO HISTORY',
                style: TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            SizedBox(height: 48),
          ],
        );
      }
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('SYMBOL',
                        style: TextStyle(color: themeTextDim(context), fontSize: 9))),
                Expanded(
                    child: Text('TYPE',
                        style: TextStyle(color: themeTextDim(context), fontSize: 9))),
                Expanded(
                    child: Text('LOT',
                        style: TextStyle(color: themeTextDim(context), fontSize: 9))),
                Expanded(
                    child: Text('OPEN PRICE',
                        style: TextStyle(color: themeTextDim(context), fontSize: 9))),
                Expanded(
                    child: Text('CLOSE PRICE',
                        style: TextStyle(color: themeTextDim(context), fontSize: 9))),
                Expanded(
                    child: Text('P&L',
                        style: TextStyle(color: themeTextDim(context), fontSize: 9))),
                const SizedBox(width: 120),
              ],
            ),
          ),
          Container(height: 1, color: border),
          ..._history.map((pos) => _historyRow(pos)),
          const SizedBox(height: 16),
        ],
      );
    } else {
      return const Column(
        children: [
          SizedBox(height: 32),
          Text('NO PENDING ORDERS',
              style: TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          SizedBox(height: 48),
        ],
      );
    }
  }

  Widget _positionRow(Map<String, dynamic> pos) {
    Color typeColor = pos['type'] == 'BUY'
        ? const Color(0xFF00FF66)
        : const Color(0xFFFF0033);
    Color pnlColor =
        pos['isUp'] ? const Color(0xFF00FF66) : const Color(0xFFFF0033);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: border))),
      child: Row(
        children: [
          SizedBox(
              width: 150,
              child: Row(
                children: [
                  Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: Colors.white12, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('XA',
                          style: TextStyle(
                              color: themeText(context),
                              fontSize: 10,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pos['symbol'],
                          style: TextStyle(
                              color: themeText(context),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      Text(pos['id'],
                          style: TextStyle(
                              color: themeTextDim(context), fontSize: 9)),
                    ],
                  )
                ],
              )),
          SizedBox(
              width: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    border: Border.all(color: typeColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(pos['type'],
                    style: TextStyle(color: typeColor, fontSize: 9),
                    textAlign: TextAlign.center),
              )),
          SizedBox(
              width: 60,
              child: Text(pos['lot'],
                  style: TextStyle(color: themeText(context), fontSize: 11),
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 80,
              child: Text(pos['openPrice'],
                  style: TextStyle(color: themeText(context), fontSize: 11),
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 80,
              child: Text(pos['current'],
                  style: TextStyle(color: themeTextDim(context), fontSize: 11),
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 60,
              child: Text(pos['sl'],
                  style: TextStyle(color: themeTextDim(context), fontSize: 11),
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 60,
              child: Text(pos['tp'],
                  style: TextStyle(color: themeTextDim(context), fontSize: 11),
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 80,
              child: Text(pos['pnl'],
                  style: TextStyle(
                      color: pnlColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 60,
              child: Text(pos['duration'],
                  style: TextStyle(color: themeTextDim(context), fontSize: 11),
                  textAlign: TextAlign.center)),
          SizedBox(
              width: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showModifyDialog(pos),
                      child: const Text('modify',
                          style: TextStyle(
                              color: Colors.blueAccent, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showCloseDialog(pos),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                    const Color(0xFFFF0033).withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('close',
                            style: TextStyle(
                                color: Color(0xFFFF0033), fontSize: 11)),
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _tableHeader(String title, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(title,
          style: TextStyle(color: themeTextDim(context), fontSize: 9),
          textAlign: TextAlign.center),
    );
  }

  Widget _historyRow(Map<String, dynamic> pos) {
    Color typeColor = pos['type'] == 'BUY'
        ? const Color(0xFF00FF66)
        : const Color(0xFFFF0033);
    Color pnlColor =
        pos['isUp'] ? const Color(0xFF00FF66) : const Color(0xFFFF0033);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: border))),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: Colors.white12, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('XA',
                          style: TextStyle(
                              color: themeText(context),
                              fontSize: 10,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pos['symbol'],
                          style: TextStyle(
                              color: themeText(context),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      Text(pos['id'],
                          style: TextStyle(
                              color: themeTextDim(context), fontSize: 9)),
                    ],
                  )
                ],
              )),
          Expanded(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                border: Border.all(color: typeColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4)),
            child: Text(pos['type'],
                style: TextStyle(color: typeColor, fontSize: 9),
                textAlign: TextAlign.center),
          )),
          Expanded(
              child: Text(pos['lot'],
                  style: TextStyle(color: themeText(context), fontSize: 11))),
          Expanded(
              child: Text(pos['openPrice'],
                  style: TextStyle(color: themeText(context), fontSize: 11))),
          Expanded(
              child: Text(pos['closePrice'],
                  style: TextStyle(color: themeText(context), fontSize: 11))),
          Expanded(
              child: Text(pos['pnl'],
                  style: TextStyle(
                      color: pnlColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 120),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }
}
