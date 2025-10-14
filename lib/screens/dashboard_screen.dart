import 'package:flutter/material.dart';

import '../models/app_screen.dart';
import '../models/dashboard_stats.dart';
import '../models/medication.dart';
import '../models/medication_dose.dart';
import '../widgets/gradient_background.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.todayDoses,
    required this.onUpdateDoseStatus,
    required this.stats,
  });

  final ValueChanged<AppScreen> onNavigate;
  final List<MedicationDose> todayDoses;
  final void Function(MedicationDose dose, MedicationStatus status) onUpdateDoseStatus;
  final DashboardStats stats;

  Color _statusColor(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return const Color(0xFF16A34A);
      case MedicationStatus.pending:
        return const Color(0xFFEA580C);
      case MedicationStatus.upcoming:
        return const Color(0xFF2563EB);
      case MedicationStatus.skipped:
        return const Color(0xFFCA8A04);
      case MedicationStatus.missed:
        return const Color(0xFFDC2626);
    }
  }

  IconData _statusIcon(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Icons.check_circle_outline;
      case MedicationStatus.pending:
        return Icons.notifications_active_outlined;
      case MedicationStatus.upcoming:
        return Icons.timer_outlined;
      case MedicationStatus.skipped:
        return Icons.skip_next_rounded;
      case MedicationStatus.missed:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final hasMedications = todayDoses.isNotEmpty;

    return GradientBackground(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Günaydın, Deniz',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Bugünkü sağlık özetin hazır',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.verified_outlined,
                    iconColor: const Color(0xFF16A34A),
                    title: 'Kullanım oranı',
                    value: '${stats.adherenceRate.toStringAsFixed(0)}%',
                    subtitle: stats.totalToday == 0
                        ? 'Henüz kayıtlı ilaç yok'
                        : '${stats.takenToday}/${stats.totalToday} ilaç alındı',
                    valueFontSize: 20,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.event_available_outlined,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Sıradaki ilaç',
                    value: stats.nextDose != null
                        ? localizations.formatTimeOfDay(stats.nextDose!.timeOfDay)
                        : 'İlaç bulunmuyor',
                    subtitle: stats.nextDose != null
                        ? stats.nextDose!.medication.name
                        : 'Yaklaşan ilaç bulunmuyor',
                    valueFontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Bugünkü ilaçlar',
            trailing: TextButton(
              onPressed: () => onNavigate(AppScreen.addMedication),
              child: const Text('İlaç ekle'),
            ),
            child: hasMedications
                ? Column(
                    children: todayDoses.map((dose) {
                      final medication = dose.medication;
                      final timeLabel = localizations.formatTimeOfDay(dose.timeOfDay);
                      final color = _statusColor(dose.status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.medication_liquid_outlined,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medication.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${medication.dosage} • $timeLabel',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: color.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _statusIcon(dose.status),
                                        size: 16,
                                        color: color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        dose.status.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                PopupMenuButton<MedicationStatus>(
                                  tooltip: 'Durumu güncelle',
                                  onSelected: (value) => onUpdateDoseStatus(dose, value),
                                  itemBuilder: (context) {
                                    return [
                                      const PopupMenuItem(
                                        value: MedicationStatus.taken,
                                        child: Text('Alındı olarak işaretle'),
                                      ),
                                      const PopupMenuItem(
                                        value: MedicationStatus.skipped,
                                        child: Text('Dozu atla'),
                                      ),
                                      const PopupMenuItem(
                                        value: MedicationStatus.pending,
                                        child: Text('Beklemede işaretle'),
                                      ),
                                    ];
                                  },
                                  icon: const Icon(Icons.more_vert_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : _EmptyState(onNavigate: onNavigate),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Bugünkü ilerleme',
            child: stats.totalToday == 0
                ? const Text(
                    'İlerlemeni takip etmek için bir ilaç ekle.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${stats.takenToday} alındı',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          Text(
                            '${stats.remainingToday} kaldı',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: stats.completionRate.clamp(0.0, 1.0),
                          minHeight: 12,
                          backgroundColor: const Color(0xFFE0EAFF),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        stats.pendingToday == 0
                            ? 'Bugünkü tüm dozlar tamamlandı.'
                            : '${stats.pendingToday} doz için harekete geçmelisin.',
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Hızlı işlemler',
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _QuickActionButton(
                  label: 'İlaç ekle',
                  icon: Icons.add_circle_outline,
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  onTap: () => onNavigate(AppScreen.addMedication),
                ),
                _QuickActionButton(
                  label: 'Geçmişi görüntüle',
                  icon: Icons.calendar_today_outlined,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  outlineColor: const Color(0xFFBFDBFE),
                  onTap: () => onNavigate(AppScreen.history),
                ),
                _QuickActionButton(
                  label: 'Eczane bul',
                  icon: Icons.store_mall_directory_outlined,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF16A34A),
                  outlineColor: const Color(0xFFBBF7D0),
                  onTap: () => onNavigate(AppScreen.pharmacy),
                ),
                _QuickActionButton(
                  label: 'Profil ayarları',
                  icon: Icons.person_outline,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7C3AED),
                  outlineColor: const Color(0xFFE9D5FF),
                  onTap: () => onNavigate(AppScreen.profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? subtitle;
  final double? valueFontSize;
  final double? minHeight;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.subtitle,
    this.valueFontSize = 20,
    this.minHeight = 176,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight!),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      textAlign: TextAlign.start,
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.outlineColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? outlineColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: outlineColor != null
                ? Border.all(color: outlineColor!, width: 1.5)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: foregroundColor),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNavigate});

  final ValueChanged<AppScreen> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: const [
              Icon(Icons.medical_services_outlined, size: 40, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text(
                'Bugün için planlanmış ilaç yok.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Programını takip etmek için bir ilaç ekle.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => onNavigate(AppScreen.addMedication),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('İlk ilacını ekle'),
        ),
      ],
    );
  }
}
