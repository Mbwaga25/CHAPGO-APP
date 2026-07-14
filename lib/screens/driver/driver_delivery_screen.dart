import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../widgets/driver_subpage_navbar.dart';
import 'driver_widgets.dart';

/// Standalone ChapDeliver screen (used for the /driver/delivery route).
class DriverDeliveryScreen extends StatelessWidget {
  const DriverDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: DriverDark.dark,
      appBar: AppBar(
        backgroundColor: DriverDark.dark,
        foregroundColor: DriverDark.white,
        elevation: 0,
        title: Text(lang.translate('delivery_title')),
      ),
      body: const DriverDeliveryView(),
      bottomNavigationBar: const DriverSubPageNavBar(activeIndex: 4),
    );
  }
}

/// ChapDeliver body — reused as the driver "Deliver" tab.
class DriverDeliveryView extends StatelessWidget {
  const DriverDeliveryView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Text(lang.translate('delivery_title'),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: DriverDark.white)),
        const SizedBox(height: 4),
        Text(lang.translate('delivery_subtitle'),
            style: TextStyle(fontSize: 13, color: DriverDark.grey)),
        const SizedBox(height: 16),

        // Coming soon banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DriverDark.gold.withValues(alpha: 0.10),
                DriverDark.green.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DriverDark.gold.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              const Text('📦', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(lang.translate('delivery_coming_soon'),
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: DriverDark.gold, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(lang.translate('delivery_coming_soon_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: DriverDark.grey, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Planned features
        DCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(lang.translate('delivery_planned_features'), DriverDark.grey),
              const SizedBox(height: 6),
              _feature('🔒', lang.translate('delivery_feat_escrow'), lang.translate('delivery_feat_escrow_desc')),
              _feature('📊', lang.translate('delivery_feat_pricing'), lang.translate('delivery_feat_pricing_desc')),
              _feature('⭐', lang.translate('delivery_feat_seller_score'), lang.translate('delivery_feat_seller_score_desc')),
              _feature('📍', lang.translate('delivery_feat_tracking'), lang.translate('delivery_feat_tracking_desc')),
              _feature('⚖️', lang.translate('delivery_feat_dispute'), lang.translate('delivery_feat_dispute_desc')),
              _feature('📌', lang.translate('delivery_feat_pindrop'), lang.translate('delivery_feat_pindrop_desc'), isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // How it works
        DCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(lang.translate('delivery_how_it_works'), DriverDark.gold),
              const SizedBox(height: 10),
              _step(1, lang.translate('delivery_step_1')),
              _step(2, lang.translate('delivery_step_2')),
              _step(3, lang.translate('delivery_step_3')),
              _step(4, lang.translate('delivery_step_4')),
              _step(5, lang.translate('delivery_step_5')),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Regulatory
        DCard(
          borderColor: DriverDark.red.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(lang.translate('delivery_regulatory'), DriverDark.red),
              const SizedBox(height: 8),
              Text(lang.translate('delivery_regulatory_desc'),
                  style: TextStyle(fontSize: 11, color: DriverDark.grey, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lang.translate('delivery_interest_recorded'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: DriverDark.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            icon: Icon(Icons.notifications_active_outlined, color: DriverDark.dark, size: 20),
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverDark.gold,
              foregroundColor: DriverDark.dark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: Text(lang.translate('delivery_register_interest'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DriverDark.dark)),
          ),
        ),
      ],
    );
  }

  Widget _label(String text, Color color) => Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 1));

  Widget _feature(String emoji, String title, String desc, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: DriverDark.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DriverDark.white)),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 11, color: DriverDark.grey, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: DriverDark.gold.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Text('$number',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DriverDark.gold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: DriverDark.white, height: 1.4))),
        ],
      ),
    );
  }
}
