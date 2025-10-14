import 'package:flutter/material.dart';

import '../models/app_screen.dart';
import '../models/medication.dart';
import '../models/medication_dose.dart';
import '../widgets/gradient_background.dart';

class MedicationHistoryScreen extends StatefulWidget {
  const MedicationHistoryScreen({
    super.key,
    required this.onNavigate,
    required this.dosesForDate,
    required this.availableDates,
    required this.onUpdateDoseStatus,
  });

  final ValueChanged<AppScreen> onNavigate;
  final List<MedicationDose> Function(DateTime date) dosesForDate;
  final List<DateTime> availableDates;
  final void Function(MedicationDose dose, MedicationStatus status) onUpdateDoseStatus;

  @override
  State<MedicationHistoryScreen> createState() => _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState extends State<MedicationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = onlyDate(DateTime.now());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    final dates = widget.availableDates;
    final hasAnyDose = dates.isNotEmpty;

    if (!hasAnyDose && _tabController.index == 1) {
      _tabController.index = 0;
    }

    final timelineDates = dates.isEmpty
        ? <DateTime>[]
        : dates
            .toSet()
            .toList()
            ..sort((a, b) => b.compareTo(a));

    final calendarFirstDate = dates.isEmpty
        ? DateTime.now().subtract(const Duration(days: 7))
        : dates.reduce((value, element) => value.isBefore(element) ? value : element);
    final calendarLastDate = dates.isEmpty
        ? DateTime.now().add(const Duration(days: 7))
        : dates.reduce((value, element) => value.isAfter(element) ? value : element);

    var adjustedSelectedDate = _selectedDate;
    if (adjustedSelectedDate.isBefore(calendarFirstDate)) {
      adjustedSelectedDate = calendarFirstDate;
    }
    if (adjustedSelectedDate.isAfter(calendarLastDate)) {
      adjustedSelectedDate = calendarLastDate;
    }
    if (adjustedSelectedDate != _selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedDate = adjustedSelectedDate);
        }
      });
    }

    final selectedDoses = widget.dosesForDate(adjustedSelectedDate);

    return GradientBackground(
      includeSafeArea: false,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => widget.onNavigate(AppScreen.dashboard),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'İlaç geçmişi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filtreler yakında eklenecek.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.insights_outlined, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text(
                            'Genel bakış',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hasAnyDose
                            ? 'Seçilen zaman aralığında ilaç uyumunu incele.'
                            : 'Geçmişini oluşturmak için bir ilaç ekle.',
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Color(0xFFE0EAFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelColor: const Color(0xFF1D4ED8),
                  unselectedLabelColor: const Color(0xFF6B7280),
                  tabs: const [
                    Tab(text: 'Zaman çizelgesi'),
                    Tab(text: 'Takvim görünümü'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  hasAnyDose
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: timelineDates.length,
                          itemBuilder: (context, index) {
                            final date = timelineDates[index];
                            final doses = widget.dosesForDate(date);
                            if (doses.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final takenCount =
                                doses.where((dose) => dose.status == MedicationStatus.taken).length;
                            final label = localizations.formatFullDate(date);

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == timelineDates.length - 1 ? 32 : 16,
                              ),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFE0EAFF),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$takenCount/${doses.length} alındı',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ...doses.map(
                                        (dose) => _HistoryDoseTile(
                                          dose: dose,
                                          statusColor: _statusColor(dose.status),
                                          statusIcon: _statusIcon(dose.status),
                                          onUpdate: widget.onUpdateDoseStatus,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : _EmptyHistoryState(onNavigate: widget.onNavigate),
                  Column(
                    children: [
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tarih seç',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CalendarDatePicker(
                                initialDate: adjustedSelectedDate,
                                firstDate: calendarFirstDate,
                                lastDate: calendarLastDate,
                                currentDate: DateTime.now(),
                                onDateChanged: (value) {
                                  setState(() => _selectedDate = onlyDate(value));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizations.formatFullDate(adjustedSelectedDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (selectedDoses.isEmpty)
                                      const Text(
                                        'Bu tarih için planlanmış ilaç yok.',
                                        style: TextStyle(color: Color(0xFF6B7280)),
                                      )
                                    else
                                      ...selectedDoses.map(
                                        (dose) => _HistoryDoseTile(
                                          dose: dose,
                                          statusColor: _statusColor(dose.status),
                                          statusIcon: _statusIcon(dose.status),
                                          onUpdate: widget.onUpdateDoseStatus,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _HistoryDoseTile extends StatelessWidget {
  const _HistoryDoseTile({
    required this.dose,
    required this.statusColor,
    required this.statusIcon,
    required this.onUpdate,
  });

  final MedicationDose dose;
  final Color statusColor;
  final IconData statusIcon;
  final void Function(MedicationDose dose, MedicationStatus status) onUpdate;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final timeLabel = localizations.formatTimeOfDay(dose.timeOfDay);
    final medication = dose.medication;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medication_outlined,
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
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  dose.status.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<MedicationStatus>(
            tooltip: 'Durumu güncelle',
            onSelected: (value) => onUpdate(dose, value),
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: MedicationStatus.taken,
                  child: Text('Alındı olarak işaretle'),
                ),
                PopupMenuItem(
                  value: MedicationStatus.skipped,
                  child: Text('Dozu atla'),
                ),
                PopupMenuItem(
                  value: MedicationStatus.pending,
                  child: Text('Beklemede işaretle'),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.onNavigate});

  final ValueChanged<AppScreen> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, size: 72, color: Color(0xFFCBD5F5)),
            const SizedBox(height: 16),
            const Text(
              'Henüz ilaç geçmişi yok',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Uyumunu izlemek için bir ilaç planı oluştur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => onNavigate(AppScreen.addMedication),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('İlaç ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
