import 'package:flutter/material.dart';

import '../models/app_screen.dart';
import '../models/medication.dart';
import '../widgets/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

enum YemekZamani { once, sirasinda, sonra }
enum YasGrubu { cocuk, yetiskin, yasli }
enum DoseStatus { pending, taken, skipped }


class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({
    super.key,
    required this.onNavigate,
    required this.onSaveMedication,
  });

  final ValueChanged<AppScreen> onNavigate;
  final ValueChanged<Medication> onSaveMedication;

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String _selectedFrequency = 'once-daily';
  List<TimeOfDay> _times = [TimeOfDay.now()];
  List<DoseStatus> _statuses = [DoseStatus.pending];
  
  YemekZamani _yemekZamani = YemekZamani.sirasinda;
  YasGrubu _yasGrubu = YasGrubu.yetiskin;

  bool _reminderEnabled = true;

  // --- AI saat öner (offline, serversiz) ---
Future<void> _applyOfflineAiSuggestion() async {
  final doz = _dozFromFrequency(_selectedFrequency);
  final suggested = _suggestByRules(
    doz: doz,
    yemek: _yemekZamani,
    yas: _yasGrubu,
  );

  final textList = suggested.map(_fmtHHmm).join(', ');

  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text('AI (offline) önerileri',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Önerilen saatler: $textList'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'merge'),
                    child: const Text('Birleştir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'replace'),
                    child: const Text('Değiştir'),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Vazgeç'),
            ),
          ],
        ),
      ),
    ),
  );

  if (!mounted || action == null || action == 'cancel') return;

  final suggestedTOD = suggested.map(_toTimeOfDay).toList();

  if (action == 'replace') {
    setState(() {
      _times = suggestedTOD;
    });
  } else if (action == 'merge') {
    final merged = [..._times, ...suggestedTOD]
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    setState(() {
      _times = merged;
    });
  }
}

// --- Basit kural tabanlı önerici (serversiz) ---
List<String> _suggestByRules({
  required int doz,
  required YemekZamani yemek,
  required YasGrubu yas,
}) {
  int kahvalti, ogle, aksam;
  switch (yas) {
    case YasGrubu.cocuk:
      kahvalti = 7 * 60 + 30; ogle = 12 * 60 + 30; aksam = 19 * 60;
      break;
    case YasGrubu.yetiskin:
      kahvalti = 8 * 60; ogle = 13 * 60; aksam = 19 * 60 + 30;
      break;
    case YasGrubu.yasli:
      kahvalti = 7 * 60 + 30; ogle = 12 * 60; aksam = 18 * 60 + 30;
      break;
  }

  List<int> anchors;
  switch (doz) {
    case 1:  anchors = [kahvalti]; break;
    case 2:  anchors = [kahvalti, ogle]; break;
    case 3:  anchors = [kahvalti, ogle, aksam]; break;
    case 4:  anchors = [kahvalti, (kahvalti + ogle) ~/ 2, ogle, aksam]; break;
    default: anchors = [kahvalti];
  }

  int offset;
  switch (yemek) {
    case YemekZamani.once:      offset = -30; break;
    case YemekZamani.sirasinda: offset = 0;   break;
    case YemekZamani.sonra:     offset = 30;  break;
  }

  final out = <String>[];
  for (final t in anchors) {
    final t2 = t + offset;
    final hh = (t2 ~/ 60).clamp(0, 23);
    final mm = (t2 % 60).clamp(0, 59);
    out.add('${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}');
  }
  return out;
}

int _dozFromFrequency(String freq) {
  switch (freq) {
    case 'once-daily':  return 1;
    case 'twice-daily': return 2;
    case 'three-times': return 3;
    case 'four-times':  return 4;
    default:            return 1;
  }
}

TimeOfDay _toTimeOfDay(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  return TimeOfDay(hour: h, minute: m);
}

