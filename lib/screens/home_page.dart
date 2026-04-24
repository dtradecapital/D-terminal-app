import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/market_service.dart';
import '../widgets/shared.dart';
import 'trading_view.dart';
import 'intelligence_view.dart';
import 'account_view.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  final ScrollController _tickerController = ScrollController();
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTickerAnimation();
    });
  }

  void _startTickerAnimation() {
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_tickerController.hasClients) {
        double maxScroll = _tickerController.position.maxScrollExtent;
        double currentScroll = _tickerController.offset;
        
        // Loop back to start when reaching half (since we duplicate the list)
        if (currentScroll >= maxScroll - 1) {
          _tickerController.jumpTo(0);
        } else {
          _tickerController.jumpTo(currentScroll + 1);
        }
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeBg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopTicker(),
            _buildTopNav(),
            Expanded(
              child: Stack(
                children: [
                  const Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: VerticalAccentLine(),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: 900), // Wider for desktop-like feel
                      child: _buildBody(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTicker() {
    final marketData = ref.watch(marketServiceProvider);
    
    final tickerItems = marketData.values.map((data) {
      return _tickerItem(data.pair, data.price.toStringAsFixed(data.pair.contains('JPY') || data.pair.contains('XAU') ? 2 : 4), 
          "${data.change > 0 ? '+' : ''}${data.change.toStringAsFixed(2)}%", data.isUp);
    }).toList();

    // Add some static indices to make it look full
    tickerItems.addAll([
      _tickerItem('SPX', '5,432.10', '+0.61%', true),
      _tickerItem('NASDAQ', '19,240.20', '+0.92%', true),
    ]);

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: themeBg(context),
        border: Border(bottom: BorderSide(color: themeBorder(context))),
      ),
      alignment: Alignment.centerLeft,
      child: ListView.builder(
        controller: _tickerController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // Animation handles scrolling
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // Duplicate items infinitely or sufficiently large to loop
        itemBuilder: (context, index) => tickerItems[index % tickerItems.length],
      ),
    );
  }

  Widget _tickerItem(String pair, String price, String change, bool isUp) {
    final color = isUp ? const Color(0xFF00FF66) : const Color(0xFFFF0033);
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pair,
              style: const TextStyle(
                  color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(price,
              style: TextStyle(color: themeText(context), fontSize: 11)),
          const SizedBox(width: 6),
          Text(change,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: gold)),
                    child: const Text('D',
                        style: TextStyle(
                            color: gold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  const Text('TERMINAL',
                      style: TextStyle(
                          color: gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Builder(builder: (ctx) {
                final sbUser = sb.Supabase.instance.client.auth.currentUser;
                
                final name = sbUser?.email ?? 'ME';
                final initials = name.length >= 2
                    ? name.substring(0, 2).toUpperCase()
                    : 'ME';
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 2),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: gold),
                      ),
                      alignment: Alignment.center,
                      child: Text(initials,
                          style: const TextStyle(
                              color: gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // Tabs Container
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: themeSurface(context),
            border: Border(bottom: BorderSide(color: themeBorder(context))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navTab('TRADING', 0),
              _navTab('INTELLIGENCE', 1),
              _navTab('ACCOUNT', 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navTab(String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _currentIndex = index),
          behavior: HitTestBehavior.opaque,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: isSelected ? gold : Colors.transparent,
                        width: 2))),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? gold : themeTextDim(context),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final idx = _currentIndex == 3 ? 0 : _currentIndex;
    switch (idx) {
      case 0:
        return const TradingView();
      case 1:
        return const IntelligenceView();
      case 2:
      default:
        return const AccountView();
    }
  }
}
