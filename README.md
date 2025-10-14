# medication_manager

Flutter uygulaması için mock eczane verisi ve kullanıcı konumu ile çalışan bir eczane bulucu ekranı içerir.

## Konum izinleri

- **iOS**: `ios/Runner/Info.plist` dosyasına `NSLocationWhenInUseUsageDescription` anahtarını, kullanıcıya gösterilecek kısa bir açıklama metni ile ekleyin.
- **Android**: `android/app/src/main/AndroidManifest.xml` içindeki `<manifest>` bloğuna `android.permission.ACCESS_FINE_LOCATION` ve `android.permission.ACCESS_COARSE_LOCATION` izinlerini ekleyin.

## NosyAPI

- API anahtarınızı `lib/config/constants.dart` dosyasındaki `AppConsts.nosyKey` alanına yerleştirin.
- Endpoint: `GET /pharmacies-on-duty/locations?latitude={lat}&longitude={lng}`. Header: `Authorization: Bearer {API_KEY}`.
- Servisten hata dönerse uygulama ekranda mesaj ve "Tekrar dene" butonu gösterir.
- Konuma göre sonuçlar ViewModel içinde 5 dakikalığına bellekte önbelleğe alınır.

## CollectAPI (gündüz eczaneleri)

- Endpoint: `GET https://api.collectapi.com/health/pharmacy?il={city}&ilce={district}`.
- Headers:
  - `authorization: apikey {COLLECT_API_KEY}`
  - `content-type: application/json`
- Şehir/ilçe bilgilerini Türkçe karakterlerini bozmadan gönderin. Servis başarısız olursa kullanıcıya mesaj gösterilecek; ileride manuel seçim için geliştirme yapılabilir.

## Reverse Geocoding (Nominatim)

- Endpoint: `GET https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lng}&format=json&addressdetails=1&accept-language=tr`.
- Header: `User-Agent: pharmacy-app/1.0`.
- Dönen yanıtta `city` / `province` / `state` ve `town` / `county` / `suburb` alanlarından şehir ve ilçe bilgileri türetilir.


## Harita (Google Maps)

- **iOS**: Ek Google Maps anahtarı gerekmez; Info.plist içindeki konum izinleri yeterlidir.
- **Android**: `android/app/src/main/AndroidManifest.xml` dosyasında `<application>` etiketine şu meta-data ekleyin:
  `<meta-data android:name="com.google.android.geo.API_KEY" android:value="REPLACE_WITH_YOUR_ANDROID_MAPS_API_KEY"/>`
  Gerekirse debug/release varyantları için SHA imza ayarlarını tamamlayın.
- Simülatörde konum emülasyonu gerekebilir; gerçek cihazda `myLocation` katmanı otomatik olarak kullanıcıyı gösterir.
