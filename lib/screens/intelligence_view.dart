import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../widgets/shared.dart';
import '../core/providers.dart';
import '../services/intelligence_service.dart';

class IntelligenceView extends ConsumerStatefulWidget {
  const IntelligenceView({super.key});

  @override
  ConsumerState<IntelligenceView> createState() => _IntelligenceViewState();
}

class _IntelligenceViewState extends ConsumerState<IntelligenceView> with SingleTickerProviderStateMixin {
  String _selectedModule = 'GEOINTEL';
  String _selectedSubModule = 'MAP';
  bool _isNavExpanded = true;
  String? _hoveredRegion;
  int? _hoveredRisk;
  Offset? _hoveredPos;
  String _selectedNewsDate = 'TODAY';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildGeoIntelContent(bool isWide) {
    switch (_selectedSubModule) {
      case 'MAP':
        return _buildMapTabContent(isWide);
      case 'NEWS':
        return _buildNewsTabContent();
      case 'CALENDAR':
        return _buildCalendarTabContent();
      case 'SIGNALS':
        return _buildSignalsTabContent();
      case 'MATRIX':
        return _buildMatrixTabContent();
      default:
        return _buildMapTabContent(isWide);
    }
  }

  String _getDateString(String label) {
    final now = DateTime.now();
    if (label == 'TODAY') return now.toIso8601String().split('T')[0];
    if (label == 'YESTERDAY') return now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    
    // For labels like "FRI 10 APR", we find the date in the last 7 days that matches
    for (int i = 2; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      if (_formatTabLabel(date) == label) {
        return date.toIso8601String().split('T')[0];
      }
    }
    return now.toIso8601String().split('T')[0];
  }