String _fmtHHmm(String hhmm) => hhmm;


  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initialDate = _parseDate(controller.text) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      controller.text = _formatDate(picked);
    }
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );

    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  void _addTimeField() {
  setState(() {
    _times = [..._times, TimeOfDay.now()];
    _statuses = [..._statuses, DoseStatus.pending]; 
  });
}


  void _removeTime(int index) {
  if (_times.length == 1) return;
  setState(() {
    _times.removeAt(index);
    if (_statuses.length > index) {
      _statuses.removeAt(index);
    }
  });
}
  
  DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final startDate = onlyDate(_parseDate(_startDateController.text) ?? DateTime.now());
    final endValue = _parseDate(_endDateController.text);
    final endDate = endValue != null ? onlyDate(endValue) : null;

    if (endDate != null && endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş tarihi başlangıç tarihinden sonra olmalı.')),
      );
      return;
    }

    final sortedTimes = [..._times]
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    final timeStrings = sortedTimes.map(timeKeyFromTimeOfDay).toList();

    final medication = Medication(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _selectedFrequency,
      times: timeStrings,
      startDate: startDate,
      endDate: endDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      reminderEnabled: _reminderEnabled,
    );

    widget.onSaveMedication(medication);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İlaç başarıyla kaydedildi.')),
    );

    widget.onNavigate(AppScreen.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      includeSafeArea: false,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,          // beyaz şeridi kaldır
            surfaceTintColor: Colors.transparent,         // Material3 tint kapalı
            scrolledUnderElevation: 0,                    // scroll gölgelenmesi yok
            toolbarHeight: 56,
            centerTitle: false,                           // sola hizala
            leadingWidth: 56,
            titleSpacing: 16,                             // geri ok + başlık sol boşluk
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => widget.onNavigate(AppScreen.dashboard),
            ),
            title: const Text(
              'İlaç ekle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: const [
              SizedBox(width: 56), // sağ üstteki global profil ikonuna yer bırak
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const QuickOptionsRow(),
                    const SizedBox(height: 24),
                    const _SectionTitle('Temel bilgiler'),
                    const SizedBox(height: 16),
                    _TextField(
                      controller: _nameController,
                      label: 'İlaç adı',
                      hintText: 'Örn: Aspirin, D Vitamini',
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      controller: _dosageController,
                      label: 'Doz',
                      hintText: 'Örn: 500 mg, 1 tablet',
                    ),
                    const SizedBox(height: 16),
                    _DropdownField(
                      label: 'Sıklık',
                      selectedValue: _selectedFrequency,
                      items: const [
                        DropdownMenuItem(value: 'once-daily', child: Text('Günde bir')),
                        DropdownMenuItem(value: 'twice-daily', child: Text('Günde iki')),
                        DropdownMenuItem(value: 'three-times', child: Text('Günde üç')),
                        DropdownMenuItem(value: 'four-times', child: Text('Günde dört')),
                        DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
                        DropdownMenuItem(value: 'as-needed', child: Text('Gerektikçe')),
                      ],
                      onChanged: (value) => setState(() => _selectedFrequency = value!),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Saatler'),
                    const SizedBox(height: 12),
                    Column(
                      children: _times.asMap().entries.map((entry) {
                        final index = entry.key;
                        final time = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TimeTile(
                            index: index,
                            time: time,
                            canRemove: _times.length > 1,
                            onEdit: () => _pickTime(index),
                            onRemove: () => _removeTime(index),
                          ),
                        );
                      }).toList(),
                    ),
                    Align(
  alignment: Alignment.centerLeft,
  child: Row(
    children: [
      TextButton.icon(
        onPressed: _addTimeField,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Yeni saat ekle'),
      ),
      const SizedBox(width: 12),
      TextButton.icon(
        onPressed: _applyOfflineAiSuggestion, // <-- AI saat öneri butonu
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI ile saat öner'),
      ),
    ],
  ),
),

                    const SizedBox(height: 24),
                    const _SectionTitle('Takvim'),
                    const SizedBox(height: 16),
                    _DateField(
                      controller: _startDateController,
                      label: 'Başlangıç tarihi',
                      onTap: () => _pickDate(_startDateController),
                    ),
                    const SizedBox(height: 16),
                    _DateField(
                      controller: _endDateController,
                      label: 'Bitiş tarihi (isteğe bağlı)',
                      onTap: () => _pickDate(_endDateController),
                      requiredField: false,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Notlar'),
                    const SizedBox(height: 12),
                    _TextField(
                      controller: _notesController,
                      label: 'Açıklamalar',
                      hintText: 'Özel talimatları buraya ekleyin',
                      maxLines: 4,
                      requiredField: false,
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile.adaptive(
                      value: _reminderEnabled,
                      onChanged: (value) => setState(() => _reminderEnabled = value),
                      title: const Text(
                        'Hatırlatmaları etkinleştir',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Planlanan saatlerde bildirim al'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _onSubmit,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('İlacı kaydet'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.maxLines = 1,
    this.requiredField = true,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLines;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (!requiredField) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Lütfen ${label.toLowerCase()} girin';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String selectedValue;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('${label}_$selectedValue'),
      initialValue: selectedValue,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.label,
    required this.onTap,
    this.requiredField = true,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: (value) {
        if (!requiredField) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Lütfen ${label.toLowerCase()} seçin';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Seçmek için dokun',
        filled: true,
        fillColor: Colors.white,
        suffixIcon: const Icon(Icons.calendar_today_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.index,
    required this.time,
    required this.onEdit,
    required this.onRemove,
    required this.canRemove,
  });

  final int index;
  final TimeOfDay time;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(time);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0EAFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.access_time, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saat ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatted,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Edit time',
            ),
            if (canRemove)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
                tooltip: 'Remove time',
              ),
          ],
        ),
      ),
    );
  }
}

