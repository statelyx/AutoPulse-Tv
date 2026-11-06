# Teslim durumu — 6 Kasım 2026

## Yeni tek-build CarPlay çalışması

Kaynak adc9a2a GitHub main dalına push edildi. Tek project.yml, audio/video entitlement, explicit scene, ses fallback ve iki yeni regresyon testi eklendi. XcodeGen üretiminde anahtarların kaybolmaması için entitlements.properties tanımlandı; disconnect callback imzası düzeltildi.

d83a308 CI çalışması 12 birim + 2 UI testiyle başarılı tamamlandı; son callback düzeltmesinin adc9a2a CI sonucu henüz doğrulanmadı. Codemagic build 7 (6aede66d24e1ec237556d548) son kontrolde waiting. Build 5 ve 6 eski kaynakları yüklememeleri için iptal edildi.

Apple CarPlay Audio ve Video başvurularının gönderim onayı görüldü; yetki onayı henüz doğrulanmadı. CarPlay yetkili development/App Store profilleri yeniden üretilemedi. Yeni build TestFlight yüklemesi ve gerçek araç testi tamamlanmadı. Build 4 submit edilmedi. Ayrıntılar: docs/verification/2026-11-06-carplay-unified.json.

## Önceki standart iOS build durumu

AutoPulse TV 1.1.0 (4), Codemagic üzerinden imzalanıp App Store Connect'e yüklendi. Mevcut AutoPulse Dahili Test grubunda Testing durumunda olduğu ve bir kurulum bulunduğu doğrulandı. Test notları kaydedildi. App Store genel yayın incelemesine gönderilmedi.

## Uygulanan özellikler

Dosyalar/Fotoğraflar içe aktarma, çevrimdışı yerel medya, video/fotoğraf filtreleri, favoriler/gruplar, kaynak düzenleme, tam ekran fotoğraf/yakınlaştırma/slayt gösterisi, AirPlay için sessiz fotoğraf video klibi, PiP, keşif kısayolları, M3U ve Keychain kimlik bilgileriyle Xtream uyumlu liste içe aktarma.

## Doğrulama

- GitHub Actions: https://github.com/statelyx/AutoPulse-Tv/actions/runs/42227322556 — kaynak 6af6fe8; 10 birim + 2 UI testi, 0 hata. iPhone ve iPad native ekran görüntüleri başarılı.
- Codemagic build: https://codemagic.io/app/6aedac2730f39d49d7284dcf/build/6aedd645e348ff611c865c01 — başarılı, imzalı Release kaynağı e0f1396. Sonraki commitler DEBUG ekran görüntüsü düzeneğini iyileştirir.
- TestFlight: 1.1.0 (4), AutoPulse Dahili Test, Testing.
- Ekran görüntüleri: store/screenshots/v1.1; dört farklı sayfa, hem iPhone hem iPad. Boyutlar/hashler manifest.json içinde.

Gerçek araç/AirPlay oynatma testi yapılmadı. Varsayılan build native AirPlay kullanır. Ayrı CarPlay yapılandırması Apple video yetkisi, uygun SDK ve uyumlu araç gerektirir. Telefonun web arayüzünü araç ekranına yansıtmaz.