  String _formatTabLabel(DateTime date) {
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${weekdays[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
  }

  List<String> _getNewsTabs() {
    final List<String> tabs = ['TODAY', 'YESTERDAY'];
    final now = DateTime.now();
    for (int i = 2; i < 5; i++) {
      tabs.add(_formatTabLabel(now.subtract(Duration(days: i))));
    }
    return tabs;
  }

  Widget _buildMapTabContent(bool isWide) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Regional Indices Sidebar
          SizedBox(
            width: 280,
            child: _buildRegionalIndices(),
          ),
          const SizedBox(width: 48),
          // Right: Large Map and Analytics
          Expanded(
            child: Column(
              children: [
                _buildMapArea(),
                const SizedBox(height: 24),
                _buildAIGeneratedSignals(),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildMapArea(),
          const SizedBox(height: 24),
          _buildTopStatsMobile(),
          const SizedBox(height: 24),
          _buildActiveHotspots(),
          const SizedBox(height: 24),
          _buildAIGeneratedSignals(),
          const SizedBox(height: 24),
          _buildRegionalIndices(), // Added for mobile view
        ],
      );
    }
  }

  Widget _buildRegionalIndices() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: gold.withOpacity(0.2)),
        color: Colors.black.withOpacity(0.2), // Subtle background for mobile visibility
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sidebarTitle('ACTIVE HOTSPOTS', '0'),
          const SizedBox(height: 16),
          _sidebarTitle('REGIONAL INDICES', ''),
          const SizedBox(height: 12),
          _indexItem('Iran', 10, const Color(0xFF00FF66)),
          _indexItem('Iraq', 10, const Color(0xFF00FF66)),
          _indexItem('Syria', 10, Colors.amberAccent),
          _indexItem('Yemen', 10, Colors.amberAccent),
          _indexItem('Libya', 10, const Color(0xFF00FF66)),
          _indexItem('Russia', 10, const Color(0xFFFF0033)),
          _indexItem('Ukraine', 10, const Color(0xFF00FF66)),
          _indexItem('Belarus', 10, const Color(0xFF00FF66)),
          _indexItem('North Korea', 10, const Color(0xFFFF0033)),
          _indexItem('Afghanistan', 10, const Color(0xFF00FF66)),
          _indexItem('Pakistan', 10, const Color(0xFF00FF66)),
          _indexItem('Myanmar', 10, const Color(0xFF00FF66)),
          _indexItem('Sudan', 10, const Color(0xFF00FF66)),
          _indexItem('Ethiopia', 10, const Color(0xFF00FF66)),
          _indexItem('Somalia', 10, const Color(0xFF00FF66)),
          _indexItem('Mali', 10, const Color(0xFF00FF66)),
          _indexItem('Venezuela', 10, const Color(0xFF00FF66)),
          _indexItem('Israel', 10, const Color(0xFF00FF66)),
          _indexItem('Saudi Arabia', 10, const Color(0xFF00FF66)),
          _indexItem('United States', 10, const Color(0xFF00FF66)),
        ],
      ),
    );
  }

  Widget _buildNewsTabContent() {
    final dateStr = _getDateString(_selectedNewsDate);
    final newsAsync = ref.watch(forexNewsProvider(dateStr));

    return Column(
      children: [
        _buildSectionHeader('BATTLESPACE INTELLIGENCE DASHBOARD'),
        const SizedBox(height: 24),
        newsAsync.when(
          data: (data) {
            final List<dynamic> articles = data;
            
            // Filter articles for geographic columns
            final middleEastArticles = articles.where((a) {
              final h = a['headline']?.toString().toLowerCase() ?? '';
              return h.contains('iran') || h.contains('houthis') || h.contains('saudi') || h.contains('turkey') || h.contains('egypt') || h.contains('israel') || h.contains('middle east');
            }).toList();

            final easternEuropeArticles = articles.where((a) {
              final h = a['headline']?.toString().toLowerCase() ?? '';
              return h.contains('russia') || h.contains('ukraine') || h.contains('poland') || h.contains('eastern europe') || h.contains('putin');
            }).toList();
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Regional Indices
                if (MediaQuery.of(context).size.width > 1000)
                SizedBox(
                  width: 200,
                  child: _buildRegionalIndices(),
                ),
                
                if (MediaQuery.of(context).size.width > 1000)
                const SizedBox(width: 24),

                // Center Column: Main News Feed
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sidebarTitle('FOREX DAILY NEWS', ''),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _getNewsTabs().map((label) => _timeFrameTab(label)).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (articles.isEmpty)
                        _emptyState()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: articles.length,
                          itemBuilder: (context, index) {
                            final item = articles[index];
                            return _newsItemDetailed(item);
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Right Column: Geo-Categorized Intelligence
                if (MediaQuery.of(context).size.width > 1200)
                SizedBox(
                  width: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sidebarTitle('MIDDLE EAST', middleEastArticles.length.toString()),
                      const SizedBox(height: 12),
                      if (middleEastArticles.isEmpty)
                        _emptyGeoIntel('No regional news')
                      else
                        ...middleEastArticles.map((a) => _geoIntelCard(
                          a['source'] ?? 'INTEL',
                          a['headline'] ?? '',
                          _formatTime(a['published_at']),
                          0.0
                        )),
                      const SizedBox(height: 24),
                      _sidebarTitle('EASTERN EUROPE', easternEuropeArticles.length.toString()),
                      const SizedBox(height: 12),
                      if (easternEuropeArticles.isEmpty)
                        _emptyGeoIntel('No regional news')
                      else
                        ...easternEuropeArticles.map((a) => _geoIntelCard(
                          a['source'] ?? 'INTEL',
                          a['headline'] ?? '',
                          _formatTime(a['published_at']),
                          0.0
                        )),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: CircularProgressIndicator(color: gold),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Text('ERROR LOADING NEWS: $err',
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeFrameTab(String label) {
    bool isSelected = _selectedNewsDate == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedNewsDate = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? gold.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? gold.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? gold : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
      ),
    );
  }

  Widget _sidebarTitle(String title, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          if (count.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            child: Text(count, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _indexItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(height: 1, color: Colors.white.withOpacity(0.05)),
                Positioned(
                  left: 0,
                  right: 0,
                  child: Row(
                    children: List.generate(5, (index) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: 2,
                        decoration: BoxDecoration(
                          color: index < 4 ? color.withOpacity(0.4) : Colors.transparent,
                        ),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value.toString(), style: const TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'RECENT';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return 'RECENT';
    }
  }

  Widget _newsItemDetailed(dynamic item) {
    String time = _formatTime(item['published_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['source']?.toString().toUpperCase() ?? 'INVESTING',
                  style: const TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(time, style: const TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item['headline'] ?? item['title'] ?? 'No Headline Available',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                child: Text(item['category'] ?? 'FOREX', style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.keyboard_arrow_right, color: Colors.white24, size: 14),
              const Text('READ MORE', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _geoIntelCard(String source, String title, String time, double tone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(source, style: const TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(time, style: const TextStyle(color: Colors.white24, fontSize: 10)),
              Text('TONE: ${tone.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyGeoIntel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1A1A1A), style: BorderStyle.solid),
      ),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.white24, fontSize: 11))),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Text('NO RECENT NEWS DETECTED',
            style: TextStyle(color: themeTextDim(context).withOpacity(0.5))),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.rss_feed, color: gold, size: 20),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    color: themeText(context),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ],
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isRefreshing ? null : _handleRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: themeSurface(context),
                  border: Border.all(color: themeBorder(context)),
                  borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: [
                  _isRefreshing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              color: gold, strokeWidth: 1.5))
                      : const Icon(Icons.refresh, color: gold, size: 14),
                  const SizedBox(width: 8),
                  Text(_isRefreshing ? 'REFRESHING...' : 'REFRESH',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _newsItem(String title, String time, String impact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeSurface(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(time, style: TextStyle(color: themeTextDim(context), fontSize: 11)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(color: themeText(context), fontWeight: FontWeight.bold))),
          Text(impact, style: TextStyle(color: impact.contains('HIGH') ? Colors.redAccent : gold, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCalendarTabContent() {
    final calendarAsync = ref.watch(calendarProvider);

    return calendarAsync.when(
      data: (events) {
        if (events.isEmpty) return _emptyGeoIntel('NO UPCOMING EVENTS DETECTED');
        
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.05),
                border: Border.all(color: gold.withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('TIME', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('CCY', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 6, child: Text('EVENT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('FORECAST', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...events.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(e.time, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                  Expanded(flex: 2, child: Text(e.country, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 6, child: Text(e.event, style: const TextStyle(color: Colors.white, fontSize: 12))),
                  Expanded(flex: 3, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getImpactColor(e.impact).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: _getImpactColor(e.impact).withOpacity(0.2)),
                    ),
                    child: Text(e.impact.toUpperCase(), style: TextStyle(color: _getImpactColor(e.impact), fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  )),
                  Expanded(flex: 3, child: Text(e.forecast, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.right)),
                ],
              ),
            )),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: gold)),
      ),
      error: (e, stack) => _emptyGeoIntel('ERROR LOADING CALENDAR'),
    );
  }

  Color _getImpactColor(String impact) {
    switch (impact.toUpperCase()) {
      case 'HIGH': return const Color(0xFFFF0033);
      case 'MEDIUM': return gold;
      case 'LOW': return const Color(0xFF00FF66);
      default: return Colors.white30;
    }
  }

  Widget _buildSignalsTabContent() {
    final signalsAsync = ref.watch(signalsProvider);

    return signalsAsync.when(
      data: (signals) {
        if (signals.isEmpty) return _emptyGeoIntel('NO ACTIVE SIGNALS DETECTED');
        
        return Column(
          children: signals.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              border: Border.all(color: const Color(0xFF1A1A1A)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.pair, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(s.timeframe, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: s.type == 'BUY' ? const Color(0xFF00FF66).withOpacity(0.1) : const Color(0xFFFF0033).withOpacity(0.1),
                        border: Border.all(color: s.type == 'BUY' ? const Color(0xFF00FF66) : const Color(0xFFFF0033)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s.type, style: TextStyle(color: s.type == 'BUY' ? const Color(0xFF00FF66) : const Color(0xFFFF0033), fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('"${s.headline}"', style: const TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'serif', height: 1.5)),
                const SizedBox(height: 20),
                Row(
                  children: s.tags.map((tag) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: Text(tag, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('CONFIDENCE', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(height: 8, color: Colors.white.withOpacity(0.05)),
                          FractionallySizedBox(
                            widthFactor: s.confidence / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: gold,
                                boxShadow: [BoxShadow(color: gold.withOpacity(0.5), blurRadius: 10)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('${s.confidence}%', style: const TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ],
                ),
              ],
            ),
          )).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: gold)),
      ),
      error: (e, stack) => _emptyGeoIntel('ERROR LOADING SIGNALS'),
    );
  }

  Widget _buildMatrixTabContent() {
    final matrixAsync = ref.watch(correlationMatrixProvider);

    return matrixAsync.when(
      data: (matrix) {
        final assets = matrix.values.first.keys.toList();
        final countries = matrix.keys.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('Country-Asset Correlation Matrix', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             const Text('Geopolitical risk event correlation with FX & commodity pairs. Green = positive, Red = negative.', style: TextStyle(color: Colors.white38, fontSize: 11)),
             const SizedBox(height: 24),
             SingleChildScrollView(
               scrollDirection: Axis.horizontal,
               child: Table(
                 defaultColumnWidth: const FixedColumnWidth(110),
                 border: TableBorder.all(color: const Color(0xFF1A1A1A), width: 0.5),
                 children: [
                   TableRow(
                     children: [
                       const Padding(padding: EdgeInsets.all(12), child: Text('Country', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold))),
                       ...assets.map((asset) => Padding(padding: const EdgeInsets.all(12), child: Text(asset, style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
                     ],
                   ),
                   ...countries.map((country) => TableRow(
                     children: [
                       Padding(padding: const EdgeInsets.all(12), child: Text(country, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
                       ...assets.map((asset) {
                          final value = matrix[country]![asset]!;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            color: _getCorrelationColor(value).withOpacity(0.15),
                            child: Text(
                              (value >= 0 ? '+' : '') + value.toStringAsFixed(2),
                              style: TextStyle(color: _getCorrelationColor(value), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              textAlign: TextAlign.center,
                            ),
                          );
                       }),
                     ],
                   )),
                 ],
               ),
             ),
             const SizedBox(height: 16),
             const Text('Values represent directional correlation coefficient. Updated every 4 hours.', style: TextStyle(color: Colors.white24, fontSize: 9)),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: gold)),
      ),
      error: (e, stack) => _emptyGeoIntel('ERROR LOADING MATRIX'),
    );
  }

  Color _getCorrelationColor(double val) {
    if (val > 0.3) return const Color(0xFF00FF66);
    if (val < -0.3) return const Color(0xFFFF0033);
    return Colors.white38;
  }

  Widget _buildModuleContent(bool isWide) {
    switch (_selectedModule) {
      case 'GEOINTEL':
        return _buildGeoIntelContent(isWide);
      case 'PATTERN INSIGHTS':
        return _buildPatternInsightsContent();
      case 'TRADER GENOME':
        return _buildTraderGenomeContent();
      case 'COGNITIVE FITNESS':
        return _buildCognitiveFitnessContent();
      default:
        return _buildGeoIntelContent(isWide);
    }
  }

  bool _isRefreshing = false;

  void _handleRefresh() async {
    setState(() => _isRefreshing = true);
    // Refresh all relevant data providers
    final dateStr = _getDateString(_selectedNewsDate);
    ref.invalidate(forexNewsProvider(dateStr));
    ref.invalidate(calendarProvider);
    ref.invalidate(signalsProvider);
    ref.invalidate(correlationMatrixProvider);
    ref.invalidate(situationalReportProvider);
    
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Widget _buildPatternInsightsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart, color: gold, size: 24),
                    const SizedBox(width: 12),
                    Text('PATTERN INSIGHTS',
                        style: TextStyle(
                            color: themeText(context),
                            fontSize: 15,
                            fontFamily: 'AgencyFB',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Behavioural detection engine — waiting for first trades',
                    style: TextStyle(
                        color: themeTextDim(context).withOpacity(0.5),
                        fontSize: 13)),
              ],
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _isRefreshing ? null : _handleRefresh,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                      color: themeSurface(context),
                      border: Border.all(color: themeBorder(context)),
                      borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isRefreshing
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  color: gold, strokeWidth: 2))
                          : Icon(Icons.refresh,
                              color: themeText(context).withOpacity(0.8), size: 14),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _isRefreshing ? 'REFRESHING...' : 'REFRESH',
                            style: TextStyle(
                              color: themeText(context),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: themeSurface(context).withOpacity(0.5),
              border: Border.all(color: themeBorder(context)),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: gold.withOpacity(0.1),
                        border: Border.all(color: gold.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      children: [
                        Icon(Icons.analytics, color: gold, size: 14),
                        SizedBox(width: 8),
                        Text('RULE BASED ANALYSIS',
                            style: TextStyle(
                                color: gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('50 MORE TRADES TO UNLOCK STATISTICAL ANALYSIS',
                        style: TextStyle(
                            color: themeTextDim(context).withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                  Text('0 / 50',
                      style: TextStyle(
                          color: themeTextDim(context).withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(2)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.05,
                  child: Container(
                    decoration: BoxDecoration(
                        color: gold, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 80),
          decoration: BoxDecoration(
              color: themeSurface(context).withOpacity(0.3),
              border: Border.all(color: themeBorder(context)),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: gold.withOpacity(0.05),
                    border: Border.all(color: gold.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.analytics_outlined, color: gold, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('BUILDING YOUR PROFILE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'AgencyFB',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: Text(
                  'Execute your first trades using the Trading Engine. Pattern detection activates automatically as your history grows.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: themeTextDim(context).withOpacity(0.5),
                      fontSize: 14,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 40),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _unlockCard('RULE-BASED PATTERNS', 'Unlocks at 1+ trades',
                        Icons.onetwothree_outlined, true),
                    const SizedBox(width: 16),
                    _unlockCard('STATISTICAL ANALYSIS', 'Unlocks at 50+ trades',
                        Icons.bar_chart_outlined, false),
                    const SizedBox(width: 16),
                    _unlockCard('PERSONAL AI MODEL', 'Unlocks at 200+ trades',
                        Icons.smart_toy_outlined, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _unlockCard(String title, String status, IconData icon, bool isActive) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: isActive ? gold.withOpacity(0.02) : Colors.transparent,
          border: Border.all(
              color: isActive ? gold.withOpacity(0.3) : themeBorder(context)),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: isActive ? gold : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Icon(icon,
                color: isActive ? Colors.black : Colors.white24, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(status,
              style: TextStyle(
                  color: isActive
                      ? gold.withOpacity(0.7)
                      : Colors.white.withOpacity(0.15),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed Icon Sidebar
              Container(
                width: 85,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: themeSurface(context).withOpacity(0.5),
                  border: Border(right: BorderSide(color: themeBorder(context))),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: _buildIntelModulesFixed(),
                ),
              ),
              // Main Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildTopStats(),
                      const SizedBox(height: 24),
                      _buildModuleContent(true),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              // Horizontal Mini Navigation for Mobile
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: themeSurface(context),
                  border: Border(bottom: BorderSide(color: themeBorder(context))),
                ),
                child: Row(
                  children: [
                    // Radar Trigger Icon with Premium Ripple & Glow Effect
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _isNavExpanded = !_isNavExpanded),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _isNavExpanded 
                                  ? gold.withOpacity(0.15) 
                                  : Colors.white.withOpacity(0.02),
                              border: Border.all(
                                color: _isNavExpanded 
                                    ? gold.withOpacity(0.5) 
                                    : Colors.white.withOpacity(0.05)
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _isNavExpanded ? [
                                BoxShadow(
                                  color: gold.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ] : [],
                            ),
                            child: Center(
                              child: Icon(
                                _isNavExpanded ? Icons.close : Icons.radar, 
                                color: gold, 
                                size: 20
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isNavExpanded ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !_isNavExpanded,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 8),
                                _intelModuleSidebarItem(Icons.public, 'GEOINTEL', 'GEOINTEL'),
                                _intelModuleSidebarItem(Icons.analytics_outlined, 'PATTERN INSIGHTS', 'PATTERN'),
                                _intelModuleSidebarItem(Icons.fingerprint, 'TRADER GENOME', 'GENOME'),
                                _intelModuleSidebarItem(Icons.psychology_outlined, 'COGNITIVE FITNESS', 'COGNITIVE'),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _buildTopStats(),
                    const SizedBox(height: 24),
                    _buildModuleContent(false),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildIntelModulesFixed() {
    return GestureDetector(
      onTap: () => setState(() => _isNavExpanded = !_isNavExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 85,
        decoration: BoxDecoration(
          color: themeSurface(context),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              ...[
                _intelModuleSidebarItem(Icons.public, 'GEOINTEL', 'GEOINTEL'),
                _intelModuleSidebarItem(Icons.analytics_outlined, 'PATTERN INSIGHTS', 'PATTERN'),
                _intelModuleSidebarItem(Icons.fingerprint, 'TRADER GENOME', 'GENOME'),
                _intelModuleSidebarItem(Icons.psychology_outlined, 'COGNITIVE FITNESS', 'COGNITIVE'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _intelModuleSidebarItem(IconData icon, String title, String shortName) {
    bool isSelected = _selectedModule == title;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedModule = title;
          _isNavExpanded = false; // Auto-collapse on selection
        }),
        child: Container(
          width: 70,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? gold.withOpacity(0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? gold.withOpacity(0.6)
                        : Colors.white.withOpacity(0.02),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: gold.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ] : null,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected 
                        ? gold 
                        : themeText(context).withOpacity(0.40), // More visible but still faint
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (isSelected || _isNavExpanded) ? 1.0 : 0.0,
                child: Text(
                  shortName,
                  style: TextStyle(
                    color: isSelected ? gold : themeTextDim(context).withOpacity(0.3),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTopStats() {
    return Column(
      children: [
        Row(
          children: [
      // Tension Index Box
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: gold.withOpacity(0.05),
          border: Border.all(color: gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text('GLOBAL TENSION INDEX',
                style: TextStyle(
                    color: gold.withOpacity(0.7),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(width: 14),
            const Text('10.0',
                style: TextStyle(
                    color: gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace')),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF66).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF66).withOpacity(0.2 * _pulseAnimation.value),
                        blurRadius: 4 * _pulseAnimation.value,
                        spreadRadius: 1 * _pulseAnimation.value,
                      )
                    ],
                  ),
                  child: const Text('+LIVE',
                      style: TextStyle(
                          color: Color(0xFF00FF66),
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                );
              },
            ),
          ],
        ),
      ),
            const SizedBox(width: 12),
            // Navigation Tabs (Strictly for GEOINTEL)
            if (_selectedModule == 'GEOINTEL')
              Expanded(
                child: Container(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _topTab('MAP'),
                        _topTab('NEWS'),
                        _topTab('CALENDAR'),
                        _topTab('SIGNALS'),
                        _topTab('MATRIX'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Status Bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusBarItem('AI ANALYTICS', 'ONLINE', const Color(0xFF00FF66)),
                _statusBarItem('ACTIVE SIGNALS', '5', gold),
                _statusBarItem('HOTSPOTS', '0 CRITICAL', const Color(0xFFFF0033)),
                _statusBarItem('NEWS FEEDS', 'ACTIVE', const Color(0xFF00FF66)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: themeBorder(context).withOpacity(0.3)),
      ],
    );
  }

  Widget _buildTopStatsMobile() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: themeBorder(context)),
            color: themeSection(context).withOpacity(0.5),
          ),
          child: Column(
            children: [
              Text('GLOBAL TENSION INDEX',
                  style: TextStyle(color: themeTextDim(context), fontSize: 9, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              const Text('71.4', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (_selectedModule == 'GEOINTEL') ...[
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
               _topTab('MAP'),
               _topTab('NEWS'),
               _topTab('CALENDAR'),
               _topTab('SIGNALS'),
               _topTab('MATRIX'),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _topTab(String label) {
    bool isSelected = _selectedSubModule == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedSubModule = label),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? themeSection(context) : Colors.transparent,
            border: Border(
                bottom: BorderSide(
                    color: isSelected ? gold : Colors.transparent, width: 1.5)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: isSelected ? gold : themeTextDim(context),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _statusBarItem(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: themeTextDim(context).withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(width: 10),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActiveHotspots() {
    return Container(
      decoration: BoxDecoration(
        color: themeSurface(context).withOpacity(0.3),
        border: Border.all(color: themeBorder(context).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVE HOTSPOTS',
                    style: TextStyle(
                        color: themeTextDim(context).withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF0033).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('9',
                      style: TextStyle(
                          color: Color(0xFFFF0033),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Container(height: 1, color: themeBorder(context).withOpacity(0.5)),
          _hotspotItem('WAR / GEO • IRAN', 'Hormuz Blockade', 88),
          _hotspotItem('WAR / GEO • UKRAINE', 'Drone Campaign', 82),
          _hotspotItem('WAR / GEO • RUSSIA', 'Sanctions Expand', 85),
          _hotspotItem('WAR / GEO • NORTH KOREA', 'Missile Launch', 79),
          _hotspotItem('WAR / GEO • ISRAEL', 'Regional Tension', 76),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _hotspotItem(String category, String title, int score) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: themeBorder(context)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category,
              style: const TextStyle(
                  color: Color(0xFFFF0033),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  color: themeText(context),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('RISK SCORE:',
                  style: TextStyle(color: themeTextDim(context).withOpacity(0.7), fontSize: 10)),
              const SizedBox(width: 8),
              Text(score.toString(),
                  style: TextStyle(color: themeText(context).withOpacity(0.7), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return Center(
      child: Container(
        height: 600,
        width: 1260, // Tactical aspect ratio for the elliptical asset
        decoration: BoxDecoration(
          color: const Color(0xFF070707),
          border: Border.all(color: gold.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 50,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Base Map Layer - Using high-res asset
            Positioned.fill(
              child: Opacity(
                opacity: 0.95,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.blueAccent.withOpacity(0.40), // Brighter neon intensity
                    BlendMode.screen,
                  ),
                  child: Image.asset(
                    'assets/images/world_map.png',
                    fit: BoxFit.contain, // Fit the entire elliptical globe without cropping
                  ),
                ),
              ),
            ),
            // Scan Line Effect
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.3,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(color: gold.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                        ],
                        gradient: LinearGradient(
                          colors: [Colors.transparent, gold.withOpacity(0.5), Colors.transparent],
                        ),
                      ),
                      transform: Matrix4.translationValues(0, 600 * _pulseController.value, 0),
                    ),
                  ),
                );
              },
            ),
            
            // Regional Intelligence Nodes - Data Driven
            ...ref.watch(regionalRiskProvider).when(
              data: (risks) => [
                // Layer 1: Regional Heat/Shading
                ...risks.map((r) => _regionGlow(r.top, r.left, r.color, _hoveredRegion == r.region)),
                // Layer 2: Interactive Nodes
                ...risks.map((r) => _hotspotNode(r.top, r.left, r.color, r.region, r.riskIndex)),
              ],
              loading: () => [],
              error: (_, __) => [],
            ),

            // Interactive Popup
            if (_hoveredRegion != null)
              _buildInteractivePopup(),
          ],
        ),
      ),
    );
  }

  Widget _regionGlow(double top, double left, Color color, bool isHovered) {
    return Positioned(
      top: top - 40,
      left: left - 40,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: isHovered ? 0.4 : 0.15,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hotspotNode(double? top, double? left, Color c, String region, int risk, {double? right, double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (e) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final pos = box.localToGlobal(Offset.zero);
          setState(() {
            _hoveredRegion = region;
            _hoveredRisk = risk;
            // Calculate a good spot for the popup
            double px = (left ?? (800 - (right ?? 0))) + 20;
            double py = (top ?? (600 - (bottom ?? 0))) - 40;
            _hoveredPos = Offset(px, py);
          });
        },
        onExit: (e) => setState(() {
          _hoveredRegion = null;
        }),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 18 * _pulseAnimation.value,
              height: 18 * _pulseAnimation.value,
              decoration: BoxDecoration(
                color: c.withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.withOpacity(0.4),
                    blurRadius: 15 * _pulseAnimation.value,
                    spreadRadius: 5 * _pulseAnimation.value,
                  )
                ],
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInteractivePopup() {
    return Positioned(
      left: (_hoveredPos?.dx ?? 0),
      top: (_hoveredPos?.dy ?? 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _hoveredRegion != null ? 1.0 : 0.0,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.95),
            border: Border.all(color: gold.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, spreadRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_hoveredRegion!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AgencyFB',
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Risk Index:',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), 
                          fontSize: 11, 
                          fontWeight: FontWeight.bold)),
                  Text('$_hoveredRisk',
                      style: const TextStyle(
                          color: gold, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'monospace')),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (_hoveredRisk ?? 0) / 100,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: (_hoveredRisk ?? 0) > 80 ? Colors.redAccent : gold,
                minHeight: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAIGeneratedSignals() {
    return Container(
      decoration: BoxDecoration(
        color: themeSurface(context).withOpacity(0.2),
        border: Border.all(color: themeBorder(context).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: gold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: gold.withOpacity(0.4 * _pulseAnimation.value),
                              blurRadius: 8 * _pulseAnimation.value,
                              spreadRadius: 2 * _pulseAnimation.value,
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text('AI INTELLIGENCE',
                      style: TextStyle(
                          color: gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                ],
              ),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF66),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FF66).withOpacity(0.6 * _pulseAnimation.value),
                              blurRadius: 10 * _pulseAnimation.value,
                              spreadRadius: 3 * _pulseAnimation.value,
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text('READY',
                      style: TextStyle(
                          color: Color(0xFF00FF66),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.02),
              border: const Border(left: BorderSide(color: gold, width: 3)),
              gradient: LinearGradient(
                colors: [gold.withOpacity(0.05), Colors.transparent],
                stops: const [0.0, 0.4],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ref.watch(situationalReportProvider).when(
                  data: (report) => Text(
                    report,
                    style: TextStyle(
                      color: themeText(context).withOpacity(0.9),
                      fontSize: 15,
                      height: 1.6,
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: gold, strokeWidth: 2)),
                  error: (err, _) => const Text(
                    'Intelligence feed currently unavailable. Strategic flow monitoring continuous.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
          ),
          const SizedBox(height: 32),
          Text('GENERATED SIGNALS',
              style: TextStyle(
                  color: themeTextDim(context).withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.05),
              border: Border.all(color: gold.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: gold, size: 18),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Long-term AI directional bias — for educational purposes only. Not financial advice. Not for short-term trading.',
                    style: TextStyle(
                      color: gold.withOpacity(0.8),
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraderGenomeContent() {
    final sbUser = sb.Supabase.instance.client.auth.currentUser;
    if (sbUser == null) return _emptyGeoIntel('PLEASE LOGIN TO VIEW GENOME');

    final genomeAsync = ref.watch(userGenomeProvider(sbUser.id));

    return genomeAsync.when(
      data: (data) {
        if (data == null || data.isEmpty) {
          return _buildLockedGenome();
        }
        return _buildUnlockedGenome(data);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (err, stack) => _emptyGeoIntel('ERROR LOADING GENOME'),
    );
  }

  Widget _buildLockedGenome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Blowing Lock Icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gold.withOpacity(0.15 * _pulseAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF131118),
                      border: Border.all(
                        color: gold.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gold.withOpacity(0.1),
                          blurRadius: 20 * _pulseAnimation.value,
                          spreadRadius: 5 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: gold,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Genome Locked Text
          const Text(
            'GENOME LOCKED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: themeTextDim(context).withOpacity(0.7),
                fontSize: 16,
                letterSpacing: 0.5,
              ),
              children: const [
                TextSpan(text: 'Need '),
                TextSpan(
                  text: '30 trades',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' to classify your archetype.'),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Progress Card
          Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1B1E).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESS',
                      style: TextStyle(
                        color: themeTextDim(context).withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      '0 / 30',
                      style: TextStyle(
                        color: Color(0xFF00FF66),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'AgencyFB',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Custom Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 8,
                      width: 0, // 0 progress for now
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '30 more trades to unlock',
                    style: TextStyle(
                      color: themeTextDim(context).withOpacity(0.4),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildUnlockedGenome(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: gold.withOpacity(0.3)),
              ),
              child: const Icon(Icons.fingerprint, color: gold, size: 40),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['archetype']?.toString().toUpperCase() ?? 'TRADER ARCHETYPE',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('DNA Profile generated from ${data['trade_count'] ?? 0} trades',
                    style: TextStyle(color: gold.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _genomeStatCard('PRECISION', data['precision'] ?? '0%', Icons.gps_fixed),
            _genomeStatCard('RISK TOLERANCE', data['risk_tolerance'] ?? 'MODERATE', Icons.warning_amber),
            _genomeStatCard('RECOVERY RATE', data['recovery'] ?? '0%', Icons.autorenew),
          ],
        ),
        const SizedBox(height: 32),
        _cardWrapper(
          icon: Icons.psychology,
          title: 'PSYCHOLOGICAL TRAITS',
          child: Column(
            children: (data['traits'] as List? ?? ['Analyzing behavior...']).map((t) => _traitRow(t.toString())).toList(),
          ),
        ),
      ],
    );
  }

  Widget _genomeStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeSurface(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: themeTextDim(context), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Icon(icon, color: gold.withOpacity(0.5), size: 16),
            ],
          ),
          Text(value, style: const TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _traitRow(String trait) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF00FF66), size: 14),
          const SizedBox(width: 12),
          Text(trait, style: TextStyle(color: themeText(context), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _cardWrapper({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeSection(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: gold, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: themeText(context),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildCognitiveFitnessContent() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: themeSurface(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeBorder(context).withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Trophy Icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00FF66).withOpacity(0.1 * _pulseAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0C1B1E),
                        border: Border.all(
                          color: const Color(0xFF00FF66).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: Color(0xFF33635A),
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Title
            const Text(
              'COGNITIVE STATUS: NO DATA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            // Subtitle
            SizedBox(
              width: 300,
              child: Text(
                'Start trading to see your Behavioral Fitness Score. Minimum 1 trade required.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeTextDim(context).withOpacity(0.5),
                  fontSize: 13,
                  height: 1.6,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
