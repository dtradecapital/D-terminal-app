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
        
        // Loop back to start when reaching end
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
            _buildAppHeader(),
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
                          maxWidth: 900), // Wider layout limit
                      child: _buildBody(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTopTicker() {
    final marketData = ref.watch(marketServiceProvider);
    
    // Convert current live symbols to ticker widgets
    final List<Widget> tickerItems = marketData.values.map<Widget>((data) {
      return TickerPairItem(
        pair: data.pair,
        price: data.price,
        change: data.change,
        isUp: data.isUp,
      );
    }).toList();
 
    // Add supplemental macro indices
    tickerItems.addAll([
      const TickerPairItem(pair: 'DXY', price: 104.24, change: 0.12, isUp: true),
      const TickerPairItem(pair: 'SPX', price: 5432.10, change: 0.61, isUp: true),
      const TickerPairItem(pair: 'NASDAQ', price: 19240.20, change: 0.92, isUp: true),
    ]);
 
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFF040404),
        border: Border(bottom: BorderSide(color: themeBorder(context))),
      ),
      alignment: Alignment.centerLeft,
      child: ListView.builder(
        controller: _tickerController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => tickerItems[index % tickerItems.length],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        border: Border(bottom: BorderSide(color: themeBorder(context), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: D Logo + Title + Pulse Connected Status
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.1),
                  border: Border.all(color: gold, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  'D',
                  style: monoStyle(
                    fontSize: 12,
                    color: gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TERMINAL',
                    style: textStyle(
                      fontSize: 11,
                      color: gold,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      _PulseDot(),
                      const SizedBox(width: 3),
                      Text(
                        'CONNECTED',
                        style: textStyle(
                          fontSize: 9,
                          color: buyGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Center/Right: Mode Toggle + Virtual Balance Chip + Avatar
          Row(
            children: [
              // Notification Bell
              Builder(builder: (context) {
                final unreadCount = ref.watch(alertsProvider).where((a) => a['isRead'] == 'false').length;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(accountMenuProvider.notifier).state = 'ALERTS';
                      setState(() {
                        _currentIndex = 2; // Direct to Account page
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF141414),
                            border: Border.all(color: const Color(0xFF222222), width: 1),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.notifications_none,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -2,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE05252), // sleek red
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              // Avatar
              Builder(builder: (ctx) {
                final sbUser = sb.Supabase.instance.client.auth.currentUser;
                final name = sbUser?.email ?? 'ME';
                final initials = name.length >= 2
                    ? name.substring(0, 2).toUpperCase()
                    : 'ME';
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(accountMenuProvider.notifier).state = 'PROFILE';
                      setState(() => _currentIndex = 2);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A1A1A),
                        border: Border.all(color: gold, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: monoStyle(
                          fontSize: 9,
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 50 + bottomPadding,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C),
        border: Border(top: BorderSide(color: themeBorder(context), width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bottomNavItem('TRADING', Icons.analytics_outlined, 0),
          _bottomNavItem('INTELLIGENCE', Icons.radar_outlined, 1),
          _bottomNavItem('ACCOUNT', Icons.account_circle_outlined, 2),
        ],
      ),
    );
  }

  Widget _bottomNavItem(String label, IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _currentIndex = index),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isSelected ? gold : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? gold : const Color(0xFF444444),
                  size: 19,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: textStyle(
                      fontSize: 8,
                      color: gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
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

class TickerPairItem extends StatefulWidget {
  final String pair;
  final double price;
  final double change;
  final bool isUp;

  const TickerPairItem({
    super.key,
    required this.pair,
    required this.price,
    required this.change,
    required this.isUp,
  });

  @override
  State<TickerPairItem> createState() => _TickerPairItemState();
}

class _TickerPairItemState extends State<TickerPairItem> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Color _flashColor;

  @override
  void initState() {
    super.initState();
    _flashColor = Colors.transparent;
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(TickerPairItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price) {
      // Trigger a green/red flash animation based on the price trend
      setState(() {
        _flashColor = widget.price > oldWidget.price
            ? buyGreen.withOpacity(0.25)
            : sellRed.withOpacity(0.25);
      });
      _flashController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _flashColor = Colors.transparent;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isUp ? buyGreen : sellRed;
    final priceStr = widget.price.toStringAsFixed(
      widget.pair.contains('JPY') || widget.pair.contains('XAU') ? 2 : 4
    );
    final changeStr = "${widget.change > 0 ? '+' : ''}${widget.change.toStringAsFixed(2)}%";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: _flashColor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.pair,
            style: monoStyle(
              fontSize: 9,
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            priceStr,
            style: monoStyle(
              fontSize: 9,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            changeStr,
            style: monoStyle(
              fontSize: 8,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '·',
            style: monoStyle(
              fontSize: 9,
              color: textLow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
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
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buyGreen.withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: buyGreen.withOpacity(0.6 * (1.0 - _animation.value)),
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}


