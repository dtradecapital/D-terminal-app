import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/shared.dart';

// ─── Data Models ────────────────────────────────────────────────
class TradeEntry {
  final String id;
  final String symbol;
  final String type; // BUY / SELL
  final double pnl;
  final double lots;
  final DateTime date;

  const TradeEntry({
    required this.id,
    required this.symbol,
    required this.type,
    required this.pnl,
    required this.lots,
    required this.date,
  });
}

class JournalNote {
  String id;
  String title;
  String content;
  DateTime date;
  JournalNote({required this.id, required this.title, required this.content, required this.date});
}

// ─── Riverpod Notifier for Notes ───────────────────────────────
class JournalNotesNotifier extends StateNotifier<List<JournalNote>> {
  JournalNotesNotifier() : super([]);

  void addNote(JournalNote note) {
    state = [note, ...state];
  }

  void updateNote(JournalNote note) {
    state = [
      for (final n in state)
        if (n.id == note.id) note else n
    ];
  }

  void deleteNote(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final journalNotesProvider = StateNotifierProvider<JournalNotesNotifier, List<JournalNote>>((ref) {
  return JournalNotesNotifier();
});

// ─── Main Widget ────────────────────────────────────────────────
class TradingJournalModal extends StatefulWidget {
  final List<TradeEntry> trades;
  const TradingJournalModal({super.key, required this.trades});

  static void show(BuildContext context, List<TradeEntry> trades) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => TradingJournalModal(trades: trades),
    );
  }

  @override
  State<TradingJournalModal> createState() => _TradingJournalModalState();
}

class _TradingJournalModalState extends State<TradingJournalModal> {
  int _tab = 0; // 0=Calendar 1=Analytics 2=Notes
  DateTime _calMonth = DateTime.now();
  String _calFilter = 'ALL';

  // ── helpers ──────────────────────────────────────────────
  List<TradeEntry> get _filtered {
    if (_calFilter == 'ALL') return widget.trades;
    return widget.trades.where((t) => t.symbol.contains(_calFilter)).toList();
  }

