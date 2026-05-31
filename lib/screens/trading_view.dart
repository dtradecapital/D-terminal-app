import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/shared.dart';
import '../widgets/live_candle_chart.dart';
import '../services/intelligence_service.dart';
import '../services/market_service.dart';

class TradingView extends ConsumerStatefulWidget {
  const TradingView({super.key});

  @override
  ConsumerState<TradingView> createState() => _TradingViewState();
}

class _TradingViewState extends ConsumerState<TradingView> {
  final ScrollController _mainScrollController = ScrollController();
  
  // Selected trading symbol context
  String _selectedSymbol = 'XAU/USD';
  
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
  String _selectedBiasTimeframe = 'H1';

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
    {
      'label': 'XA',
      'color': Colors.amber,
      'pair': 'XAU/USD',
      'price': '2350.25',
      'change': '+0.54%',
      'isUp': true
    }
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

  @override
  void initState() {
    super.initState();
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
            backgroundColor: const Color(0xFF0C0C0C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: border),
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
                      Text('ADD SYMBOL',
                          style: monoStyle(
                              color: gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close,
                            color: Colors.white38, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      border: Border.all(color: gold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      onChanged: (v) => setDialogState(() => searchQuery = v),
                      style: monoStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search pairs...',
                        hintStyle: monoStyle(color: Colors.white24, fontSize: 13),
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
                              style: monoStyle(
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
        backgroundColor: const Color(0xFF0C0C0C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TRADE WITH YOUR BROKER',
                      style: monoStyle(
                          color: gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close,
                          color: Colors.white38, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Connect your broker account to begin live execution',
                  style: textStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    const Icon(Icons.search,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 8),
                    Text('Search brokers...',
                        style: textStyle(color: Colors.white24, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('UNIVERSAL SIMULATOR',
                  style: monoStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
              const SizedBox(height: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPaperTradingDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: gold.withOpacity(0.1),
                                border: Border.all(color: gold.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(4)),
                            alignment: Alignment.center,
                            child: Text('PA',
                                style: monoStyle(
                                    color: gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Paper Trading Simulator',
                                  style: textStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Virtual demo account with \$100k balance',
                                  style: textStyle(
                                      color: Colors.white38,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
          backgroundColor: const Color(0xFF0C0C0C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: border),
          ),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PAPER TRADING SIMULATOR',
                        style: monoStyle(
                            color: gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8)),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close,
                            color: Colors.white38, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('STARTING BALANCE',
                    style: monoStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(4)),
                  child: TextField(
                    controller: balanceController,
                    autofocus: true,
                    style: monoStyle(
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
                        hintStyle: monoStyle(
                            color: Colors.white24, fontSize: 13)),
                    cursorColor: gold,
                    keyboardType: TextInputType.number,
                  ),
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
                                border: Border.all(color: border),
                                borderRadius: BorderRadius.circular(4)),
                            alignment: Alignment.center,
                            child: Text('CANCEL',
                                style: monoStyle(
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
                                borderRadius: BorderRadius.circular(4)),
                            alignment: Alignment.center,
                            child: Text('START TRADING',
                                style: monoStyle(
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
      backgroundColor: const Color(0xFF0C1B10),
      shape: RoundedRectangleBorder(
          side: const BorderSide(color: buyGreen),
          borderRadius: BorderRadius.circular(6)),
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: buyGreen),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paper Account Created!',
                  style: textStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Starting balance: USD 100,000',
                  style: textStyle(color: Colors.white70, fontSize: 11)),
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
              backgroundColor: const Color(0xFF0C0C0C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: border),
              ),
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('MODIFY TRADE: ${pos['id']}',
                            style: monoStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(Icons.close,
                                color: Colors.white38, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _customSliderRow('STOP LOSS', '${tempSl.toInt()} pips',
                        sellRed, tempSl, (v) {
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: gold,
                              borderRadius: BorderRadius.circular(4)),
                          alignment: Alignment.center,
                          child: Text('SAVE CHANGES',
                              style: monoStyle(
                                  color: Colors.black,
                                  fontSize: 12,
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
        backgroundColor: const Color(0xFF0C0C0C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Close Position',
                      style: textStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close,
                          color: Colors.white38,
                          size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(6)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text('SYMBOL',
                                style: monoStyle(
                                    color: Colors.white38,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            child: Text('LOTS',
                                style: monoStyle(
                                    color: Colors.white38,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            child: Text('FLOAT P&L',
                                style: monoStyle(
                                    color: Colors.white38,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                            child: Text(pos['symbol'],
                                style: monoStyle(
                                    color: gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            child: Text(pos['lot'],
                                style: monoStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            child: Text(
                                '${pos['pnl'].toString().startsWith('+') ? '' : '-'}\$${pos['pnl'].toString().replaceAll('+', '').replaceAll('-', '')}',
                                style: monoStyle(
                                    color: pos['isUp'] ? buyGreen : sellRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Close ${pos['id']} at current market price? This action is irreversible.',
                style: textStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    height: 1.4),
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
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(4)),
                          alignment: Alignment.center,
                          child: Text('Cancel',
                              style: textStyle(
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
                              color: const Color(0xFF1E0C0C),
                              border: Border.all(color: sellRed.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(4)),
                          alignment: Alignment.center,
                          child: Text('Close Order',
                              style: textStyle(
                                  color: sellRed,
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
        backgroundColor: const Color(0xFF0C0C0C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: sellRed, size: 40),
              const SizedBox(height: 16),
              Text('Disconnect Account?',
                  style: textStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                  'Disconnecting will close active paper simulation positions and wipe current balance. Reset simulator?',
                  textAlign: TextAlign.center,
                  style: textStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      height: 1.4)),
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
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(4)),
                          alignment: Alignment.center,
                          child: Text('Cancel',
                              style: textStyle(
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
                          setState(() {
                            _isPaperConnected = false;
                            _openPositions.clear();
                          });
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1E0C0C),
                              border: Border.all(color: sellRed.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(4)),
                          alignment: Alignment.center,
                          child: Text('Disconnect',
                              style: textStyle(
                                  color: sellRed,
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

  void _executeTrade() {
    String type = _selectedOrderType;
    if (!_isPaperConnected) {
      _showBrokerDialog(context);
      return;
    }
    
    final priceStr = _marketWatchItems.firstWhere((x) => x['pair'] == _selectedSymbol, orElse: () => {'price': '1.0000'})['price'];

    setState(() {
      _openPositions.add({
        'id': '#P${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'type': type,
        'symbol': _selectedSymbol.replaceAll('/', ''),
        'lot': _selectedLot,
        'openPrice': priceStr,
        'current': priceStr,
        'sl': _stopLoss.toStringAsFixed(1),
        'tp': _takeProfit.toStringAsFixed(1),
        'pnl': type == 'BUY' ? '+12.50' : '-9.00',
        'duration': '1m',
        'isUp': type == 'BUY',
      });
      _positionsTabIndex = 0; // Show Open Positions Tab
    });

    _mainScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF0C1B10),
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: buyGreen),
        borderRadius: BorderRadius.circular(6),
      ),
      content: Row(
        children: [
          const Icon(Icons.bolt, color: buyGreen),
          const SizedBox(width: 12),
          Text('Executed $type $_selectedLot Lot $_selectedSymbol',
              style: textStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold)),
        ],
      ),
    ));
  }

  void _closePosition(Map<String, dynamic> pos) {
    setState(() {
      _openPositions.remove(pos);
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
        const SizedBox(height: 16),
        _buildDirectionBias(),
        const SizedBox(height: 16),
        _buildChartSection(),
        const SizedBox(height: 16),
        _buildExecuteTrade(),
      ],
    );
  }

  Widget _buildMarketWatch() {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond_outlined, color: gold, size: 14),
                  const SizedBox(width: 6),
                  Text('MARKET WATCH', style: labelCaps(color: gold)),
                ],
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _showAddSymbolDialog,
                  child: Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: gold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+ ADD',
                      style: textStyle(fontSize: 9, color: gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 4),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _marketWatchItems.length,
            itemBuilder: (context, index) => _marketWatchItem(_marketWatchItems[index]),
          ),
        ],
      ),
    );
  }

  Widget _marketWatchItem(Map<String, dynamic> item) {
    final pair = item['pair'] as String;
    
    // Look up live data from market service
    final marketData = ref.watch(marketServiceProvider);
    final liveData = marketData[pair];

    final double price = liveData != null ? liveData.price : double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final double change = liveData != null ? liveData.change : double.tryParse(item['change']?.toString().replaceAll('%', '') ?? '0') ?? 0.0;
    final bool isUp = liveData != null ? liveData.isUp : item['isUp'] as bool;

    String flag = '🇪🇺🇺🇸';
    if (pair.startsWith('GBP')) flag = '🇬🇧🇺🇸';
    if (pair.startsWith('USD/JPY')) flag = '🇺🇸🇯🇵';
    if (pair.startsWith('USD/CHF')) flag = '🇺🇸🇨🇭';
    if (pair.startsWith('NZD')) flag = '🇳🇿🇺🇸';
    if (pair.startsWith('EUR/GBP')) flag = '🇪🇺🇬🇧';
    if (pair.startsWith('AUD')) flag = '🇦🇺🇺🇸';
    if (pair.startsWith('USD/CAD')) flag = '🇺🇸🇨🇦';
    if (pair.startsWith('XAU')) flag = '👑🇺🇸';
    if (pair.startsWith('BTC')) flag = '🪙🇺🇸';

    final isSelected = _selectedSymbol == pair;

    return LiveWatchItem(
      pair: pair,
      flag: flag,
      initialPrice: price,
      initialChange: change,
      initialIsUp: isUp,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _selectedSymbol = pair;
        });
      },
      onDismissed: () {
        setState(() {
          _marketWatchItems.removeWhere((x) => x['pair'] == pair);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E0C0C),
            content: Text('REMOVED $pair FROM WATCHLIST', style: monoStyle(fontSize: 10, color: sellRed)),
          ),
        );
      },
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
            'previewColor': s.type == 'BUY' ? buyGreen : sellRed,
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

        final activeCount = mappedSignals.where((s) => s['status'] == 'ACTIVE').length;
        final passedCount = mappedSignals.where((s) => s['status'] == 'PASSED').length;

        return SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, color: gold, size: 14),
                  const SizedBox(width: 6),
                  Text('SIGNALS', style: labelCaps(color: gold)),
                  const SizedBox(width: 6),
                  Text('API VERIFIED', style: textStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _badge('${mappedSignals.length} TOTAL', textMid),
                  const SizedBox(width: 4),
                  _badge('$activeCount ACTIVE', textMid),
                  const SizedBox(width: 4),
                  _badge('$passedCount PASSED', buyGreen),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _signalTab('ALL'),
                  const SizedBox(width: 4),
                  _signalTab('BUY'),
                  const SizedBox(width: 4),
                  _signalTab('SELL'),
                  const SizedBox(width: 4),
                  _signalTab('ACTIVE'),
                ],
              ),
              const SizedBox(height: 6),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSignals.length,
                itemBuilder: (context, index) => _signalRow(filteredSignals[index]),
              ),
            ],
          ),
        );
      },
      loading: () => SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonContainer(width: 80, height: 12),
                SkeletonContainer(width: 40, height: 12),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonContainer(width: double.infinity, height: 32),
            const SizedBox(height: 8),
            const SkeletonContainer(width: double.infinity, height: 32),
            const SizedBox(height: 8),
            const SkeletonContainer(width: double.infinity, height: 32),
          ],
        ),
      ),
      error: (e, stack) => Container(
        height: 60,
        decoration: BoxDecoration(color: themeSurface(context), border: Border.all(color: themeBorder(context)), borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text('SIGNAL ENGINE OFFLINE', style: monoStyle(color: sellRed, fontSize: 10))),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: textStyle(color: color, fontSize: 8, fontWeight: FontWeight.w600),
      ),
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
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? gold.withOpacity(0.08) : const Color(0xFF121212),
              border: Border.all(color: isSelected ? gold : borderFaint),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: textStyle(
                color: isSelected ? gold : textMid,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    final bool isExpanded = signal['isExpanded'] == true;
    final bool isPassed = status == 'PASSED';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  final int idx = signal['index'];
                  if (_expandedSignalIndices.contains(idx)) {
                    _expandedSignalIndices.remove(idx);
                  } else {
                    _expandedSignalIndices.add(idx);
                  }
                  _selectedSymbol = pair;
                  _selectedOrderType = type;
                  _stopLoss = 40.0;
                  _takeProfit = 90.0;
                });
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isExpanded ? const Color(0xFF141414) : const Color(0xFF0F0F0F),
                  border: Border.all(color: isExpanded ? gold.withOpacity(0.3) : borderFaint),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pair,
                      style: textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        if (isPassed)
                          const PassedChip()
                        else ...[
                          SignalBadge(type: type),
                          const SizedBox(width: 4),
                          ConfidencePill(level: conf),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF080808),
                border: Border.all(color: borderFaint, width: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TP1: ${signal['result'] ?? "1.0820"}',
                    style: monoStyle(fontSize: 11, color: textHigh, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'SL: ${signal['pips'] ?? "1.0690"}',
                    style: monoStyle(fontSize: 11, color: sellRed, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIAlerts() {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: criticalRed, size: 14),
              const SizedBox(width: 6),
              _RedPulseDot(),
              const SizedBox(width: 6),
              Text('AI COGNITIVE WARNING', style: labelCaps(color: criticalRed)),
              const Spacer(),
              Text(
                'CRITICAL',
                style: monoStyle(fontSize: 9, color: criticalRed, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF140809),
              border: Border.all(color: criticalRed.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenge trading pattern detected. User has closed 3 consecutive loss trades on $_selectedSymbol and is executing orders with 2x normal lot sizes.',
                  style: bodyMD(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ALGO TRIGGER: GENOME-ALPHA',
                      style: monoStyle(fontSize: 9, color: criticalRed, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '04:41:12 UTC',
                      style: monoStyle(fontSize: 9, color: textLow),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionBias() {
    final biases = ref.watch(directionBiasProvider);
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: gold, size: 14),
                  const SizedBox(width: 6),
                  Text('DIRECTION BIAS', style: labelCaps(color: gold)),
                ],
              ),
              Row(
                children: ['H1', 'H4', 'D1'].map((tf) {
                  final active = _selectedBiasTimeframe == tf;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedBiasTimeframe = tf),
                      child: Container(
                        height: 24,
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: active ? gold : const Color(0xFF121212),
                          border: Border.all(color: active ? gold : borderFaint),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tf,
                          style: textStyle(
                            color: active ? Colors.black : textMid,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 4),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: biases.length,
            separatorBuilder: (context, index) => const Divider(color: borderFaint, height: 1),
            itemBuilder: (context, index) {
              final bias = biases[index];
              final String currentBias = _selectedBiasTimeframe == 'H1'
                  ? bias.h1Bias
                  : _selectedBiasTimeframe == 'H4'
                      ? bias.h4Bias
                      : bias.d1Bias;

              // Compute timeframe-specific values to make the switcher alive!
              int confidenceVal = bias.confidence;
              int rsiVal = bias.rsi;
              if (_selectedBiasTimeframe == 'H4') {
                confidenceVal = (bias.confidence * 0.9).toInt();
                rsiVal = (bias.rsi * 0.95).toInt();
              } else if (_selectedBiasTimeframe == 'D1') {
                confidenceVal = (bias.confidence * 1.05).clamp(0, 100).toInt();
                rsiVal = (bias.rsi * 1.05).clamp(0, 100).toInt();
              }

              return SizedBox(
                height: 36,
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        bias.pair,
                        style: textStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    if (currentBias == 'NEUTRAL')
                      Container(
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'NEUTRAL',
                          style: monoStyle(color: textMid, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      SizedBox(
                        height: 18,
                        child: SignalBadge(type: currentBias == 'BULLISH' ? 'BUY' : 'SELL'),
                      ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$confidenceVal%',
                        style: monoStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: bgElevated,
                          borderRadius: BorderRadius.circular(1),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: confidenceVal / 100.0,
                          child: Container(color: gold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 44,
                      child: Text(
                        'RSI $rsiVal',
                        style: monoStyle(color: textMid, fontSize: 10),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final marketData = ref.watch(marketServiceProvider);
    final selectedPairData = marketData[_selectedSymbol];
    final currentPrice = selectedPairData?.price ?? 1.0724;
    final priceChange = selectedPairData?.change ?? 0.0;
    final isUp = selectedPairData?.isUp ?? true;

    // Live OHLC calculations based on the current tick price
    final double spread = currentPrice * 0.0005;
    final double open = currentPrice - (isUp ? spread * 0.4 : -spread * 0.4);
    final double high = currentPrice + spread * 0.8;
    final double low = currentPrice - spread * 0.8;
    final double close = currentPrice;
    final digits = _selectedSymbol.contains('JPY') || _selectedSymbol.contains('XAU') ? 2 : 4;

    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedSymbol,
                style: textStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'O: ${open.toStringAsFixed(digits)}  H: ${high.toStringAsFixed(digits)}  L: ${low.toStringAsFixed(digits)}  C: ${close.toStringAsFixed(digits)}',
                style: monoStyle(fontSize: 9, color: textMid),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 6),
          Row(
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
                  Text('SPREAD —', style: monoStyle(color: textLow, fontSize: 9)),
                  const SizedBox(width: 4),
                  const Icon(Icons.circle, color: buyGreen, size: 6),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: monoStyle(color: buyGreen, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 260,
            padding: const EdgeInsets.only(top: 8, bottom: 20, right: 12),
            color: const Color(0xFF060606),
            child: LiveCandleChart(symbol: _selectedSymbol),
          ),
          const Divider(color: borderFaint, height: 1),
          // Chart Bottom Tabs (Positions lists)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _bottomTab('OPEN', 0, badge: _openPositions.length.toString()),
                    const SizedBox(width: 12),
                    _bottomTab('HISTORY', 1),
                    const SizedBox(width: 12),
                    _bottomTab('PENDING', 2),
                  ],
                ),
                Row(
                  children: [
                    FilterTab(label: 'ALL', active: true, onTap: () {}),
                    const SizedBox(width: 4),
                    FilterTab(label: 'BUY', active: false, onTap: () {}),
                    const SizedBox(width: 4),
                    FilterTab(label: 'SELL', active: false, onTap: () {}),
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
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active ? gold.withOpacity(0.08) : Colors.transparent,
        border: Border.all(color: active ? gold : borderFaint),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: monoStyle(color: active ? gold : textMid, fontSize: 9),
      ),
    );
  }

  Widget _buildExecuteTrade() {
    final marketData = ref.watch(marketServiceProvider);
    final selectedPairData = marketData[_selectedSymbol];
    final currentPrice = selectedPairData?.price ?? 1.0724;

    // Estimate dynamic bid / ask based on spread model
    final double spreadOffset = _selectedSymbol.contains('JPY') ? 0.02 : _selectedSymbol.contains('XAU') ? 0.15 : 0.0002;
    final double bidPrice = currentPrice - (spreadOffset / 2);
    final double askPrice = currentPrice + (spreadOffset / 2);

    final digits = _selectedSymbol.contains('JPY') || _selectedSymbol.contains('XAU') ? 2 : 4;

    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: gold, size: 14),
                  const SizedBox(width: 6),
                  Text('EXECUTE TRADE', style: labelCaps(color: gold)),
                ],
              ),
              if (_isPaperConnected)
                _badge('PAPER TRADING', buyGreen),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgDeep,
              border: Border.all(color: borderFaint, width: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _isPaperConnected
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, color: buyGreen, size: 6),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PAPER TRADING SIMULATOR',
                                style: textStyle(color: textMid, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'BALANCE: \$${_paperBalance.toStringAsFixed(2)}',
                                style: monoStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _showDisconnectPaperDialog,
                          child: const Icon(Icons.logout, color: Colors.white38, size: 14),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.link_off, color: sellRed, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            'NO ACCOUNT CONNECTED',
                            style: textStyle(color: textLow, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _showBrokerDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: gold.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+ CONNECT',
                              style: textStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOrderType = 'BUY'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedOrderType == 'BUY' ? buyGreen : Colors.transparent,
                        border: Border.all(
                          color: _selectedOrderType == 'BUY' ? Colors.transparent : buyGreen.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '▲ BUY',
                            style: textStyle(
                              color: _selectedOrderType == 'BUY' ? Colors.black : buyGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            bidPrice.toStringAsFixed(digits),
                            style: monoStyle(
                              color: _selectedOrderType == 'BUY' ? Colors.black87 : Colors.white70,
                              fontSize: 10,
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
                    onTap: () => setState(() => _selectedOrderType = 'SELL'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedOrderType == 'SELL' ? sellRed : Colors.transparent,
                        border: Border.all(
                          color: _selectedOrderType == 'SELL' ? Colors.transparent : sellRed.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '▼ SELL',
                            style: textStyle(
                              color: _selectedOrderType == 'SELL' ? Colors.black : sellRed,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            askPrice.toStringAsFixed(digits),
                            style: monoStyle(
                              color: _selectedOrderType == 'SELL' ? Colors.black87 : Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LOT SIZE', style: labelCaps(color: textMid)),
              Text(
                _selectedLot,
                style: monoStyle(color: gold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _lotSizeBox('0.01'),
              _lotSizeBox('0.05'),
              _lotSizeBox('0.10'),
              _lotSizeBox('0.20'),
              _lotSizeBox('0.50'),
              _lotSizeBox('1.00'),
              _lotSizeBox('2.00'),
            ],
          ),
          const SizedBox(height: 8),
          _customSliderRow(
            'STOP LOSS',
            '${_stopLoss.toInt()} pips',
            sellRed,
            _stopLoss,
            (v) => setState(() => _stopLoss = v),
          ),
          const SizedBox(height: 6),
          _customSliderRow(
            'TAKE PROFIT',
            '${_takeProfit.toInt()} pips',
            gold,
            _takeProfit,
            (v) => setState(() => _takeProfit = v),
          ),
          const SizedBox(height: 10),
          // Risk/Reward Preview Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: bgDeep,
              border: Border.all(color: borderFaint, width: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'RISK: \$${(_stopLoss * double.parse(_selectedLot) * 10).toStringAsFixed(2)}',
                  style: monoStyle(color: sellRed, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  'REWARD: \$${(_takeProfit * double.parse(_selectedLot) * 10).toStringAsFixed(2)}',
                  style: monoStyle(color: buyGreen, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  'R:R: 1:${(_takeProfit / _stopLoss).toStringAsFixed(1)}',
                  style: monoStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GoldButton(
            label: 'EXECUTE $_selectedOrderType $_selectedLot LOT',
            onTap: _executeTrade,
          ),
        ],
      ),
    );
  }

  Widget _lotSizeBox(String size) {
    final active = _selectedLot == size;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _selectedLot = size),
          child: Container(
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: active ? gold : bgElevated,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              size,
              style: textStyle(
                color: active ? Colors.black : textMid,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _customSliderRow(String label, String value, Color activeColor, double currentVal, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: labelCaps(color: textMid)),
            Text(
              value,
              style: monoStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbColor: activeColor,
            activeTrackColor: activeColor,
            inactiveTrackColor: borderFaint,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
          ),
          child: Slider(
            value: currentVal,
            min: 0.0,
            max: 1000.0,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _bottomTab(String title, int index, {String? badge}) {
    final active = _positionsTabIndex == index;
    final displayTitle = badge != null ? '$title ($badge)' : title;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _positionsTabIndex = index),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? gold : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            displayTitle,
            style: textStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? gold : textLow,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionsList() {
    if (_positionsTabIndex == 0) {
      if (_openPositions.isEmpty) {
        return Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'NO ACTIVE POSITIONS',
              style: monoStyle(color: textLow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              'CONNECT A BROKER TO INITIATE TRADES',
              style: textStyle(color: Colors.white12, fontSize: 9),
            ),
            const SizedBox(height: 24),
          ],
        );
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _openPositions.length,
        separatorBuilder: (context, index) => const Divider(color: borderFaint, height: 1),
        itemBuilder: (context, index) {
          final pos = _openPositions[index];
          return _positionRow(pos);
        },
      );
    } else if (_positionsTabIndex == 1) {
      if (_history.isEmpty) {
        return Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'NO HISTORY RECORDED',
              style: monoStyle(color: textLow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 24),
          ],
        );
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _history.length,
        separatorBuilder: (context, index) => const Divider(color: borderFaint, height: 1),
        itemBuilder: (context, index) {
          final pos = _history[index];
          return _historyRow(pos);
        },
      );
    } else {
      return Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'NO PENDING ORDERS',
            style: monoStyle(color: textLow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 24),
        ],
      );
    }
  }

  void _showPositionActions(BuildContext context, Map<String, dynamic> pos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C0C0C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                title: Text('Modify Order', style: textStyle(color: Colors.white, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showModifyDialog(pos);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: sellRed, size: 18),
                title: Text('Close Order', style: textStyle(color: Colors.white, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCloseDialog(pos);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _positionRow(Map<String, dynamic> pos) {
    final Color pnlColor = pos['isUp'] ? buyGreen : sellRed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showPositionActions(context, pos),
        child: SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    pos['symbol'],
                    style: textStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  SignalBadge(type: pos['type']),
                ],
              ),
              Row(
                children: [
                  Text(
                    pos['lot'],
                    style: monoStyle(color: textMid, fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    pos['pnl'],
                    style: monoStyle(color: pnlColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showModifyDialog(pos),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 0.5),
                      ),
                      child: const Icon(Icons.edit, color: Colors.blueAccent, size: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showCloseDialog(pos),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: sellRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: sellRed.withOpacity(0.3), width: 0.5),
                      ),
                      child: const Icon(Icons.close, color: sellRed, size: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyRow(Map<String, dynamic> pos) {
    final Color pnlColor = pos['isUp'] ? buyGreen : sellRed;

    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                pos['symbol'],
                style: textStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              SignalBadge(type: pos['type']),
            ],
          ),
          Row(
            children: [
              Text(
                pos['lot'],
                style: monoStyle(color: textMid, fontSize: 11),
              ),
              const SizedBox(width: 12),
              Text(
                pos['pnl'],
                style: monoStyle(color: pnlColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
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

class LiveWatchItem extends StatefulWidget {
  final String pair;
  final String flag;
  final double initialPrice;
  final double initialChange;
  final bool initialIsUp;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const LiveWatchItem({
    super.key,
    required this.pair,
    required this.flag,
    required this.initialPrice,
    required this.initialChange,
    required this.initialIsUp,
    required this.isSelected,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  State<LiveWatchItem> createState() => _LiveWatchItemState();
}

class _LiveWatchItemState extends State<LiveWatchItem> {
  double _lastPrice = 0;
  Color _flashColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _lastPrice = widget.initialPrice;
  }

  @override
  void didUpdateWidget(covariant LiveWatchItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPrice != oldWidget.initialPrice && widget.initialPrice != _lastPrice) {
      final isUp = widget.initialPrice > _lastPrice;
      setState(() {
        _flashColor = isUp ? buyGreen.withOpacity(0.2) : sellRed.withOpacity(0.2);
        _lastPrice = widget.initialPrice;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _flashColor = Colors.transparent;
          });
        }
      });
    }
  }

  Widget _buildSymbolIcon(String pair) {
    String initials = 'US';
    Color color = const Color(0xFF333333);
    
    if (pair.startsWith('EUR')) {
      initials = 'EU';
      color = const Color(0xFF0052B4);
    } else if (pair.startsWith('GBP')) {
      initials = 'GB';
      color = const Color(0xFF7E3FF2);
    } else if (pair.startsWith('USD')) {
      initials = 'US';
      color = const Color(0xFF424242);
    } else if (pair.startsWith('XAU')) {
      initials = 'XA';
      color = const Color(0xFFD4AF37);
    } else if (pair.startsWith('BTC')) {
      initials = 'BT';
      color = const Color(0xFFF7931A);
    } else if (pair.startsWith('AUD')) {
      initials = 'AU';
      color = const Color(0xFF26A69A);
    } else if (pair.startsWith('NZD')) {
      initials = 'NZ';
      color = const Color(0xFF29B6F6);
    } else if (pair.length >= 2) {
      initials = pair.substring(0, 2).toUpperCase();
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceStr = widget.initialPrice.toStringAsFixed(
        widget.pair.contains('JPY') || widget.pair.contains('XAU') ? 2 : 4);
    final changeStr = "${widget.initialChange > 0 ? '+' : ''}${widget.initialChange.toStringAsFixed(2)}%";
    final changeColor = widget.initialIsUp ? buyGreen : sellRed;

    return Dismissible(
      key: Key(widget.pair),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: sellRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.delete_outline, color: sellRed, size: 16),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: widget.isSelected ? gold.withOpacity(0.04) : _flashColor.withOpacity(0.1),
              border: Border.all(
                color: widget.isSelected ? gold.withOpacity(0.4) : Colors.transparent,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildSymbolIcon(widget.pair),
                    const SizedBox(width: 8),
                    Text(
                      widget.pair,
                      style: textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected ? gold : Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      priceStr,
                      style: monoStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected ? gold : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 54,
                      alignment: Alignment.centerRight,
                      child: Text(
                        changeStr,
                        style: monoStyle(
                          fontSize: 10,
                          color: changeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RedPulseDot extends StatefulWidget {
  @override
  State<_RedPulseDot> createState() => _RedPulseDotState();
}

class _RedPulseDotState extends State<_RedPulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: criticalRed.withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: criticalRed.withOpacity(0.5 * _animation.value),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ],
          ),
        );
      },
    );
  }
}

class SkeletonContainer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.35).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
