import 'package:flutter/material.dart';

import '../models/app_screen.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final AppScreen current;
  final ValueChanged<AppScreen> onChanged;

  static const _items = <({AppScreen screen, IconData icon, String label})>[
    (screen: AppScreen.dashboard, icon: Icons.home_rounded, label: 'Ana Sayfa'),
    (screen: AppScreen.addMedication, icon: Icons.add_circle_outline_rounded, label: 'İlaç Ekle'),
    (screen: AppScreen.history, icon: Icons.calendar_month_rounded, label: 'Geçmiş'),
    (screen: AppScreen.pharmacy, icon: Icons.local_pharmacy_outlined, label: 'Eczaneler'),
    (screen: AppScreen.health, icon: Icons.monitor_heart_rounded, label: 'Sağlık'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xEBFFFFFF),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 12,
            color: Color(0x161F2937),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _items.map((item) {
            final isActive = item.screen == current;
            final color = isActive ? colorScheme.primary : const Color(0xFF6B7280);

            return _NavButton(
              icon: item.icon,
              label: item.label,
              isActive: isActive,
              color: color,
              onTap: () => onChanged(item.screen),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE0EAFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
