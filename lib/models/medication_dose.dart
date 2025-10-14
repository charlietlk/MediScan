import 'package:flutter/material.dart';

import 'medication.dart';

class MedicationDose {
  MedicationDose({
    required this.id,
    required this.medication,
    required this.scheduledDateTime,
    required this.status,
  });

  final String id;
  final Medication medication;
  final DateTime scheduledDateTime;
  final MedicationStatus status;

  MedicationDose copyWith({MedicationStatus? status}) {
    return MedicationDose(
      id: id,
      medication: medication,
      scheduledDateTime: scheduledDateTime,
      status: status ?? this.status,
    );
  }

  TimeOfDay get timeOfDay => TimeOfDay(
        hour: scheduledDateTime.hour,
        minute: scheduledDateTime.minute,
      );

  DateTime get dateOnly => DateTime(
        scheduledDateTime.year,
        scheduledDateTime.month,
        scheduledDateTime.day,
      );
}
