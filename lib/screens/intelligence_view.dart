import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // AI Hub local state
  final TextEditingController _promptController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [
    {'role': 'system', 'content': 'Genome-Alpha cognitive intelligence core initialized. Enter query to begin real-time risk assessment or anomaly checks.'},
  ];
  String _activeModel = 'GEMINI-2.0-FLASH-EXP';

  // CSV journal local state
  bool _isCsvUploaded = false;

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
    _promptController.dispose();
    super.dispose();
  }

  void _showModuleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      isScrollControlled: true,
      builder: (ctx) {
        return _IntelligenceDirectoryModal(
          currentModule: _selectedModule,
          onSelect: (module) {
            setState(() {
              _selectedModule = module;
            });
          },
        );
      },
    );
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
          SizedBox(
            width: 260,
            child: _buildRegionalIndices(),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildMapArea(),
                const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _buildTopStatsMobile(),
          const SizedBox(height: 16),
          _buildActiveHotspots(),
          const SizedBox(height: 16),
          _buildAIGeneratedSignals(),
          const SizedBox(height: 16),
          _buildRegionalIndices(),
        ],
      );
    }
  }

  Widget _buildRegionalIndices() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: themeBorder(context)),
        color: themeSurface(context),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sidebarTitle('ACTIVE HOTSPOTS', '0'),
          const SizedBox(height: 12),
          _sidebarTitle('REGIONAL INDICES', ''),
          const SizedBox(height: 8),
          _indexItem('Iran', 88, sellRed),
          _indexItem('Saudi Arabia', 45, gold),
          _indexItem('Russia', 92, sellRed),
          _indexItem('Ukraine', 85, sellRed),
          _indexItem('Germany', 32, buyGreen),
          _indexItem('China', 58, gold),
          _indexItem('United States', 42, gold),
          _indexItem('Japan', 18, buyGreen),
        ],
      ),
    );
  }

  Widget _buildNewsTabContent() {
    final dateStr = _getDateString(_selectedNewsDate);
    final newsAsync = ref.watch(forexNewsProvider(dateStr));

    return Column(
      children: [
        _buildSectionHeader('BATTLESPACE NEWS FEED'),
        const SizedBox(height: 16),
        newsAsync.when(
          data: (data) {
            final List<dynamic> articles = data;
            
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
                if (MediaQuery.of(context).size.width > 900)
                SizedBox(
                  width: 220,
                  child: _buildRegionalIndices(),
                ),
                
                if (MediaQuery.of(context).size.width > 900)
                const SizedBox(width: 16),

                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sidebarTitle('FOREX NEWS', ''),
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

                if (MediaQuery.of(context).size.width > 1200) ...[
                  const SizedBox(width: 16),
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
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(color: gold),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Text('ERROR LOADING NEWS: $err',
                  style: monoStyle(color: sellRed, fontSize: 10)),
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? gold.withOpacity(0.05) : Colors.transparent,
          border: Border.all(color: isSelected ? gold : border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: monoStyle(
                color: isSelected ? gold : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _sidebarTitle(String title, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: monoStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
          if (count.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: sellRed.withOpacity(0.1), border: Border.all(color: sellRed.withOpacity(0.3)), borderRadius: BorderRadius.circular(2)),
            child: Text(count, style: monoStyle(color: sellRed, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _indexItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: monoStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: value / 100.0,
                backgroundColor: const Color(0xFF141414),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(value.toString(), style: monoStyle(color: gold, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'RECENT';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return 'RECENT';
    }
  }

  Widget _newsItemDetailed(dynamic item) {
    String time = _formatTime(item['published_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: themeSection(context),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['source']?.toString().toUpperCase() ?? 'ANALYSIS',
                  style: monoStyle(color: gold, fontSize: 8, fontWeight: FontWeight.bold)),
              Text(time, style: monoStyle(color: Colors.white38, fontSize: 8)),
            ],
          ),
          const SizedBox(height: 6),
          Text(item['headline'] ?? item['title'] ?? 'Strategic Risk Advisory',
              style: textStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.35)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                child: Text(item['category'] ?? 'GEOPOLITICAL', style: monoStyle(color: Colors.white54, fontSize: 7, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text('READ →', style: monoStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _geoIntelCard(String source, String title, String time, double tone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(source, style: monoStyle(color: gold, fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(title, style: textStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(time, style: monoStyle(color: Colors.white24, fontSize: 8)),
              Text('TONE: 0.0', style: monoStyle(color: Colors.white24, fontSize: 8)),
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
        color: themeSurface(context),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: Text(message, style: monoStyle(color: Colors.white24, fontSize: 10))),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text('NO CURRENT INTELLIGENCE FLUSHED',
            style: monoStyle(color: Colors.white24, fontSize: 10)),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.rss_feed, color: gold, size: 13),
            const SizedBox(width: 6),
            Text(title,
                style: monoStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ],
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isRefreshing ? null : _handleRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: themeSurface(context),
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(3)),
              child: Row(
                children: [
                  _isRefreshing
                      ? const SizedBox(
                          width: 9,
                          height: 9,
                          child: CircularProgressIndicator(
                              color: gold, strokeWidth: 1.5))
                      : const Icon(Icons.refresh, color: gold, size: 10),
                  const SizedBox(width: 4),
                  Text(_isRefreshing ? 'REFRESHING' : 'REFRESH',
                      style: monoStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarTabContent() {
    final calendarAsync = ref.watch(calendarProvider);

    return calendarAsync.when(
      data: (events) {
        if (events.isEmpty) return _emptyGeoIntel('NO ECONOMIC EVENTS REGISTERED');
        
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.04),
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('TIME', style: monoStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('CCY', style: monoStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold))),
                  Expanded(flex: 6, child: Text('ECONOMIC EVENT', style: monoStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('IMPACT', style: monoStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 3, child: Text('FORECAST', style: monoStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...events.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(e.time, style: monoStyle(color: Colors.white70, fontSize: 10))),
                  Expanded(flex: 2, child: Text(e.country, style: monoStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 6, child: Text(e.event, style: textStyle(color: Colors.white, fontSize: 11))),
                  Expanded(flex: 3, child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getImpactColor(e.impact).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: _getImpactColor(e.impact).withOpacity(0.3), width: 0.5),
                      ),
                      child: Text(e.impact.toUpperCase(), style: monoStyle(color: _getImpactColor(e.impact), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  )),
                  Expanded(flex: 3, child: Text(e.forecast, style: monoStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.right)),
                ],
              ),
            )),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: gold)),
      ),
      error: (e, stack) => _emptyGeoIntel('ERROR SYNCHRONIZING CALENDAR'),
    );
  }

  Color _getImpactColor(String impact) {
    switch (impact.toUpperCase()) {
      case 'HIGH': return sellRed;
      case 'MEDIUM': return gold;
      case 'LOW': return buyGreen;
      default: return Colors.white38;
    }
  }

  Widget _buildSignalsTabContent() {
    final signalsAsync = ref.watch(signalsProvider);

    return signalsAsync.when(
      data: (signals) {
        if (signals.isEmpty) return _emptyGeoIntel('NO ACTIVE SIGNALS DETECTED');
        
        return Column(
          children: signals.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeSurface(context),
              border: Border.all(color: themeBorder(context)),
              borderRadius: BorderRadius.circular(6),
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
                        Text(s.pair, style: monoStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(s.timeframe, style: monoStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: s.type == 'BUY' ? buyGreen.withOpacity(0.05) : sellRed.withOpacity(0.05),
                        border: Border.all(color: s.type == 'BUY' ? buyGreen : sellRed),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s.type, style: monoStyle(color: s.type == 'BUY' ? buyGreen : sellRed, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('"${s.headline}"', style: textStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  children: s.tags.map((tag) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), border: Border.all(color: border), borderRadius: BorderRadius.circular(2)),
                    child: Text(tag, style: monoStyle(color: Colors.white54, fontSize: 8)),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('CONFIDENCE', style: monoStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: LinearProgressIndicator(
                          value: s.confidence / 100.0,
                          backgroundColor: const Color(0xFF141414),
                          valueColor: const AlwaysStoppedAnimation<Color>(gold),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${s.confidence}%', style: monoStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
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
             Text('Risk Event Correlation Matrix', style: monoStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
             const SizedBox(height: 4),
             Text('Geopolitical event correlation coefficients. Green = Positive, Red = Inverse.', style: textStyle(color: Colors.white38, fontSize: 10)),
             const SizedBox(height: 16),
             SingleChildScrollView(
               scrollDirection: Axis.horizontal,
               child: Table(
                 defaultColumnWidth: const FixedColumnWidth(90),
                 border: TableBorder.all(color: border, width: 0.5),
                 children: [
                   TableRow(
                     children: [
                       const Padding(padding: EdgeInsets.all(10), child: Text('Country', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold))),
                       ...assets.map((asset) => Padding(padding: const EdgeInsets.all(10), child: Text(asset, style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
                     ],
                   ),
                   ...countries.map((country) => TableRow(
                     children: [
                       Padding(padding: const EdgeInsets.all(10), child: Text(country, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))),
                       ...assets.map((asset) {
                          final value = matrix[country]![asset]!;
                          return Container(
                            padding: const EdgeInsets.all(10),
                            color: _getCorrelationColor(value).withOpacity(0.08),
                            child: Text(
                              (value >= 0 ? '+' : '') + value.toStringAsFixed(2),
                              style: monoStyle(color: _getCorrelationColor(value), fontSize: 11, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          );
                       }),
                     ],
                   )),
                 ],
               ),
             ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: gold)),
      ),
      error: (e, stack) => _emptyGeoIntel('ERROR COMPILING MATRIX'),
    );
  }

  Color _getCorrelationColor(double val) {
    if (val > 0.3) return buyGreen;
    if (val < -0.3) return sellRed;
    return Colors.white38;
  }

  Widget _buildAIHubContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.smart_toy_outlined, color: gold, size: 16),
            const SizedBox(width: 8),
            Text(
              'COGNITIVE AI HUB',
              style: monoStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeSurface(context),
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CORE AGENTS', style: monoStyle(fontSize: 8, color: Colors.white38)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.circle, color: buyGreen, size: 6),
                        const SizedBox(width: 8),
                        Text('ALPHA • RUNNING', style: monoStyle(fontSize: 9, color: buyGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('THROUGHPUT', style: monoStyle(fontSize: 8, color: Colors.white38)),
                    const SizedBox(height: 2),
                    Text('148 tokens/s', style: monoStyle(fontSize: 9, color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeSurface(context),
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COGNITIVE MODEL', style: monoStyle(fontSize: 8, color: Colors.white38)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _activeModel = _activeModel == 'GEMINI-2.0-FLASH-EXP' ? 'GENOME-INFERENCE-V1' : 'GEMINI-2.0-FLASH-EXP';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: gold.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_activeModel, style: monoStyle(fontSize: 9, color: gold, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.swap_horiz, color: gold, size: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF0C0C0C),
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(12),
          child: ListView.builder(
            itemCount: _chatHistory.length,
            itemBuilder: (context, idx) {
              final msg = _chatHistory[idx];
              final isSys = msg['role'] == 'system';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isSys ? '🤖 ' : '👤 ', style: const TextStyle(fontSize: 12)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSys ? const Color(0xFF141414) : gold.withOpacity(0.04),
                          border: Border.all(color: isSys ? border : gold.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          msg['content']!,
                          style: textStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: _promptController,
                  style: monoStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Inquire intelligence network...',
                    hintStyle: monoStyle(color: Colors.white24, fontSize: 11),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_promptController.text.trim().isEmpty) return;
                setState(() {
                  _chatHistory.add({'role': 'user', 'content': _promptController.text});
                  final q = _promptController.text.toLowerCase();
                  _promptController.clear();
                  
                  String reply = 'Cognitive agents scanning. Correlation analysis is complete. Strong risk-off sentiment supports XAU/USD.';
                  if (q.contains('gold') || q.contains('xau')) {
                    reply = 'XAU/USD displays solid technical breakout above 2350. Order book depth shows institutional bids accumulating.';
                  } else if (q.contains('risk') || q.contains('correlation')) {
                    reply = 'High risk index detected on Middle East corridor. Correlation with Brent remains positive (+0.82). Recommend cautious position sizing.';
                  }
                  _chatHistory.add({'role': 'system', 'content': reply});
                });
              },
              icon: const Icon(Icons.send, color: gold, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: gold.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCSVAnalysesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined, color: gold, size: 16),
            const SizedBox(width: 8),
            Text(
              'CSV JOURNAL ANALYTICS',
              style: monoStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_isCsvUploaded) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E0E),
              border: Border.all(color: border, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Icon(Icons.upload_file, color: gold, size: 32),
                const SizedBox(height: 12),
                Text('UPLOAD TRADING JOURNAL CSV', style: monoStyle(fontSize: 10, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Supports MT4, MT5, and TradingView CSV exports', style: textStyle(fontSize: 9, color: Colors.white38)),
                const SizedBox(height: 16),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCsvUploaded = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('SELECT CSV FILE', style: monoStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeSection(context),
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: buyGreen, size: 14),
                        const SizedBox(width: 8),
                        Text('dtrade_history_may2026.csv', style: monoStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isCsvUploaded = false),
                      child: Text('RESET', style: monoStyle(fontSize: 8, color: sellRed)),
                    ),
                  ],
                ),
                const Divider(color: border, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _csvStatBox('WIN RATE', '67.4%', buyGreen),
                    _csvStatBox('PROFIT FACTOR', '2.05', gold),
                    _csvStatBox('AVG HOLD TIME', '38m', Colors.white70),
                    _csvStatBox('MAX DD', '-3.2%', sellRed),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('EQUITY PERFORMANCE CURVE', style: monoStyle(fontSize: 9, color: Colors.white38)),
          const SizedBox(height: 8),
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C0C),
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomPaint(
              painter: _CsvChartPainter(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _csvStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: monoStyle(fontSize: 8, color: Colors.white38)),
        const SizedBox(height: 4),
        Text(value, style: monoStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
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
      case 'AI HUB':
        return _buildAIHubContent();
      case 'CSV ANALYSES':
        return _buildCSVAnalysesContent();
      default:
        return _buildGeoIntelContent(isWide);
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
                    const Icon(Icons.bar_chart, color: gold, size: 18),
                    const SizedBox(width: 8),
                    Text('PATTERN INSIGHTS',
                        style: monoStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Behavioural pattern analytics engine',
                    style: textStyle(
                        color: Colors.white38,
                        fontSize: 11)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: themeSurface(context),
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: gold.withOpacity(0.05),
                        border: Border.all(color: gold.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics, color: gold, size: 12),
                        const SizedBox(width: 6),
                        Text('RULE BASED ANALYSIS',
                            style: monoStyle(
                                color: gold,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('30 MORE TRADES TO UNLOCK COGNITIVE ANALYTICS',
                        style: monoStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text('0/30',
                      style: monoStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: LinearProgressIndicator(
                  value: 0.0,
                  backgroundColor: const Color(0xFF141414),
                  valueColor: const AlwaysStoppedAnimation<Color>(gold),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
              color: themeSurface(context),
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: gold.withOpacity(0.05),
                    border: Border.all(color: gold.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(50)),
                child: const Icon(Icons.analytics_outlined, color: gold, size: 36),
              ),
              const SizedBox(height: 16),
              Text('PROFILING ARCHETYPE',
                  style: monoStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: 320,
                child: Text(
                  'Execute positions using the trading screen. Inference triggers automatically once enough trade density is logged.',
                  textAlign: TextAlign.center,
                  style: textStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTraderGenomeContent() {
    final sbUser = sb.Supabase.instance.client.auth.currentUser;
    if (sbUser == null) return _emptyGeoIntel('PLEASE LOGIN TO VIEW TRADER GENOME');

    final genomeAsync = ref.watch(userGenomeProvider(sbUser.id));

    return genomeAsync.when(
      data: (data) {
        if (data == null || data.isEmpty) {
          return _buildLockedGenome();
        }
        return _buildUnlockedGenome(data);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (err, stack) => _emptyGeoIntel('ERROR PARSING GENOME'),
    );
  }

  Widget _buildLockedGenome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
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
                      gold.withOpacity(0.1 * _pulseAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0C0C0C),
                      border: Border.all(
                        color: gold.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: gold,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'GENOME PROFILE LOCKED',
            style: monoStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Requires 30 trades to compile profile archetype.',
            style: textStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeSurface(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESS',
                      style: monoStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '0 / 30',
                      style: monoStyle(
                        color: buyGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: const Color(0xFF141414),
                    valueColor: const AlwaysStoppedAnimation<Color>(gold),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: gold.withOpacity(0.3)),
              ),
              child: const Icon(Icons.fingerprint, color: gold, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['archetype']?.toString().toUpperCase() ?? 'ARCHETYPE UNKNOWN',
                    style: monoStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('DNA mapped from ${data['trade_count'] ?? 0} trades',
                    style: monoStyle(color: gold, fontSize: 9)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _genomeStatCard('PRECISION', data['precision'] ?? '0%', Icons.gps_fixed),
            _genomeStatCard('RISK FACTOR', data['risk_tolerance'] ?? 'MODERATE', Icons.warning_amber),
            _genomeStatCard('RECOVERY RATE', data['recovery'] ?? '0%', Icons.autorenew),
          ],
        ),
      ],
    );
  }

  Widget _genomeStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeSurface(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: monoStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
              Icon(icon, color: gold.withOpacity(0.4), size: 14),
            ],
          ),
          Text(value, style: monoStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCognitiveFitnessContent() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: BoxDecoration(
          color: themeSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        buyGreen.withOpacity(0.1 * _pulseAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0C0C0C),
                        border: Border.all(
                          color: buyGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: buyGreen,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'COGNITIVE STATUS: NO DATA',
              style: monoStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 260,
              child: Text(
                'Minimum 1 executed trade required to compute cognitive metrics.',
                textAlign: TextAlign.center,
                style: textStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isRefreshing = false;

  void _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final dateStr = _getDateString(_selectedNewsDate);
    ref.invalidate(forexNewsProvider(dateStr));
    ref.invalidate(calendarProvider);
    ref.invalidate(signalsProvider);
    ref.invalidate(correlationMatrixProvider);
    ref.invalidate(situationalReportProvider);
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: themeSurface(context),
                  border: Border(right: BorderSide(color: themeBorder(context))),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      _intelModuleSidebarItem(Icons.public, 'GEOINTEL', 'GEO'),
                      _intelModuleSidebarItem(Icons.analytics_outlined, 'PATTERN INSIGHTS', 'PAT'),
                      _intelModuleSidebarItem(Icons.fingerprint, 'TRADER GENOME', 'GEN'),
                      _intelModuleSidebarItem(Icons.psychology_outlined, 'COGNITIVE FITNESS', 'COG'),
                      _intelModuleSidebarItem(Icons.smart_toy_outlined, 'AI HUB', 'HUB'),
                      _intelModuleSidebarItem(Icons.insert_drive_file_outlined, 'CSV ANALYSES', 'CSV'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTopStats(),
                      const SizedBox(height: 20),
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
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: themeSurface(context),
                  border: Border(bottom: BorderSide(color: themeBorder(context))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_outlined, color: gold, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          _selectedModule,
                          style: monoStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _showModuleSelector,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: gold.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'MODULES',
                              style: monoStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, color: gold, size: 12),
                          ],
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
                    _buildTopStatsMobile(),
                    const SizedBox(height: 16),
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

  Widget _intelModuleSidebarItem(IconData icon, String title, String shortName) {
    bool isSelected = _selectedModule == title;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedModule = title;
        }),
        child: Container(
          width: 70,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? gold.withOpacity(0.05) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? gold : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected ? gold : Colors.white38,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                shortName,
                style: monoStyle(
                  color: isSelected ? gold : Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
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
            // Compact GTI pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.04),
                border: Border.all(color: gold.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('GTI',
                      style: monoStyle(
                          color: Colors.white38, fontSize: 7, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Text('10.0',
                      style: monoStyle(
                          color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 5),
                  Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: buyGreen,
                      boxShadow: [BoxShadow(color: buyGreen.withOpacity(0.6), blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status pills inline
            _miniStatus('SIGNALS', '4', gold),
            const SizedBox(width: 6),
            _miniStatus('CRITICAL', '3', sellRed),
            const SizedBox(width: 6),
            _miniStatus('FEEDS', '18', buyGreen),
            const Spacer(),
            if (_selectedModule == 'GEOINTEL')
              SingleChildScrollView(
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
          ],
        ),
        const SizedBox(height: 6),
        const Divider(color: border, height: 8),
      ],
    );
  }

  Widget _miniStatus(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: monoStyle(color: Colors.white38, fontSize: 7, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(value, style: monoStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
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
            color: themeSurface(context),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Text('GLOBAL TENSION INDEX',
                  style: monoStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('10.0', style: monoStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (_selectedModule == 'GEOINTEL') ...[
          const SizedBox(height: 12),
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
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? gold.withOpacity(0.04) : Colors.transparent,
            border: Border(
                bottom: BorderSide(
                    color: isSelected ? gold : Colors.transparent, width: 1.5)),
          ),
          child: Text(label,
              style: monoStyle(
                  color: isSelected ? gold : Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }



  Widget _buildActiveHotspots() {
    return Container(
      decoration: BoxDecoration(
        color: themeSurface(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVE HOTSPOTS', style: monoStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: sellRed.withOpacity(0.1), border: Border.all(color: sellRed.withOpacity(0.3)), borderRadius: BorderRadius.circular(3)),
                  child: Text('3', style: monoStyle(color: sellRed, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(color: border, height: 1),
          _hotspotItem('WAR / GEO • IRAN', 'Hormuz Strait Monitoring', 88),
          _hotspotItem('WAR / GEO • UKRAINE', 'Energy Grid Interdictions', 82),
          _hotspotItem('WAR / GEO • RUSSIA', 'Capital Flight Restrictions', 76),
        ],
      ),
    );
  }

  Widget _hotspotItem(String category, String title, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category, style: monoStyle(color: sellRed, fontSize: 7, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(title, style: textStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('RISK:', style: monoStyle(color: Colors.white38, fontSize: 7)),
              const SizedBox(width: 4),
              Text(score.toString(), style: monoStyle(color: gold, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return _GeoIntelMapWidget(
      pulseController: _pulseController,
      pulseAnimation: _pulseAnimation,
      hoveredRegion: _hoveredRegion,
      hoveredRisk: _hoveredRisk,
      hoveredPos: _hoveredPos,
      onHover: (region, risk, pos) {
        setState(() {
          _hoveredRegion = region;
          _hoveredRisk = risk;
          _hoveredPos = pos;
        });
      },
      onHoverExit: () {
        setState(() {
          _hoveredRegion = null;
        });
      },
      gdeltAsync: ref.watch(gdeltStreamProvider),
      buildInteractivePopup: _hoveredRegion != null ? _buildInteractivePopup : null,
    );
  }



  Widget _buildInteractivePopup() {
    return Positioned(
      left: (_hoveredPos?.dx ?? 0),
      top: (_hoveredPos?.dy ?? 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _hoveredRegion != null ? 1.0 : 0.0,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.95),
            border: Border.all(color: gold.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_hoveredRegion!.toUpperCase(),
                  style: monoStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Risk Index:', style: monoStyle(color: Colors.white38, fontSize: 8)),
                  Text('$_hoveredRisk', style: monoStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
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
        color: themeSurface(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: gold, size: 16),
                  const SizedBox(width: 8),
                  Text('AI SITUATIONAL REPORT',
                      style: monoStyle(
                          color: gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.circle, color: buyGreen, size: 6),
                  const SizedBox(width: 6),
                  Text('ACTIVE', style: monoStyle(color: buyGreen, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C0C),
              border: const Border(left: BorderSide(color: gold, width: 2)),
            ),
            child: ref.watch(situationalReportProvider).when(
                  data: (report) => Text(
                    report,
                    style: textStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: gold, strokeWidth: 1.5)),
                  error: (err, _) => Text(
                    'AI report feeds offline. Monitoring risk matrices continuously.',
                    style: monoStyle(color: Colors.white38, fontSize: 9),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GeoIntel World Map Widget
// Renders an SVG world map with country risk color-coding, pulsing GDELT
// hotspot markers, elliptical gold border, and GDELT LIVE badge.
// ─────────────────────────────────────────────────────────────────────────────

class _GeoIntelMapWidget extends StatefulWidget {
  final AnimationController pulseController;
  final Animation<double> pulseAnimation;
  final String? hoveredRegion;
  final int? hoveredRisk;
  final Offset? hoveredPos;
  final void Function(String region, int risk, Offset pos) onHover;
  final VoidCallback onHoverExit;
  final AsyncValue<GdeltData> gdeltAsync;
  final Widget Function()? buildInteractivePopup;

  const _GeoIntelMapWidget({
    required this.pulseController,
    required this.pulseAnimation,
    required this.hoveredRegion,
    required this.hoveredRisk,
    required this.hoveredPos,
    required this.onHover,
    required this.onHoverExit,
    required this.gdeltAsync,
    this.buildInteractivePopup,
  });

  @override
  State<_GeoIntelMapWidget> createState() => _GeoIntelMapWidgetState();
}

class _GeoIntelMapWidgetState extends State<_GeoIntelMapWidget> with TickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;
  late AnimationController _gdeltDotController;
  late Animation<double> _gdeltDotAnimation;

  Color _getRiskColor(double score) {
    if (score >= 9) return const Color(0xFF8B2635); // deep crimson
    if (score >= 7) return const Color(0xFFB85C38); // dark orange
    if (score >= 5) return const Color(0xFF8B6914); // dark amber
    if (score >= 3) return const Color(0xFF2D6A4F); // forest green
    return const Color(0xFF1A3A2A);                 // dark green
  }

  // Hotspots with lat/lon → map normalized coords (0-1 range)
  // Mercator-like projection: x = (lon+180)/360, y = (90-lat)/180
  Offset _latLonToMap(double lat, double lon) {
    final x = (lon + 180) / 360;
    final y = (90 - lat) / 180;
    return Offset(x, y);
  }

  // Hardcoded hotspot list with geo coords from GDELT fallback
  static const List<Map<String, dynamic>> _hotspots = [
    {'name': 'United States', 'lat': 38.0, 'lon': -97.0, 'score': 4.2, 'label': 'US', 'color': Color(0xFF4A90E2)},
    {'name': 'Venezuela', 'lat': 8.0, 'lon': -66.0, 'score': 6.0, 'label': 'VE', 'color': Color(0xFF10B981)},
    {'name': 'Germany', 'lat': 51.16, 'lon': 10.45, 'score': 2.0, 'label': 'DE', 'color': Color(0xFFF5A623)},
    {'name': 'Ukraine', 'lat': 49.0, 'lon': 31.0, 'score': 8.5, 'label': 'UA', 'color': Color(0xFFFF1744)},
    {'name': 'Russia', 'lat': 58.0, 'lon': 45.0, 'score': 9.2, 'label': 'RU', 'color': Color(0xFF8B2635)},
    {'name': 'Turkey', 'lat': 39.0, 'lon': 35.0, 'score': 5.0, 'label': 'TR', 'color': Color(0xFFF5A623)},
    {'name': 'Iran', 'lat': 32.0, 'lon': 53.0, 'score': 8.8, 'label': 'IR', 'color': Color(0xFF10B981)},
    {'name': 'Saudi Arabia', 'lat': 24.0, 'lon': 45.0, 'score': 4.5, 'label': 'SA', 'color': Color(0xFF10B981)},
    {'name': 'China', 'lat': 36.0, 'lon': 104.0, 'score': 5.8, 'label': 'CN', 'color': Color(0xFFF5A623)},
    {'name': 'North Korea', 'lat': 40.3, 'lon': 127.5, 'score': 7.5, 'label': 'KP', 'color': Color(0xFFFF1744)},
    {'name': 'Japan', 'lat': 36.0, 'lon': 138.0, 'score': 1.8, 'label': 'JP', 'color': Color(0xFF4A90E2)},
  ];

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_ringController);

    _gdeltDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _gdeltDotAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_gdeltDotController);
  }

  @override
  void dispose() {
    _ringController.dispose();
    _gdeltDotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = (w * 0.42).clamp(200.0, 300.0);

        // Merge GDELT hotspots if live
        final List<Map<String, dynamic>> hotspots = List.from(_hotspots);
        widget.gdeltAsync.whenData((gdelt) {
          // Update scores from GDELT live data
          // Merge live GDELT geo events (first 5 unique locations)
          int gdeltAdded = 0;
          for (final ghs in gdelt.hotspots) {
            if (gdeltAdded >= 5) break;
            final ghLat = ghs.lat;
            final ghLon = ghs.lon;
            final exists = hotspots.any((entry) {
              final eLat = entry['lat'] as double;
              final eLon = entry['lon'] as double;
              return (eLat - ghLat).abs() < 2.0 && (eLon - ghLon).abs() < 2.0;
            });
            if (!exists) {
              hotspots.add({
                'name': ghs.locationName,
                'lat': ghs.lat,
                'lon': ghs.lon,
                'score': 6.5,
                'label': '${ghs.eventCount}',
              });
              gdeltAdded++;
            }
          }
        });


        final isLive = widget.gdeltAsync.whenOrNull(data: (d) => d.isLive) ?? false;

        return Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: const Color(0xFF080808), // near-black background
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // ── Radar Grid Lines ──
              Positioned.fill(
                child: CustomPaint(painter: _RadarGridPainter()),
              ),

              // ── World Map SVG (color overlay) ──
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Stack(
                    children: [
                      // Base map image with high opacity
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/world_map.png',
                          fit: BoxFit.fill,
                          opacity: const AlwaysStoppedAnimation(0.9),
                        ),
                      ),
                      // Risk overlay – colored rectangles for major regions
                      ..._buildCountryRiskOverlays(w, h),
                    ],
                  ),
                ),
              ),

              // ── Scanline ──
              AnimatedBuilder(
                animation: widget.pulseController,
                builder: (context, _) {
                  return Positioned(
                    top: h * widget.pulseController.value,
                    left: 0, right: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          gold.withOpacity(0.15),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  );
                },
              ),

              // ── Hotspot Markers ──
              ...hotspots.map((hs) {
                final pos = _latLonToMap(hs['lat'] as double, hs['lon'] as double);
                final px = pos.dx * w;
                final py = pos.dy * h;
                final score = (hs['score'] as double);
                final isHigh = score >= 7.5;
                final dotColor = hs['color'] as Color? ?? (isHigh ? const Color(0xFFFF1744) : gold);

                return Positioned(
                  left: px - 12,
                  top: py - 12,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => widget.onHover(
                      hs['name'] as String,
                      score.round(),
                      Offset(px + 8, py - 36),
                    ),
                    onExit: (_) => widget.onHoverExit(),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: AnimatedBuilder(
                        animation: _ringAnimation,
                        builder: (context, _) {
                          final ring = _ringAnimation.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing outer ring (light, no highlight)
                              Container(
                                width: 8 + 20 * ring,
                                height: 8 + 20 * ring,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: dotColor.withOpacity((1 - ring) * 0.25),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              // Inner solid dot (light opacity, no glow)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dotColor.withOpacity(0.75),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),

              // ── Country Code Labels ──
              ...hotspots.map((hs) {
                final pos = _latLonToMap(hs['lat'] as double, hs['lon'] as double);
                final px = pos.dx * w;
                final py = pos.dy * h;
                final code = hs['label'] as String;
                final score = (hs['score'] as double);
                final isHigh = score >= 7.5;
                final dotColor = hs['color'] as Color? ?? (isHigh ? const Color(0xFFFF1744) : gold);
                return Positioned(
                  left: px + 8,
                  top: py - 12,
                  child: IgnorePointer(
                    child: Text(
                      code,
                      style: monoStyle(
                        color: dotColor.withOpacity(0.75),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),

              // ── Hover Popup ──
              if (widget.hoveredRegion != null && widget.buildInteractivePopup != null)
                widget.buildInteractivePopup!(),

              // ── GDELT LIVE Badge ──
              Positioned(
                top: 10,
                left: 12,
                child: AnimatedBuilder(
                  animation: _gdeltDotAnimation,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: buyGreen.withOpacity(_gdeltDotAnimation.value),
                            boxShadow: [
                              BoxShadow(
                                color: buyGreen.withOpacity(0.5 * _gdeltDotAnimation.value),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isLive ? 'GDELT LIVE · 18 FEEDS' : 'GDELT · CACHED',
                          style: monoStyle(
                            fontSize: 8,
                            color: isLive ? buyGreen : Colors.white38,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.06,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Risk Legend ──
              Positioned(
                bottom: 10,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendDot(const Color(0xFF8B2635), '9–10'),
                    const SizedBox(width: 8),
                    _legendDot(const Color(0xFFB85C38), '7–8'),
                    const SizedBox(width: 8),
                    _legendDot(const Color(0xFF8B6914), '5–6'),
                    const SizedBox(width: 8),
                    _legendDot(const Color(0xFF2D6A4F), '1–4'),
                  ],
                ),
              ),

              // ── Active Hotspots Count Badge ──
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: sellRed.withOpacity(0.08),
                    border: Border.all(color: sellRed.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: sellRed, size: 9),
                      const SizedBox(width: 3),
                      Text('${hotspots.where((h) => (h['score'] as double) >= 7.5).length} CRITICAL',
                        style: monoStyle(color: sellRed, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 3),
        Text(label, style: monoStyle(color: Colors.white38, fontSize: 7)),
      ],
    );
  }

  List<Widget> _buildCountryRiskOverlays(double w, double h) {
    // Approximate country bounding boxes as highlighted overlays
    // [name, score, left%, top%, width%, height%]
    const regions = [
      ['Russia', 9.2, 0.53, 0.08, 0.20, 0.22],
      ['Ukraine', 8.5, 0.537, 0.235, 0.04, 0.04],
      ['Iran', 8.8, 0.592, 0.29, 0.04, 0.05],
      ['Israel/Gaza', 8.8, 0.558, 0.307, 0.015, 0.025],
      ['North Korea', 7.5, 0.795, 0.225, 0.02, 0.03],
      ['Afghanistan', 8.0, 0.629, 0.268, 0.028, 0.04],
      ['Syria', 7.0, 0.556, 0.278, 0.018, 0.03],
      ['Yemen', 7.5, 0.575, 0.35, 0.025, 0.03],
      ['Somalia', 7.5, 0.574, 0.408, 0.02, 0.04],
      ['Libya', 6.5, 0.517, 0.31, 0.03, 0.04],
      ['China', 5.8, 0.72, 0.22, 0.10, 0.16],
      ['India', 5.0, 0.647, 0.32, 0.06, 0.10],
      ['Pakistan', 5.5, 0.632, 0.292, 0.04, 0.06],
      ['Sudan', 6.0, 0.545, 0.35, 0.03, 0.05],
      ['Venezuela', 6.0, 0.295, 0.39, 0.03, 0.04],
      ['United States', 4.2, 0.10, 0.18, 0.20, 0.20],
      ['Brazil', 2.0, 0.295, 0.45, 0.12, 0.18],
      ['Australia', 2.0, 0.77, 0.55, 0.12, 0.18],
      ['Germany', 2.0, 0.496, 0.205, 0.02, 0.03],
      ['UK', 2.0, 0.47, 0.19, 0.015, 0.03],
      ['France', 2.0, 0.476, 0.215, 0.02, 0.04],
      ['Turkey', 5.0, 0.555, 0.255, 0.04, 0.04],
      ['Kazakhstan', 4.5, 0.63, 0.20, 0.07, 0.08],
      ['Nigeria', 5.5, 0.487, 0.40, 0.03, 0.05],
      ['DR Congo', 6.5, 0.535, 0.435, 0.04, 0.07],
      ['Myanmar', 7.0, 0.72, 0.34, 0.025, 0.04],
    ];

    return regions.map((r) {
      final name = r[0] as String;
      final score = (r[1] as double);
      final color = _getRiskColor(score);
      final isHovered = widget.hoveredRegion == name;
      
      return Positioned(
        left: (r[2] as double) * w,
        top: (r[3] as double) * h,
        width: (r[4] as double) * w,
        height: (r[5] as double) * h,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (event) {
            final localX = (r[2] as double) * w + (r[4] as double) * w + 8;
            final localY = (r[3] as double) * h - 30;
            widget.onHover(name, score.round(), Offset(localX, localY));
          },
          onExit: (_) => widget.onHoverExit(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: color.withOpacity(isHovered ? 0.15 : (score >= 7 ? 0.08 : 0.04)),
              border: Border.all(
                color: isHovered ? gold.withOpacity(0.5) : color.withOpacity(0.08),
                width: isHovered ? 1.0 : 0.5,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Radar grid painter
class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2030)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal lines
    for (int i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (int i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Gold ellipse border painter
class _EllipseGoldBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5A623).withOpacity(0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    
    // Inset to align perfectly with the map image's built-in ellipse
    final rect = Rect.fromLTWH(
      size.width * 0.043,
      size.height * 0.088,
      size.width * 0.914,
      size.height * 0.824,
    );
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CsvChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gold.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.7, size.width * 0.4, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.5, size.width * 0.75, size.height * 0.25)
      ..lineTo(size.width, size.height * 0.15);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gold.withOpacity(0.12), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IntelligenceDirectoryModal extends StatefulWidget {
  final String currentModule;
  final ValueChanged<String> onSelect;

  const _IntelligenceDirectoryModal({
    required this.currentModule,
    required this.onSelect,
  });

  @override
  State<_IntelligenceDirectoryModal> createState() => _IntelligenceDirectoryModalState();
}

class _IntelligenceDirectoryModalState extends State<_IntelligenceDirectoryModal> {
  late String _activeTempModule;

  @override
  void initState() {
    super.initState();
    _activeTempModule = widget.currentModule;
  }

  String _mapUiToCodeName(String uiName) {
    switch (uiName) {
      case 'GEOINTEL': return 'GEOINTEL';
      case 'PATTERN': return 'PATTERN INSIGHTS';
      case 'GENOME': return 'TRADER GENOME';
      case 'COGNITIVE': return 'COGNITIVE FITNESS';
      case 'AI HUB': return 'AI HUB';
      case 'CSV INTEL': return 'CSV ANALYSES';
      default: return uiName;
    }
  }

  String _mapCodeToUiName(String codeName) {
    switch (codeName) {
      case 'GEOINTEL': return 'GEOINTEL';
      case 'PATTERN INSIGHTS': return 'PATTERN';
      case 'TRADER GENOME': return 'GENOME';
      case 'COGNITIVE FITNESS': return 'COGNITIVE';
      case 'AI HUB': return 'AI HUB';
      case 'CSV ANALYSES': return 'CSV INTEL';
      default: return codeName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUiName = _mapCodeToUiName(_activeTempModule);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 245,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          border: Border(
            top: BorderSide(color: Color(0xFF222222), width: 1),
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: gold, width: 1.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'D',
                            style: monoStyle(fontSize: 9, color: gold, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'INTELLIGENCE DIRECTORY',
                          style: textStyle(
                            fontSize: 9,
                            color: gold,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: const Icon(Icons.close, size: 10, color: Color(0xFF666666)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildGridItem('GEOINTEL', Icons.public, 'Risk matrix', true, activeUiName)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildGridItem('PATTERN', Icons.trending_up, 'Behavior', true, activeUiName)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildGridItem('GENOME', Icons.fingerprint, 'Identity', false, activeUiName)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _buildGridItem('COGNITIVE', Icons.psychology_outlined, 'Psychometric', false, activeUiName)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildGridItem('AI HUB', Icons.smart_toy_outlined, 'Dashboard', true, activeUiName)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildGridItem('CSV INTEL', Icons.insert_drive_file_outlined, 'Reports', false, activeUiName)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: textStyle(fontSize: 8, color: const Color(0xFF555555), letterSpacing: 0.6),
                        children: [
                          const TextSpan(text: 'ACTIVE '),
                          TextSpan(
                            text: '3',
                            style: monoStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: textStyle(fontSize: 8, color: const Color(0xFF555555), letterSpacing: 0.6),
                        children: [
                          const TextSpan(text: 'GTI '),
                          TextSpan(
                            text: '71.4',
                            style: monoStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const LiveDot(label: 'LIVE'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(String name, IconData icon, String subtitle, bool isLive, String activeName) {
    final isSelected = name == activeName;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        setState(() {
          _activeTempModule = _mapUiToCodeName(name);
        });
        await Future.delayed(const Duration(milliseconds: 120));
        if (mounted) {
          widget.onSelect(_mapUiToCodeName(name));
          Navigator.pop(context);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF141008) : const Color(0xFF111111),
          border: Border.all(color: isSelected ? gold : const Color(0xFF222222), width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? gold : const Color(0xFF666666),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: textStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isSelected ? gold : const Color(0xFF888888),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
