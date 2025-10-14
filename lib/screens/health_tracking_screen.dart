import 'package:flutter/material.dart';

import '../models/app_screen.dart';
import '../widgets/gradient_background.dart';

class HealthTrackingScreen extends StatefulWidget {
  const HealthTrackingScreen({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<AppScreen> onNavigate;

  @override
  State<HealthTrackingScreen> createState() => _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends State<HealthTrackingScreen> {
  int _waterIntake = 6;
  int _calorieIntake = 1250;

  final int _waterGoal = 8;
  final int _calorieGoal = 2000;

  final List<_WeeklyHydration> _weeklyHydration = const [
    _WeeklyHydration('Pzt', 8, 8),
    _WeeklyHydration('Sal', 6, 8),
    _WeeklyHydration('Çar', 7, 8),
    _WeeklyHydration('Per', 8, 8),
    _WeeklyHydration('Cum', 5, 8),
    _WeeklyHydration('Cmt', 9, 8),
    _WeeklyHydration('Paz', 6, 8),
  ];

  final List<_Achievement> _achievements = const [
    _Achievement('🏆', '7 günlük seri', 'İlaçlarını zamanında aldın', true),
    _Achievement('💧', 'Hidrasyon kahramanı', '5 gün üst üste su hedefini tutturdun', true),
    _Achievement('⭐', 'Tutarlılık şampiyonu', 'Bu hafta kaçırılan doz olmadı', false),
    _Achievement('🛡️', 'Sağlık savaşçısı', '30 gün boyunca sağlık verisi kaydettin', false),
  ];

  void _changeWater(int delta) {
    setState(() {
      _waterIntake = (_waterIntake + delta).clamp(0, 15);
    });
  }

  void _addCalories(int amount) {
    setState(() => _calorieIntake += amount);
  }

  double get _waterProgress => _waterGoal == 0 ? 0 : _waterIntake / _waterGoal;

  double get _calorieProgress => _calorieGoal == 0 ? 0 : _calorieIntake / _calorieGoal;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      includeSafeArea: false,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: DefaultTabController(
          length: 3,
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
                      'Sağlık takibi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: const TabBar(
                    indicator: BoxDecoration(
                      color: Color(0xFFE0EAFF),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    labelColor: Color(0xFF1D4ED8),
                    unselectedLabelColor: Color(0xFF6B7280),
                    tabs: [
                      Tab(text: 'Bugün'),
                      Tab(text: 'Haftalık'),
                      Tab(text: 'Başarılar'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.water_drop_outlined, color: Color(0xFF2563EB)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Su takibi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _CircleIconButton(
                                      icon: Icons.remove_rounded,
                                      onPressed: () => _changeWater(-1),
                                    ),
                                    const SizedBox(width: 20),
                                    Column(
                                      children: [
                                        Text(
                                          '$_waterIntake',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const Text(
                                          'bardak',
                                          style: TextStyle(color: Color(0xFF6B7280)),
                                        )
                                      ],
                                    ),
                                    const SizedBox(width: 20),
                                    _CircleIconButton(
                                      icon: Icons.add_rounded,
                                      onPressed: () => _changeWater(1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Hedef: $_waterGoal bardak',
                                        style: const TextStyle(color: Color(0xFF6B7280))),
                                    Text('$_waterIntake/$_waterGoal',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2563EB),
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: LinearProgressIndicator(
                                    value: _waterProgress.clamp(0.0, 1.0),
                                    minHeight: 12,
                                    backgroundColor: const Color(0xFFE0EAFF),
                                    valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(8, (index) {
                                    final filled = index < _waterIntake;
                                    return Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: filled
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFFE8EDFF),
                                      ),
                                      child: Icon(
                                        Icons.water_drop,
                                        color: filled ? Colors.white : const Color(0xFFB4C6FC),
                                      ),
                                    );
                                  }),
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
                                    Icon(Icons.local_pizza_outlined, color: Color(0xFF16A34A)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Kalori takibi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '$_calorieIntake',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const Text(
                                  'alınan kalori',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Hedef: $_calorieGoal kalori',
                                        style: const TextStyle(color: Color(0xFF6B7280))),
                                    Text('$_calorieIntake/$_calorieGoal',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF16A34A),
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: LinearProgressIndicator(
                                    value: _calorieProgress.clamp(0.0, 1.0),
                                    minHeight: 12,
                                    backgroundColor: const Color(0xFFD1FAE5),
                                    valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _QuickAddChip(label: '+200 Ara öğün', onTap: () => _addCalories(200)),
                                    _QuickAddChip(label: '+400 Öğün', onTap: () => _addCalories(400)),
                                    _QuickAddChip(label: '+150 İçecek', onTap: () => _addCalories(150)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.show_chart_rounded, color: Color(0xFF2563EB)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Haftalık su takibi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._weeklyHydration.map((item) {
                                  final progress = item.goal == 0 ? 0 : item.amount / item.goal;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            item.day,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: LinearProgressIndicator(
                                              value: progress.clamp(0.0, 1.0).toDouble(),
                                              minHeight: 12,
                                              backgroundColor: const Color(0xFFE0EAFF),
                                              valueColor:
                                                  const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${item.amount}/${item.goal}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
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
                              children: const [
                                Row(
                                  children: [
                                    Icon(Icons.monitor_heart_outlined, color: Color(0xFF7C3AED)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Haftalık içgörüler',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "• 7 günün 4'ünde su hedefini tutturdun.\n"
                                  '• Ortalama kalori alımı: 1870 kalori.\n'
                                  '• En yüksek hidrasyon: Cumartesi (9 bardak).',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        ..._achievements.map((achievement) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Text(
                                      achievement.icon,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            achievement.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            achievement.description,
                                            style: const TextStyle(color: Color(0xFF6B7280)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      achievement.earned
                                          ? Icons.check_circle_rounded
                                          : Icons.lock_outline_rounded,
                                      color:
                                          achievement.earned ? const Color(0xFF16A34A) : const Color(0xFFCBD5F5),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE0EAFF),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFF2563EB)),
        ),
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  const _QuickAddChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF16A34A),
        ),
      ),
      side: const BorderSide(color: Color(0xFF86EFAC)),
      backgroundColor: const Color(0xFFEFFDF4),
      onPressed: onTap,
    );
  }
}

class _WeeklyHydration {
  const _WeeklyHydration(this.day, this.amount, this.goal);

  final String day;
  final int amount;
  final int goal;
}

class _Achievement {
  const _Achievement(this.icon, this.title, this.description, this.earned);

  final String icon;
  final String title;
  final String description;
  final bool earned;
}
