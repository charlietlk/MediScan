enum AppScreen {
  dashboard,
  addMedication,
  history,
  pharmacy,
  health,
  profile,
}

extension AppScreenExt on AppScreen {
  String get title {
    switch (this) {
      case AppScreen.dashboard:
        return 'Ana sayfa';
      case AppScreen.addMedication:
        return 'İlaç ekle';
      case AppScreen.history:
        return 'İlaç geçmişi';
      case AppScreen.pharmacy:
        return 'Eczane bul';
      case AppScreen.health:
        return 'Sağlık takibi';
      case AppScreen.profile:
        return 'Profil ve ayarlar';
    }
  }
}
