import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// PART 1: GLOBAL COLORS
// ==========================================
const Color bgDeep      = Color(0xFF080808); // deepest layer - screen bg
const Color bgCard      = Color(0xFF111111); // card surfaces
const Color bgElevated  = Color(0xFF1A1A1A); // modals, elevated cards
const Color bgInput     = Color(0xFF222222); // input fields, chips

const Color gold        = Color(0xFFF5A623); // CTAs, active states, key values
const Color goldDark    = Color(0xFFB87D1A); // pressed/hover states
const Color goldSubtle  = Color(0x1AF5A623); // 10% opacity gold tint (#F5A6231A)

const Color buyGreen    = Color(0xFF00C853); // BUY, positive
const Color sellRed     = Color(0xFFFF1744); // SELL, negative
const Color liveGreen   = Color(0xFF00E676); // LIVE dot, ONLINE status
const Color criticalRed = Color(0xFFFF3D00); // CRITICAL alerts
const Color warnAmber   = Color(0xFFFFAB00); // MEDIUM signals

const Color textHigh    = Color(0xFFEEEEEE); // headings, prices
const Color textMid     = Color(0xFF999999); // labels, subtitles
const Color textLow     = Color(0xFF555555); // hints, disabled
const Color textGold    = Color(0xFFF5A623); // highlighted values

const Color borderFaint  = Color(0xFF1E1E1E); // card outlines
const Color borderActive = Color(0xFFF5A623); // selected state

// Legacy aliases for backward compatibility with existing code
const Color bg = bgDeep;
const Color border = borderFaint;

bool isDark(BuildContext context) => true; // Force premium dark terminal theme
Color themeBg(BuildContext context) => bgDeep;
Color themeBorder(BuildContext context) => borderFaint;
Color themeSurface(BuildContext context) => bgCard;
Color themeSection(BuildContext context) => bgElevated;
Color themeText(BuildContext context) => textHigh;
Color themeTextDim(BuildContext context) => textMid;

// ==========================================
// PART 2: TYPOGRAPHY (FONTS & SCALE)
// ==========================================

TextStyle monoStyle({
  double fontSize = 12,
  Color color = textHigh,
  FontWeight fontWeight = FontWeight.normal,
  double? letterSpacing,
  double? height,
  FontStyle? fontStyle,
}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    fontStyle: fontStyle,
  );
}

TextStyle textStyle({
  double fontSize = 13,
  Color color = textHigh,
  FontWeight fontWeight = FontWeight.normal,
  double? letterSpacing,
  double? height,
  FontStyle? fontStyle,
}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    fontStyle: fontStyle,
  );
}

// Typography Scale helpers
// Typography Scale helpers
TextStyle priceXL({Color color = textHigh}) => monoStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color);
TextStyle priceMD({Color color = textHigh}) => monoStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color);
TextStyle priceSM({Color color = textHigh}) => monoStyle(fontSize: 12, fontWeight: FontWeight.normal, color: color);
TextStyle labelCaps({Color color = textMid}) => textStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: color);
TextStyle headingMD({Color color = textHigh}) => textStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color);
TextStyle bodyMD({Color color = textHigh}) => textStyle(fontSize: 12, fontWeight: FontWeight.normal, color: color);
TextStyle bodySM({Color color = textMid}) => textStyle(fontSize: 10, fontWeight: FontWeight.normal, color: color);

// ==========================================
// PART 3: REUSABLE COMPONENTS
// ==========================================

/// LiveDot - Pulsing green circle (6px) with glow + label text in green 10px.
class LiveDot extends StatefulWidget {
  final String label;
  const LiveDot({super.key, this.label = 'LIVE'});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: liveGreen.withOpacity(_animation.value),
                boxShadow: [
                  BoxShadow(
                    color: liveGreen.withOpacity(0.6 * _animation.value),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 5),
        Text(
          widget.label.toUpperCase(),
          style: monoStyle(fontSize: 10, color: liveGreen, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// GoldBadge - Pill shape, gold border 1px, gold text 9px SemiBold, horizontal pad 6px.
class GoldBadge extends StatelessWidget {
  final String text;
  const GoldBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: goldSubtle,
        border: Border.all(color: borderActive, width: 1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text.toUpperCase(),
        style: textStyle(fontSize: 9, color: textGold, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// StatusChip - bgElevated bg, radiusPill, icon 12px + label 9px, color tinted.
class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgElevated,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: textStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: chip,
        ),
      );
    }
    return chip;
  }
}

/// SectionCard - bgCard bg, radiusLg border, borderFaint border 1px, padding 10px 12px, margin horizontal 12px vertical 3px.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgCard,
        border: Border.all(color: borderFaint, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// GoldButton - Full gold fill, black text 13px SemiBold Inter, height 48px, radiusLg 8px, press: scale 0.97.
class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const GoldButton({super.key, required this.label, required this.onTap});

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        HapticFeedback.heavyImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: Transform.scale(
        scale: _scale,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// GhostButton - borderActive border 1px, gold text, transparent bg, height 28px, radiusMd 6px.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const GhostButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: borderActive, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: textStyle(fontSize: 10, color: textGold, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// FilterTab - Active: gold bg + black text. Inactive: bgElevated bg + textMid. radiusPill 20px, height 28px, horizontal pad 10px.
class FilterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const FilterTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active ? gold : bgElevated,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: textStyle(
              fontSize: 10,
              color: active ? Colors.black : textMid,
              fontWeight: active ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// SignalBadge - BUY: buyGreen fill, black text. SELL: sellRed fill, white text. radiusSm 4px, 6px horizontal pad, 2px vertical pad, 9px SemiBold.
class SignalBadge extends StatelessWidget {
  final String type;
  const SignalBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final bool isBuy = type.toUpperCase() == 'BUY';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isBuy ? buyGreen : sellRed,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.toUpperCase(),
        style: textStyle(
          fontSize: 9,
          color: isBuy ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// ConfidencePill - HIGH: criticalRed outline+text. MEDIUM: warnAmber. LOW: textLow. radiusSm 4px, outlined, 9px.
class ConfidencePill extends StatelessWidget {
  final String level;
  const ConfidencePill({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final String lvl = level.toUpperCase();
    final Color color = lvl == 'HIGH'
        ? criticalRed
        : lvl == 'MEDIUM'
            ? warnAmber
            : textLow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        lvl,
        style: monoStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// PassedChip - liveGreen outline + text, "✓ PASSED", radiusSm 4px, 9px font.
class PassedChip extends StatelessWidget {
  const PassedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: liveGreen, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, color: liveGreen, size: 9),
          const SizedBox(width: 3),
          Text(
            'PASSED',
            style: textStyle(fontSize: 9, color: liveGreen, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class VerticalAccentLine extends StatelessWidget {
  const VerticalAccentLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: themeBorder(context),
    );
  }
}
