import 'package:flutter/material.dart';
import '../config/theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (variant) {
      case BadgeVariant.active:
        return const Color(0xFFE8F5EB);
      case BadgeVariant.pending:
        return AppTheme.soft;
      case BadgeVariant.urgent:
        return const Color(0xFFF5E8E8);
      case BadgeVariant.inactive:
        return const Color(0xFFE8E8E8);
    }
  }

  Color get _textColor {
    switch (variant) {
      case BadgeVariant.active:
        return AppTheme.green;
      case BadgeVariant.pending:
        return AppTheme.gold;
      case BadgeVariant.urgent:
        return AppTheme.red;
      case BadgeVariant.inactive:
        return AppTheme.gray;
    }
  }
}

enum BadgeVariant { active, pending, urgent, inactive }
