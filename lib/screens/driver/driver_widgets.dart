import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ════════════════════════════════════════════════════════════
// Shared dark-theme UI widgets for the driver experience.
// Mirrors the Chapgo HTML prototype components.
// ════════════════════════════════════════════════════════════

/// Circular Boda Score ring (HTML `.score-ring`).
class DScoreRing extends StatelessWidget {
  final double value; // 0..1
  final String centerText;
  final String maxText;
  final Color color;
  final double size;
  const DScoreRing({
    super.key,
    required this.value,
    required this.centerText,
    required this.maxText,
    required this.color,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value.clamp(0, 1), color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerText,
                  style: TextStyle(
                      fontSize: size * 0.26,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1)),
              Text(maxText,
                  style: TextStyle(fontSize: 11, color: DriverDark.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  _RingPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    final bg = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

/// Small stat card (HTML `.stat-card`).
class DStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  const DStatCard({super.key, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: DriverDark.cardDeco(),
      child: Column(
        children: [
          FittedBox(
            child: Text(value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: valueColor ?? DriverDark.white)),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: DriverDark.grey, height: 1.3)),
        ],
      ),
    );
  }
}

/// 2-column responsive grid of stat cards.
class DStatGrid extends StatelessWidget {
  final List<DStatCard> cards;
  const DStatGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: cards,
    );
  }
}

/// Section header with optional trailing action (HTML `.section-head`).
class DSectionHead extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  const DSectionHead({super.key, required this.title, this.actionLabel, this.onAction, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DriverDark.white)),
          if (trailing != null)
            trailing!
          else if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: TextStyle(fontSize: 12, color: DriverDark.gold, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

/// Translucent card container (HTML `.card`).
class DCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? fill;
  const DCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: DriverDark.cardDeco(borderColor: borderColor, fill: fill),
      child: child,
    );
  }
}

/// Thin progress bar (HTML `.progress-bar`).
class DProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const DProgressBar({super.key, required this.value, required this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: const Color(0x14FFFFFF),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Pill badge (HTML `.badge-pill`).
class DBadge extends StatelessWidget {
  final String text;
  final Color color;
  const DBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Emoji/icon + title/meta + trailing list row (HTML `.list-item`).
class DListItem extends StatelessWidget {
  final String emoji;
  final Color? emojiBg;
  final String title;
  final String? meta;
  final Color? metaColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  const DListItem({
    super.key,
    required this.emoji,
    required this.title,
    this.emojiBg,
    this.meta,
    this.metaColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: emojiBg ?? DriverDark.card, borderRadius: BorderRadius.circular(10)),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DriverDark.white)),
                  if (meta != null) ...[
                    const SizedBox(height: 2),
                    Text(meta!, style: TextStyle(fontSize: 12, color: metaColor ?? DriverDark.grey, height: 1.3)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Two-value trailing for list rows (amount + unit).
class DTrailingValue extends StatelessWidget {
  final String amount;
  final String? unit;
  final Color? amountColor;
  const DTrailingValue({super.key, required this.amount, this.unit, this.amountColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: amountColor ?? DriverDark.white)),
        if (unit != null) Text(unit!, style: TextStyle(fontSize: 11, color: DriverDark.grey)),
      ],
    );
  }
}

/// A thin divider used inside cards.
class DRowDivider extends StatelessWidget {
  const DRowDivider({super.key});
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: Color(0x0AFFFFFF));
}

/// Demo-data disclaimer banner (HTML `.data-disclaimer`).
class DDisclaimer extends StatelessWidget {
  final String text;
  const DDisclaimer({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: DriverDark.gold.withValues(alpha: 0.08),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: DriverDark.gold, height: 1.5)),
    );
  }
}
