# Teslim durumu — 6 Kasım 2026

## Son düzenleme

Ürün adı Molaqo olarak değiştirildi. Tek kaynak proje kullanıcının Masaüstü/Molaqo klasörüne taşındı. Eski teslim ZIP'i ve geçici araçlar, silme işlemi otomatik denetimde engellendiği için proje içindeki Git dışında tutulan .local arşivine taşındı. Git geçmişi projenin .git klasöründe korundu.

Telefon içi WebKit tarayıcı ve oynatıcı devam konumu düzeltmeleri eklendi. Güncel bulgular docs/APTV-FINDINGS.md, isim kararı docs/NAME.md, cihaz kabul testleri docs/TEST-MATRIX.md dosyalarında.

## Tamamlanan yerel çalışma

SwiftUI uygulama kaynakları; M3U ayrıştırıcı; JSON içe/dışa aktarma; dosya korumalı kalıcı kayıt; favori, arama ve izleme konumu; AVPlayer ve AirPlay; telefon içi WebKit tarayıcı ve Safari alternatifi; isteğe bağlı CarPlay video sahnesi; ikon, manifest, birim/UI testleri, CI tanımları ve Codemagic rehberi.

## Doğrulama

VALIDATION.json dosyasında Swift sözdizimi, YAML, plist ve JSON kontrolleri kaydedildi. Apple SDK bulunmadığı için derleme, link, XCTest ve araç testi çalıştırılmadı. Çalışan CarPlay uygulaması veya mağazaya hazır binary olduğu iddia edilmiyor.

## GitHub engeli

Son kullanıcı isteği statelyxx hesabına push yönündedir. Önceki ekran görüntüsünde görünen hesap kullanıcı adı statelyx, görünen profil adı statelyxx idi. Doğru uzak hesap canlı olarak doğrulanamadı. GitHub sekmesine normal erişim yeniden denendi ve kayıtlı izin/yönetilen politika kapısında reddedildi. Bu engel başka yüzeyle aşılmadı; depo oluşturulmadı ve push yapılmadı.

## Sonraki adım

Yerel depo içeriği Masaüstü/Molaqo altındadır. GitHub erişimi açıldığında kullanıcı hesabını doğrula, molaqo-ios adlı özel depo oluştur ve main dalını push et. Sonra docs/CODEMAGIC.md içindeki simulator işiyle ilk gerçek derlemeyi yap. CarPlay yetkisi ve araç doğrulaması tamamlanınca project-carplay.yml kullanılabilir. Sıfır gecikme veya sistemden gizleme desteği yoktur.
