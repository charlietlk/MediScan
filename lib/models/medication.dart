import 'package:flutter/material.dart';

enum MedicationStatus { upcoming, pending, taken, skipped, missed }

extension MedicationStatusX on MedicationStatus {
  String get label {
    switch (this) {
      case MedicationStatus.upcoming:
        return 'Yaklaşan';
      case MedicationStatus.pending:
        return 'Beklemede';
      case MedicationStatus.taken:
        return 'Alındı';
      case MedicationStatus.skipped:
        return 'Atlandı';
      case MedicationStatus.missed:
        return 'Kaçırıldı';
    }
  }
}

class Medication {
  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.reminderEnabled,
  });

  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times; // Stored as HH:mm strings.
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool reminderEnabled;

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? reminderEnabled,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}

DateTime onlyDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String dateKey(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd';
}

String timeKeyFromTimeOfDay(TimeOfDay time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

TimeOfDay timeOfDayFromKey(String value) {
  final parts = value.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return TimeOfDay(hour: hour, minute: minute);
}
