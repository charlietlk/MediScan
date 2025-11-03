import 'package:flutter/material.dart';

enum YemekZamani { once, sirasinda, sonra }
enum YasGrubu { cocuk, yetiskin, yasli }

List<TimeOfDay> offlineSuggestTimes({
  required int doz,
  required YemekZamani yemek,
  required YasGrubu yas,
}) {
  int hh(int h, int m) => h * 60 + m;

  late int kahvalti, ogle, aksam;
  switch (yas) {
    case YasGrubu.cocuk:
      kahvalti = hh(7, 30); ogle = hh(12, 30); aksam = hh(19, 0);
      break;
    case YasGrubu.yetiskin:
      kahvalti = hh(8, 0);  ogle = hh(13, 0);  aksam = hh(19, 30);
      break;
    case YasGrubu.yasli:
      kahvalti = hh(7, 30); ogle = hh(12, 0);  aksam = hh(18, 30);
      break;
  }

  List<int> anchors;
  switch (doz) {
    case 1: anchors = [kahvalti]; break;
    case 2: anchors = [kahvalti, ogle]; break;
    case 3: anchors = [kahvalti, ogle, aksam]; break;
    case 4: anchors = [kahvalti, (kahvalti + ogle) ~/ 2, ogle, aksam]; break;
    default: anchors = [kahvalti];
  }

  int offset;
  switch (yemek) {
    case YemekZamani.once: offset = -30; break;
    case YemekZamani.sirasinda: offset = 0; break;
    case YemekZamani.sonra: offset = 30; break;
  }

  return anchors.map((a) {
    final total = a + offset;
    final h = (total ~/ 60) % 24;
    final m = total % 60;
    return TimeOfDay(hour: h, minute: m);
  }).toList();
}

String fmtHHmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

int dozFromFrequency(String freq) {
  switch (freq) {
    case 'once-daily': return 1;
    case 'twice-daily': return 2;
    case 'three-times': return 3;
    case 'four-times': return 4;
    default: return 1;
  }
}
