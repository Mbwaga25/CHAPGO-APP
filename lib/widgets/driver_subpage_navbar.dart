import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/language_provider.dart';

/// The driver main menu (5 items), shown at the bottom of every driver
/// sub-screen so the rider can jump to any main section from anywhere.
///
/// Tabs map 1:1 to the driver home IndexedStack:
///   0 Home · 1 Scan · 2 My Money · 3 Credit · 4 Deliver · 5 Profile
///
/// [activeIndex] highlights one of the 5 items (0..4); pass -1 (default) when
/// the current sub-screen doesn't correspond to a main tab.
class DriverSubPageNavBar extends StatelessWidget {
  final int activeIndex;
  final String type; // retained for backwards compatibility (unused)
  final ValueChanged<int>? onTap;

  const DriverSubPageNavBar({
    super.key,
    this.activeIndex = -1,
    this.type = 'default',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final items = <List<dynamic>>[
      [Icons.home_filled, lang.translate('nav_home')],
      [Icons.qr_code_scanner, lang.translate('nav_scan')],
      [Icons.account_balance_wallet, lang.translate('nav_money')],
      [Icons.credit_score, lang.translate('nav_credit')],
      [Icons.local_shipping, lang.translate('deliver')],
      [Icons.person, lang.translate('nav_profile')],
    ];

    return Container(
      decoration: BoxDecoration(
        color: DriverDark.navy,
        border: Border(top: BorderSide(color: DriverDark.cardBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = activeIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (onTap != null) {
                      onTap!(i);
                      return;
                    }
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/driver/home',
                      (route) => false,
                      arguments: {'tab': i},
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i][0] as IconData,
                            size: 22, color: active ? DriverDark.gold : DriverDark.grey),
                        const SizedBox(height: 3),
                        Text(
                          items[i][1] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? DriverDark.gold : DriverDark.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
