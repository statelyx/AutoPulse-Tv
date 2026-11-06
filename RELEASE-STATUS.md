# Teslim durumu — 6 Kasım 2026

AutoPulse TV 1.1.0 (4), Codemagic üzerinden imzalanıp App Store Connect'e yüklendi. Mevcut AutoPulse Dahili Test grubunda Testing durumunda olduğu ve bir kurulum bulunduğu doğrulandı. Test notları kaydedildi. App Store genel yayın incelemesine gönderilmedi.

## Uygulanan özellikler

Dosyalar/Fotoğraflar içe aktarma, çevrimdışı yerel medya, video/fotoğraf filtreleri, favoriler/gruplar, kaynak düzenleme, tam ekran fotoğraf/yakınlaştırma/slayt gösterisi, AirPlay için sessiz fotoğraf video klibi, PiP, keşif kısayolları, M3U ve Keychain kimlik bilgileriyle Xtream uyumlu liste içe aktarma.

## Doğrulama

- GitHub Actions: https://github.com/statelyx/AutoPulse-Tv/actions/runs/42227322556 — kaynak 6af6fe8; 10 birim + 2 UI testi, 0 hata. iPhone ve iPad native ekran görüntüleri başarılı.
- Codemagic build: https://codemagic.io/app/6aedac2730f39d49d7284dcf/build/6aedd645e348ff611c865c01 — başarılı, imzalı Release kaynağı e0f1396. Sonraki commitler DEBUG ekran görüntüsü düzeneğini iyileştirir.
- TestFlight: 1.1.0 (4), AutoPulse Dahili Test, Testing.
- Ekran görüntüleri: store/screenshots/v1.1; dört farklı sayfa, hem iPhone hem iPad. Boyutlar/hashler manifest.json içinde.

Gerçek araç/AirPlay oynatma testi yapılmadı. Varsayılan build native AirPlay kullanır. Ayrı CarPlay yapılandırması Apple video yetkisi, uygun SDK ve uyumlu araç gerektirir. Telefonun web arayüzünü araç ekranına yansıtmaz.
