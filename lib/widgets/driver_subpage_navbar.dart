import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';

class DriverSubPageNavBar extends StatelessWidget {
  final int activeIndex;
  final String type; // 'default', 'loans', 'stations'
  final ValueChanged<int>? onTap; // Custom onTap callback for in-place actions

  const DriverSubPageNavBar({
    super.key,
    this.activeIndex = -1,
    this.type = 'default',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    if (type == 'loans') {
      return BottomNavigationBar(
        currentIndex: activeIndex == -1 ? 0 : activeIndex,
        selectedItemColor: activeIndex == -1 ? AppTheme.grayLight : AppTheme.gold,
        unselectedItemColor: AppTheme.grayLight,
        backgroundColor: AppTheme.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (onTap != null) {
            onTap!(index);
            return;
          }
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/home',
              (route) => false,
              arguments: {'tab': 0},
            );
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/loans',
              (route) => route.isFirst,
            );
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/loans/list',
              (route) => route.isFirst,
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: lang.translate('preset_all') == 'All Time' ? 'Home' : 'Nyumbani',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            activeIcon: const Icon(Icons.add_circle),
            label: lang.translate('menu_apply_loan'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            activeIcon: const Icon(Icons.list_alt_rounded),
            label: lang.translate('menu_loan_list'),
          ),
        ],
      );
    } else if (type == 'stations') {
      return BottomNavigationBar(
        currentIndex: activeIndex == -1 ? 0 : activeIndex,
        selectedItemColor: activeIndex == -1 ? AppTheme.grayLight : AppTheme.gold,
        unselectedItemColor: AppTheme.grayLight,
        backgroundColor: AppTheme.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (onTap != null) {
            onTap!(index);
            return;
          }
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/home',
              (route) => false,
              arguments: {'tab': 0},
            );
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/stations/map',
              (route) => route.isFirst,
              arguments: {'tab': 0},
            );
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/stations/map',
              (route) => route.isFirst,
              arguments: {'tab': 1},
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: lang.translate('preset_all') == 'All Time' ? 'Home' : 'Nyumbani',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            activeIcon: const Icon(Icons.map),
            label: lang.translate('menu_stations_map'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt_outlined),
            activeIcon: const Icon(Icons.list),
            label: lang.translate('menu_stations_list'),
          ),
        ],
      );
    }

    // Default main dashboard tabs
    return BottomNavigationBar(
      currentIndex: activeIndex == -1 ? 0 : activeIndex,
      selectedItemColor: activeIndex == -1 ? AppTheme.grayLight : AppTheme.gold,
      unselectedItemColor: AppTheme.grayLight,
      backgroundColor: AppTheme.white,
      onTap: (index) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/driver/home',
          (route) => false,
          arguments: {'tab': index},
        );
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_outlined),
          activeIcon: const Icon(Icons.dashboard),
          label: lang.translate('overview'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          activeIcon: const Icon(Icons.account_balance_wallet),
          label: '${lang.translate('income')} / ${lang.translate('expenses')}',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.trending_up_outlined),
          activeIcon: const Icon(Icons.trending_up),
          label: lang.translate('boda_score'),
        ),
      ],
    );
  }
}
