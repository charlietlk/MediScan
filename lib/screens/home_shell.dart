import 'package:flutter/material.dart';

import '../models/app_screen.dart';
import '../models/dashboard_stats.dart';
import '../models/medication.dart';
import '../models/medication_dose.dart';
import '../widgets/app_bottom_navigation.dart';
import 'add_medication_screen.dart';
import 'dashboard_screen.dart';
import 'health_tracking_screen.dart';
import 'medication_history_screen.dart';
import 'pharmacy_map_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppScreen _activeScreen = AppScreen.dashboard;
  final List<Medication> _medications = [];
  final Map<String, MedicationStatus> _doseStatuses = {};

  void _handleNavigate(AppScreen screen) {
    setState(() => _activeScreen = screen);
  }

  void _addMedication(Medication medication) {
    setState(() {
      _medications.add(medication);
    });
    _handleNavigate(AppScreen.dashboard);
  }

  void _updateDoseStatus(MedicationDose dose, MedicationStatus status) {
    setState(() {
      _doseStatuses[dose.id] = status;
    });
  }

  bool _isMedicationActiveOnDate(Medication medication, DateTime date) {
    final day = onlyDate(date);
    final start = onlyDate(medication.startDate);
    final end = medication.endDate != null ? onlyDate(medication.endDate!) : null;

    if (day.isBefore(start)) return false;
    if (end != null && day.isAfter(end)) return false;

    switch (medication.frequency) {
      case 'weekly':
        final diff = day.difference(start).inDays;
        return diff % 7 == 0;
      default:
        return true;
    }
  }

  String _doseKey(Medication medication, DateTime date, TimeOfDay time) {
    return '${medication.id}|${dateKey(date)}|${timeKeyFromTimeOfDay(time)}';
  }

  List<MedicationDose> _getDosesForDate(DateTime targetDate) {
    final date = onlyDate(targetDate);
    final now = DateTime.now();
    final todayKey = dateKey(now);

    final List<MedicationDose> doses = [];

    for (final medication in _medications) {
      if (!_isMedicationActiveOnDate(medication, date)) continue;

      for (final timeString in medication.times) {
        final time = timeOfDayFromKey(timeString);
        final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        final key = _doseKey(medication, date, time);
        final storedStatus = _doseStatuses[key];

        MedicationStatus status;
        if (storedStatus != null) {
          status = storedStatus;
        } else {
          final scheduledKey = dateKey(scheduled);
          if (scheduled.isBefore(now)) {
            status = scheduledKey == todayKey ? MedicationStatus.pending : MedicationStatus.missed;
          } else {
            status = MedicationStatus.upcoming;
          }
        }

        doses.add(
          MedicationDose(
            id: key,
            medication: medication,
            scheduledDateTime: scheduled,
            status: status,
          ),
        );
      }
    }

    doses.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return doses;
  }

  double _calculateAdherenceRate({int days = 7}) {
    if (_medications.isEmpty) return 0;

    final now = DateTime.now();
    final today = onlyDate(now);

    int taken = 0;
    int total = 0;

    for (var i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final doses = _getDosesForDate(date);
      for (final dose in doses) {
        if (dose.scheduledDateTime.isAfter(now)) continue;
        total++;
        if (dose.status == MedicationStatus.taken) {
          taken++;
        }
      }
    }

    if (total == 0) return 0;
    return (taken / total) * 100;
  }

  DashboardStats _buildDashboardStats(List<MedicationDose> todayDoses) {
    final adherence = _calculateAdherenceRate();
    final takenToday = todayDoses.where((dose) => dose.status == MedicationStatus.taken).length;
    final pendingToday = todayDoses.where((dose) => dose.status == MedicationStatus.pending).length;
    final upcoming = todayDoses
        .where((dose) => dose.status == MedicationStatus.upcoming)
        .toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

    return DashboardStats(
      adherenceRate: adherence,
      takenToday: takenToday,
      totalToday: todayDoses.length,
      pendingToday: pendingToday,
      nextDose: upcoming.isNotEmpty ? upcoming.first : null,
    );
  }

  List<DateTime> _buildAvailableDates() {
    if (_medications.isEmpty) return const [];

    final today = onlyDate(DateTime.now());
    DateTime start = today;
    DateTime end = today;

    for (final medication in _medications) {
      final medStart = onlyDate(medication.startDate);
      final medEnd = medication.endDate != null ? onlyDate(medication.endDate!) : today.add(const Duration(days: 7));
      if (medStart.isBefore(start)) start = medStart;
      if (medEnd.isAfter(end)) end = medEnd;
    }

    // Limit the range to avoid generating extremely large histories.
    const maxRange = Duration(days: 60);
    if (end.difference(start) > maxRange) {
      end = start.add(maxRange);
    }

    final Set<DateTime> result = {};
    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      for (final medication in _medications) {
        if (_isMedicationActiveOnDate(medication, cursor)) {
          result.add(cursor);
          break;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return result.toList()
      ..sort((a, b) => a.compareTo(b));
  }

  Widget _buildActiveScreen() {
    final today = onlyDate(DateTime.now());
    final todayDoses = _getDosesForDate(today);
    final stats = _buildDashboardStats(todayDoses);
    final availableDates = _buildAvailableDates();

    switch (_activeScreen) {
      case AppScreen.dashboard:
        return DashboardScreen(
          onNavigate: _handleNavigate,
          todayDoses: todayDoses,
          onUpdateDoseStatus: _updateDoseStatus,
          stats: stats,
        );
      case AppScreen.addMedication:
        return AddMedicationScreen(
          onNavigate: _handleNavigate,
          onSaveMedication: _addMedication,
        );
      case AppScreen.history:
        return MedicationHistoryScreen(
          onNavigate: _handleNavigate,
          dosesForDate: _getDosesForDate,
          availableDates: availableDates,
          onUpdateDoseStatus: _updateDoseStatus,
        );
      case AppScreen.pharmacy:
        return PharmacyMapScreen(onNavigate: _handleNavigate);
      case AppScreen.health:
        return HealthTrackingScreen(onNavigate: _handleNavigate);
      case AppScreen.profile:
        return ProfileScreen(onNavigate: _handleNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildActiveScreen()),
          if (_activeScreen != AppScreen.profile)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(Icons.person_rounded),
                      tooltip: 'Profil',
                      onPressed: () => _handleNavigate(AppScreen.profile),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        current: _activeScreen,
        onChanged: _handleNavigate,
      ),
    );
  }
}