class QuickOptionsRow extends StatefulWidget {
  const QuickOptionsRow({super.key});

  @override
  State<QuickOptionsRow> createState() => _QuickOptionsRowState();
}

class _QuickOptionsRowState extends State<QuickOptionsRow> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _withBusy(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      _show('Hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Kamera -> OCR
  Future<void> _onCamera() async => _withBusy(() async {
        final x = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600);
        if (x == null) return;
        final input = InputImage.fromFilePath(x.path);
        final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        try {
          final out = await recognizer.processImage(input);
          final text = out.text.trim();
          _show(text.isEmpty ? 'Metin bulunamadı.' : text);
        } finally {
          await recognizer.close();
        }
      });

  // Galeri -> OCR
  Future<void> _onGallery() async => _withBusy(() async {
        final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
        if (x == null) return;
        final input = InputImage.fromFilePath(x.path);
        final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        try {
          final out = await recognizer.processImage(input);
          final text = out.text.trim();
          _show(text.isEmpty ? 'Metin bulunamadı.' : text);
        } finally {
          await recognizer.close();
        }
      });

  // Kamera -> Barkod
  Future<void> _onQr() async => _withBusy(() async {
        final x = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600);
        if (x == null) return;
        final input = InputImage.fromFilePath(x.path);

        // Format listesi vermiyoruz — sürüm uyuşmazlığı riskini azaltır
        final scanner = BarcodeScanner();
        try {
          final codes = await scanner.processImage(input);
          if (codes.isEmpty) {
            _show('Kod bulunamadı.');
            return;
          }
          final first = codes.first;
          final value = first.rawValue ?? first.displayValue ?? '';
          _show(value.isEmpty ? 'Kod çözümlenemedi.' : value);
        } finally {
          await scanner.close();
        }
      });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı ekleme seçenekleri',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Fotoğraf çek',
                  color: const Color(0xFF2563EB),
                  onTap: _busy ? null : _onCamera,
                ),
                _buildButton(
                  icon: Icons.qr_code_scanner_outlined,
                  label: 'Barkodu tara',
                  color: const Color(0xFF16A34A),
                  onTap: _busy ? null : _onQr,
                ),
                _buildButton(
                  icon: Icons.upload_file_outlined,
                  label: 'Görsel yükle',
                  color: const Color(0xFF7C3AED),
                  onTap: _busy ? null : _onGallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            side: BorderSide(color: color.withOpacity(0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickOption {
  const _QuickOption({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}