  Map<String, double> get _dailyPnl {
    final map = <String, double>{};
    for (final t in _filtered) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      map[key] = (map[key] ?? 0) + t.pnl;
    }
    return map;
  }

  // Analytics computations
  double get _totalPnl => widget.trades.fold(0, (s, t) => s + t.pnl);
  int get _totalTrades => widget.trades.length;
  int get _wins => widget.trades.where((t) => t.pnl > 0).length;
  int get _losses => widget.trades.where((t) => t.pnl < 0).length;
  double get _winRate => _totalTrades == 0 ? 0 : (_wins / _totalTrades * 100);
  double get _avgWin => _wins == 0 ? 0 : widget.trades.where((t) => t.pnl > 0).fold(0.0, (s, t) => s + t.pnl) / _wins;
  double get _avgLoss => _losses == 0 ? 0 : widget.trades.where((t) => t.pnl < 0).fold(0.0, (s, t) => s + t.pnl) / _losses;
  double get _profitFactor => _avgLoss == 0 ? 0 : _avgWin / _avgLoss.abs();
  int get _tradingDays => _dailyPnl.length;

  // symbol breakdown
  Map<String, double> get _symbolPnl {
    final map = <String, double>{};
    for (final t in widget.trades) {
      map[t.symbol] = (map[t.symbol] ?? 0) + t.pnl;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        backgroundColor: const Color(0xFF0E0E0E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderFaint, width: 1),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 680,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const Divider(color: borderFaint, height: 1),
              Flexible(
                child: _tab == 0
                    ? _buildCalendar()
                    : _tab == 1
                        ? _buildAnalytics()
                        : _buildNotes(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.book_outlined, color: gold, size: 14),
          const SizedBox(width: 6),
          Text(isNarrow ? 'JOURNAL' : 'TRADING JOURNAL',
              style: monoStyle(fontSize: 12, color: textHigh, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(width: 6),
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: gold, shape: BoxShape.circle)),
          const Spacer(),
          _tabBtn(Icons.calendar_month_outlined, 'CALENDAR', 0),
          const SizedBox(width: 6),
          _tabBtn(Icons.bar_chart_outlined, 'ANALYTICS', 1),
          const SizedBox(width: 6),
          _tabBtn(Icons.notes_outlined, 'NOTES', 2),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white38, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(IconData icon, String label, int idx) {
    final active = _tab == idx;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? gold.withOpacity(0.12) : Colors.transparent,
            border: Border.all(color: active ? gold : borderFaint),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: active ? gold : textMid),
              if (!isNarrow) ...[
                const SizedBox(width: 4),
                Text(label, style: textStyle(fontSize: 9, color: active ? gold : textMid, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── CALENDAR TAB ────────────────────────────────────────────
  Widget _buildCalendar() {
    final dailyPnl = _dailyPnl;
    final firstDay = DateTime(_calMonth.year, _calMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_calMonth.year, _calMonth.month);
    final startWeekday = firstDay.weekday % 7; // Sun=0
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nav + Filter row
          Row(
            children: [
              if (!isNarrow) ...[
                Text('TRADING CALENDAR', style: monoStyle(fontSize: 10, color: textMid, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(width: 8),
              ],
              _navBtn(Icons.chevron_left, () => setState(() => _calMonth = DateTime(_calMonth.year, _calMonth.month - 1))),
              const SizedBox(width: 4),
              Text(
                '${_monthName(_calMonth.month)} ${_calMonth.year}',
                style: monoStyle(fontSize: 12, color: textHigh, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              _navBtn(Icons.chevron_right, () => setState(() => _calMonth = DateTime(_calMonth.year, _calMonth.month + 1))),
              const Spacer(),
              _filterChip('ALL'),
              const SizedBox(width: 4),
              _filterChip('FOREX'),
              const SizedBox(width: 4),
              _filterChip('CRYPTO'),
            ],
          ),
          const SizedBox(height: 12),
          // Day headers
          Row(
            children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((d) => Expanded(
              child: Center(child: Text(d, style: monoStyle(fontSize: 8, color: textLow, fontWeight: FontWeight.bold))),
            )).toList(),
          ),
          const SizedBox(height: 6),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.9,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (ctx, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final date = DateTime(_calMonth.year, _calMonth.month, day);
              final key = '${date.year}-${date.month}-${date.day}';
              final pnl = dailyPnl[key];
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              return _calDay(day, pnl, isToday);
            },
          ),
          if (dailyPnl.isEmpty) ...[
            const SizedBox(height: 12),
            Center(child: Text('No trades this month. Start trading to see P&L on the calendar.',
                style: textStyle(fontSize: 11, color: textLow), textAlign: TextAlign.center)),
          ],
        ],
      ),
    );
  }

  Widget _calDay(int day, double? pnl, bool isToday) {
    Color borderColor = isToday ? gold : borderFaint;
    Color bgColor = const Color(0xFF111111);
    Color pnlColor = buyGreen;

    if (pnl != null) {
      pnlColor = pnl >= 0 ? buyGreen : sellRed;
      bgColor = pnl >= 0 ? buyGreen.withOpacity(0.06) : sellRed.withOpacity(0.06);
      borderColor = pnl >= 0 ? buyGreen.withOpacity(0.4) : sellRed.withOpacity(0.4);
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: isToday ? 1.5 : 1),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$day', style: monoStyle(fontSize: 9, color: isToday ? gold : textMid, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
              if (pnl != null) ...[
                const Spacer(),
                Container(width: 5, height: 5,
                    decoration: BoxDecoration(color: pnlColor, shape: BoxShape.circle)),
              ],
            ],
          ),
          if (pnl != null) ...[
            const Spacer(),
            Text(
              '${pnl >= 0 ? '+' : ''}\$${pnl.abs().toStringAsFixed(0)}',
              style: monoStyle(fontSize: 8, color: pnlColor, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(border: Border.all(color: borderFaint), borderRadius: BorderRadius.circular(4)),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: textMid),
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final active = _calFilter == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _calFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? gold.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: active ? gold : borderFaint),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: textStyle(fontSize: 9, color: active ? gold : textMid, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  String _monthName(int m) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  // ── ANALYTICS TAB ───────────────────────────────────────────
  Widget _buildAnalytics() {
    if (widget.trades.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart_outlined, color: textLow, size: 40),
              const SizedBox(height: 12),
              Text('No closed trades to analyze yet.\nStart trading to see your analytics here.',
                  style: textStyle(fontSize: 12, color: textLow), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards grid
          Row(children: [
            _statCard('+\$${_totalPnl.toStringAsFixed(2)}', 'NET P&L', _totalPnl >= 0 ? buyGreen : sellRed),
            const SizedBox(width: 8),
            _statCard('${_winRate.toStringAsFixed(0)}%', 'WIN RATE', _winRate >= 50 ? buyGreen : sellRed),
            const SizedBox(width: 8),
            _statCard('$_totalTrades', 'TOTAL TRADES', gold),
            const SizedBox(width: 8),
            _statCard(_profitFactor.toStringAsFixed(2), 'PROFIT FACTOR', _profitFactor >= 1 ? buyGreen : sellRed),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('+\$${_avgWin.toStringAsFixed(2)}', 'AVG WIN', buyGreen),
            const SizedBox(width: 8),
            _statCard('\$${_avgLoss.toStringAsFixed(2)}', 'AVG LOSS', sellRed),
            const SizedBox(width: 8),
            _statCard('$_wins W / $_losses L', 'WIN / LOSS', textMid),
            const SizedBox(width: 8),
            _statCard('$_tradingDays days', 'TRADING DAYS', textMid),
          ]),
          const SizedBox(height: 16),
          // Equity curve (bar chart)
          Text('EQUITY CURVE', style: labelCaps(color: textMid)),
          const SizedBox(height: 8),
          _buildEquityCurve(),
          const SizedBox(height: 16),
          // Symbol breakdown
          Text('ASSET BREAKDOWN', style: labelCaps(color: textMid)),
          const SizedBox(height: 8),
          ..._symbolPnl.entries.map((e) => _symbolRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: borderFaint),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: monoStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: textStyle(fontSize: 9, color: textLow)),
          ],
        ),
      ),
    );
  }

  Widget _buildEquityCurve() {
    // Build cumulative PnL per trade
    if (widget.trades.isEmpty) return const SizedBox();
    double cumulative = 0;
    final bars = widget.trades.map((t) { cumulative += t.pnl; return cumulative; }).toList();
    final maxVal = bars.reduce((a, b) => a.abs() > b.abs() ? a : b).abs().clamp(1.0, double.infinity);

    return Container(
      height: 80,
      decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(4), border: Border.all(color: borderFaint)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.asMap().entries.map((e) {
          final val = e.value;
          final h = ((val.abs() / maxVal) * 60).clamp(2.0, 60.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    color: val >= 0 ? buyGreen.withOpacity(0.7) : sellRed.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _symbolRow(String symbol, double pnl) {
    final maxPnl = _symbolPnl.values.map((v) => v.abs()).fold(1.0, (a, b) => a > b ? a : b);
    final fraction = (pnl.abs() / maxPnl).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF111111), border: Border.all(color: borderFaint), borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(symbol, style: textStyle(fontSize: 11, color: textHigh, fontWeight: FontWeight.bold))),
          Expanded(
            child: Stack(children: [
              Container(height: 6, decoration: BoxDecoration(color: bgElevated, borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(height: 6, decoration: BoxDecoration(
                  color: pnl >= 0 ? buyGreen : sellRed, borderRadius: BorderRadius.circular(3))),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Text('${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
              style: monoStyle(fontSize: 11, color: pnl >= 0 ? buyGreen : sellRed, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── NOTES TAB ───────────────────────────────────────────────
  Widget _buildNotes() {
    return Consumer(
      builder: (context, ref, child) {
        final notes = ref.watch(journalNotesProvider);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('TRADING NOTES', style: labelCaps(color: textMid)),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _addNote(ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.1),
                          border: Border.all(color: gold),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('+ ADD NOTE FOR TODAY', style: textStyle(fontSize: 9, color: gold, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notes, color: textLow, size: 36),
                            const SizedBox(height: 10),
                            Text('No notes yet. Click "ADD NOTE FOR TODAY" to start journaling.',
                                style: textStyle(fontSize: 11, color: textLow), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (ctx, i) => _noteCard(notes[i], ref),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _noteCard(JournalNote note, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: borderFaint),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(note.title, style: textStyle(fontSize: 12, color: textHigh, fontWeight: FontWeight.bold))),
              Text(_formatDate(note.date), style: monoStyle(fontSize: 9, color: textLow)),
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _editNote(note, ref),
                  child: const Icon(Icons.edit_outlined, size: 14, color: Colors.white38),
                ),
              ),
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => ref.read(journalNotesProvider.notifier).deleteNote(note.id),
                  child: const Icon(Icons.delete_outline, size: 14, color: sellRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 6),
          Text(note.content, style: textStyle(fontSize: 11, color: textMid, height: 1.5)),
        ],
      ),
    );
  }

  void _addNote(WidgetRef ref) => _openNoteEditor(null, ref);
  void _editNote(JournalNote note, WidgetRef ref) => _openNoteEditor(note, ref);

  void _openNoteEditor(JournalNote? existing, WidgetRef ref) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0E0E0E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: borderFaint)),
        child: SingleChildScrollView(
          child: Container(
            width: 440,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(existing == null ? 'NEW NOTE' : 'EDIT NOTE',
                        style: monoStyle(fontSize: 11, color: gold, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const Spacer(),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: Colors.white38, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('TITLE', style: labelCaps(color: textMid)),
                const SizedBox(height: 4),
                _inputField(titleCtrl, 'Enter note title...', maxLines: 1),
                const SizedBox(height: 10),
                Text('CONTENT', style: labelCaps(color: textMid)),
                const SizedBox(height: 4),
                _inputField(contentCtrl, 'Write your trading thoughts, emotions, observations...', maxLines: 5),
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
                            decoration: BoxDecoration(border: Border.all(color: borderFaint), borderRadius: BorderRadius.circular(4)),
                            alignment: Alignment.center,
                            child: Text('CANCEL', style: monoStyle(fontSize: 11, color: textMid, fontWeight: FontWeight.bold)),
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
                            String t = titleCtrl.text.trim();
                            final c = contentCtrl.text.trim();
                            if (c.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF1E0C0C),
                                  content: Text('Note content cannot be empty', style: TextStyle(color: Colors.redAccent)),
                                ),
                              );
                              return;
                            }
                            if (t.isEmpty) {
                              t = c.split('\n').first;
                              if (t.length > 25) {
                                t = '${t.substring(0, 22)}...';
                              }
                            }

                            if (existing == null) {
                              ref.read(journalNotesProvider.notifier).addNote(JournalNote(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: t, content: c, date: DateTime.now(),
                              ));
                            } else {
                              ref.read(journalNotesProvider.notifier).updateNote(JournalNote(
                                id: existing.id,
                                title: t, content: c, date: DateTime.now(),
                              ));
                            }
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(4)),
                            alignment: Alignment.center,
                            child: Text('SAVE NOTE', style: monoStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
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

  Widget _inputField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: borderFaint),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: textStyle(fontSize: 12, color: textHigh),
        cursorColor: gold,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: textStyle(fontSize: 12, color: textLow),
          contentPadding: const EdgeInsets.all(10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';
}
