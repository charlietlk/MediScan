import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/app_screen.dart';
import '../models/pharmacy.dart';
import '../state/pharmacy_view_model.dart';
import '../widgets/gradient_background.dart';
import '../widgets/pharmacy_map.dart';

class PharmacyMapScreen extends StatefulWidget {
  const PharmacyMapScreen({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<AppScreen> onNavigate;

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<PharmacyMapState> _mapKey = GlobalKey<PharmacyMapState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PharmacyViewModel>(
      create: (_) => PharmacyViewModel()..init(),
      child: Consumer<PharmacyViewModel>(
        builder: (context, vm, _) {
          _listenForTransientErrors(context, vm);

          final userLatLng = vm.current != null
              ? LatLng(vm.current!.latitude, vm.current!.longitude)
              : const LatLng(41.0369, 28.9853);
          final showWebPlaceholder = kIsWeb &&
              (AppConsts.googleWebApiKey.isEmpty ||
                  AppConsts.googleWebApiKey.startsWith('YOUR_') ||
                  AppConsts.googleWebApiKey.startsWith('REPLACE'));

          return GradientBackground(
            includeSafeArea: false,
            padding: EdgeInsets.zero,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () =>
                              widget.onNavigate(AppScreen.dashboard),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Eczane bul',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: vm.isActiveLoading
                              ? null
                              : () {
                                  vm.refresh();
                                },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Yenile'),
                        ),
                      ],
                    ),
                  ),
                  if (vm.isActiveLoading && vm.items.isNotEmpty)
                    const LinearProgressIndicator(minHeight: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ScopeTabs(
                      activeIndex: vm.tabIndex,
                      onSelect: (index) {
                        final scope = index == 0
                            ? PharmacyScope.onDuty
                            : PharmacyScope.regular;
                        vm.setScope(scope);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          onChanged: vm.applySearch,
                          onSubmitted: (value) {
                            if (vm.tabIndex == PharmacyScope.regular.index) {
                              _handleManualSearch(vm, value);
                            }
                          },
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: vm.tabIndex == PharmacyScope.regular.index
                                ? 'İlçe, il veya sadece il adı ile ara'
                                : 'İsim veya adres ile ara',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon:
                                ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (context, value, child) {
                                if (value.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    vm.applySearch('');
                                  },
                                );
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SizedBox(
                        height: 220,
                        child: showWebPlaceholder
                            ? const _WebMapPlaceholder()
                            : PharmacyMap(
                                key: _mapKey,
                                userLatLng: userLatLng,
                                items: vm.items,
                                onMarkerTap: (pharmacy) {
                                  vm.select(pharmacy);
                                  _mapKey.currentState?.animateTo(pharmacy);
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Yakın eczaneler',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '${vm.items.length} eczane bulundu',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (vm.permissionDenied)
                          _PermissionRequestCard(
                            onRequest: vm.requestPermission,
                          ),
                        if (vm.isActiveLoading && vm.items.isEmpty)
                          _StatusCard(
                            icon: Icons.location_searching_rounded,
                            message: 'Yakındaki eczaneler yükleniyor...',
                            onRetry: () {
                              vm.refresh();
                            },
                            showProgress: true,
                          )
                        else if (vm.error != null && vm.items.isEmpty)
                          _StatusCard(
                            icon: Icons.error_outline_rounded,
                            message: vm.error!,
                            onRetry: () {
                              vm.refresh();
                            },
                          )
                        else if (vm.items.isEmpty)
                          _StatusCard(
                            icon: Icons.search_off_rounded,
                            message: 'Aramanızla eşleşen eczane bulunamadı.',
                            onRetry: () {
                              _searchController.clear();
                              vm.applySearch('');
                            },
                          )
                        else
                          ...vm.items.map(
                            (pharmacy) => _PharmacyCard(
                              pharmacy: pharmacy,
                              isSelected: identical(vm.selected, pharmacy),
                              onTap: () {
                                vm.select(pharmacy);
                                _mapKey.currentState?.animateTo(pharmacy);
                              },
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleManualSearch(PharmacyViewModel vm, String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    String city = trimmed;
    String? district;
    final parts = trimmed.split(',');
    if (parts.length >= 2) {
      district = parts.first.trim();
      city = parts.sublist(1).join(',').trim();
    }

    vm.loadRegularManual(
      city: city,
      district: (district?.isEmpty ?? true) ? null : district,
    );
  }

  void _listenForTransientErrors(BuildContext context, PharmacyViewModel vm) {
    if (vm.error == null || vm.items.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(vm.error!)),
        );
      vm.clearError();
    });
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({
    required this.pharmacy,
    required this.onTap,
    required this.isSelected,
  });

  final Pharmacy pharmacy;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<PharmacyViewModel>(context, listen: false);
    const accentColor = Color(0xFF2563EB);

    final distance = pharmacy.distanceKm;
    final distanceLabel = distance != null
        ? '${distance.toStringAsFixed(1)} km'
        : 'Mesafe hesaplanamadı';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? accentColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pharmacy.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pharmacy.address,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.navigation_rounded,
                                color: accentColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              distanceLabel,
                              style: const TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Ara',
                        icon: const Icon(Icons.phone_rounded),
                        onPressed: () {
                          vm.callPharmacy(pharmacy);
                        },
                      ),
                      IconButton(
                        tooltip: 'Haritada aç',
                        icon: const Icon(Icons.map_outlined),
                        onPressed: () {
                          vm.openInMaps(pharmacy);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({
    required this.activeIndex,
    required this.onSelect,
  });

  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0EAFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ScopeTabButton(
            label: 'Nöbetçi',
            isActive: activeIndex == 0,
            onTap: () => onSelect(0),
          ),
          _ScopeTabButton(
            label: 'Gündüz',
            isActive: activeIndex == 1,
            onTap: () => onSelect(1),
          ),
        ],
      ),
    );
  }
}

class _ScopeTabButton extends StatelessWidget {
  const _ScopeTabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2563EB);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive ? activeColor : const Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionRequestCard extends StatelessWidget {
  const _PermissionRequestCard({
    required this.onRequest,
  });

  final Future<void> Function() onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7EB),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konum izni olmadan yakın eczaneler gösterilemiyor.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: onRequest,
                  child: const Text('İzin iste'),
                ),
                OutlinedButton(
                  onPressed: () {
                    openAppSettings();
                  },
                  child: const Text('Ayarlar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WebMapPlaceholder extends StatelessWidget {
  const _WebMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Harita web’de API anahtarı eklenince açılır.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.message,
    required this.onRetry,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showProgress) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ] else ...[
              Icon(icon, size: 48, color: const Color(0xFF2563EB)),
              const SizedBox(height: 12),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
