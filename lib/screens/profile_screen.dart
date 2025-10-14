import 'package:flutter/material.dart';

import '../models/app_screen.dart';
import '../widgets/gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<AppScreen> onNavigate;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool medicationReminders = true;
  bool waterReminders = true;
  bool appointmentReminders = true;
  bool familyUpdates = true;

  bool shareWithFamily = true;
  bool cloudBackup = true;
  bool usageAnalytics = false;

  String _selectedLanguage = 'tr';

  final List<_FamilyMember> familyMembers = const [
    _FamilyMember('Alp Özdemir', 'Eş', 'AÖ', true),
    _FamilyMember('Ece Özdemir', 'Kız', 'EÖ', true),
    _FamilyMember('Dr. Ahmet Yılmaz', 'Aile hekimi', 'AY', false),
  ];

  Future<void> _showLanguagePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uygulama dili',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Radio<String>(
                  value: 'tr',
                  groupValue: _selectedLanguage,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                title: const Text('Türkçe'),
                onTap: () => Navigator.of(context).pop('tr'),
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'en',
                  groupValue: _selectedLanguage,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                title: const Text('English'),
                onTap: () => Navigator.of(context).pop('en'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null || selected == _selectedLanguage) {
      return;
    }

    setState(() => _selectedLanguage = selected);

    final message = selected == 'en'
        ? 'Dil İngilizce olarak ayarlandı.'
        : 'Dil Türkçe olarak ayarlandı.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      includeSafeArea: false,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => widget.onNavigate(AppScreen.dashboard),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Profil ve ayarlar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundColor: Color(0xFFE0EAFF),
                              child: Text(
                                'DÖ',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: IconButton(
                                  iconSize: 20,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Profil fotoğrafı yükleme çok yakında.')),
                                    );
                                  },
                                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deniz Özdemir',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ocak 2024’ten beri üye',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                child: const Text(
                                  '%92 kullanım oranı',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const _InfoRow(icon: Icons.mail_outline_rounded, value: 'deniz.ozdemir@email.com'),
                    const SizedBox(height: 10),
                    const _InfoRow(icon: Icons.phone_rounded, value: '(555) 123-4567'),
                    const SizedBox(height: 10),
                    const _InfoRow(icon: Icons.cake_outlined, value: 'Doğum: 15 Mart 1975'),
                    const SizedBox(height: 10),
                    const _InfoRow(icon: Icons.favorite_outline, value: 'Acil durum: Alp Özdemir (Eş)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.group_outlined, color: Color(0xFF7C3AED)),
                            SizedBox(width: 8),
                            Text(
                              'Aile ve bakım ekibi',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Davet özelliği yakında geliyor.')),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Davet et'),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...familyMembers.map((member) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFEDE9FE),
                                child: Text(
                                  member.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member.relationship,
                                      style: const TextStyle(color: Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: member.connected
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  member.connected ? 'Bağlı' : 'Beklemede',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: member.connected
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_outlined, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Text(
                          'Bildirim ayarları',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SwitchRow(
                      title: 'İlaç hatırlatıcıları',
                      description: 'İlaç zamanı geldiğinde bildirim al',
                      value: medicationReminders,
                      onChanged: (value) => setState(() => medicationReminders = value),
                    ),
                    const Divider(height: 28),
                    _SwitchRow(
                      title: 'Su hatırlatıcıları',
                      description: 'Düzenli hatırlatmalarla susuz kalma',
                      value: waterReminders,
                      onChanged: (value) => setState(() => waterReminders = value),
                    ),
                    const Divider(height: 28),
                    _SwitchRow(
                      title: 'Randevu hatırlatıcıları',
                      description: 'Yaklaşan randevular için bildirim al',
                      value: appointmentReminders,
                      onChanged: (value) => setState(() => appointmentReminders = value),
                    ),
                    const Divider(height: 28),
                    _SwitchRow(
                      title: 'Aile paylaşımları',
                      description: 'Aile üyelerinden bildirim al',
                      value: familyUpdates,
                      onChanged: (value) => setState(() => familyUpdates = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF16A34A)),
                        SizedBox(width: 8),
                        Text(
                          'Gizlilik ve güvenlik',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SwitchRow(
                      title: 'Aileyle paylaş',
                      description: 'Aile üyelerinin ilaç durumunu görmesine izin ver',
                      value: shareWithFamily,
                      onChanged: (value) => setState(() => shareWithFamily = value),
                    ),
                    const Divider(height: 28),
                    _SwitchRow(
                      title: 'Bulut yedekleme ve senkronizasyon',
                      description: 'Verilerini güvenle buluta yedekle',
                      value: cloudBackup,
                      onChanged: (value) => setState(() => cloudBackup = value),
                    ),
                    const Divider(height: 28),
                    _SwitchRow(
                      title: 'Kullanım analitiği',
                      description: 'Anonim kullanım verileriyle uygulamayı geliştirmemize yardımcı ol',
                      value: usageAnalytics,
                      onChanged: (value) => setState(() => usageAnalytics = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings_outlined, color: Color(0xFF4B5563)),
                        SizedBox(width: 8),
                        Text(
                          'Hızlı işlemler',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _QuickActionButton(
                      label: "Dil: ${_selectedLanguage == 'tr' ? 'Türkçe' : 'English'}",
                      color: const Color(0xFF2563EB),
                      onTap: _showLanguagePicker,
                    ),
                    _QuickActionButton(
                      label: 'Sağlık verilerini dışa aktar',
                      color: const Color(0xFF2563EB),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veriler dışa aktarılıyor...')),
                        );
                      },
                    ),
                    _QuickActionButton(
                      label: 'Destek ile iletişime geç',
                      color: const Color(0xFF16A34A),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Destek sohbeti açılıyor...')),
                        );
                      },
                    ),
                    _QuickActionButton(
                      label: 'Gizlilik politikası',
                      color: const Color(0xFF7C3AED),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gizlilik politikası açılıyor...')),
                        );
                      },
                    ),
                    _QuickActionButton(
                      label: 'Çıkış yap',
                      color: const Color(0xFFDC2626),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Oturum kapatıldı.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B7280), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _FamilyMember {
  const _FamilyMember(this.name, this.relationship, this.initials, this.connected);

  final String name;
  final String relationship;
  final String initials;
  final bool connected;
}
