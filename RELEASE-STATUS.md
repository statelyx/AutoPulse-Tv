# Teslim durumu — 9 Kasım 2026

## Güncel dağıtım: 1.1.0 (12)

Tüm çalışma alanı değişiklikleri 7c35956 commit'i ile GitHub main dalına gönderildi.
Codemagic build 12 (6af1b5310e96298b1e677037), bu kaynakla imzalı arşivi oluşturdu
ve App Store Connect yüklemesini hatasız tamamladı. Apple işleme adımı tamamlandı;
AutoPulse Dahili Test grubunda 1.1.0 (12) Testing durumunda ve kurulum gözlendi.

Codemagic dış TestFlight beta incelemesini de denedi; Feedback Email ve beta review
iletişim bilgileri (ad, soyad, telefon, e-posta) eksik olduğu için bu son adım
başarısız oldu. Bu nedenle Codemagic toplam durumu "finished with post-processing
failed" olsa da imzalı derleme, yükleme ve dahili test erişimi başarılıdır.
Genel App Store incelemesine gönderilmedi. Gerçek araç testi yapılmadı.

GitHub Actions 42613005535 son kontrolde çalışıyordu; test başarısı henüz doğrulanmadı.
Kanıt: docs/verification/2026-11-09-build-12.json ve testflight-build-12-testing.png.

## Önceki kayıt (6 Kasım 2026)

# Teslim durumu — 6 Kasım 2026

## Yeni tek-build CarPlay çalışması

Kaynak adc9a2a GitHub main dalına push edildi. Tek project.yml, audio/video entitlement, explicit scene, ses fallback ve iki yeni regresyon testi eklendi. XcodeGen üretiminde anahtarların kaybolmaması için entitlements.properties tanımlandı; disconnect callback imzası düzeltildi.

d83a308 CI çalışması 12 birim + 2 UI testiyle başarılı tamamlandı; son callback düzeltmesinin adc9a2a CI sonucu henüz doğrulanmadı. Codemagic build 7 (6aede66d24e1ec237556d548) 2 dakika 14 saniyede başarısız oldu: Archive and export, exit 65. Xcode, com.apple.developer.carplay-audio ve com.apple.developer.carplay-video yetkilerinin profile eklenemediğini raporladı. Apple portalında Audio hâlâ No Status / Request capability olarak görünüyor. Build 5 ve 6 eski kaynakları yüklememeleri için iptal edildi.

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
