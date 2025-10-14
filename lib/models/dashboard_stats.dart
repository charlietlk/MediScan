import '../models/medication_dose.dart';

class DashboardStats {
  const DashboardStats({
    required this.adherenceRate,
    required this.takenToday,
    required this.totalToday,
    required this.pendingToday,
    this.nextDose,
  });

  final double adherenceRate;
  final int takenToday;
  final int totalToday;
  final int pendingToday;
  final MedicationDose? nextDose;

  int get remainingToday => totalToday - takenToday;

  double get completionRate =>
      totalToday == 0 ? 0 : takenToday / totalToday;
}
