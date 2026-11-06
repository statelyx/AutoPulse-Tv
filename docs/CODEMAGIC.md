# Codemagic başlangıcı

Depo kökünde project.yml, codemagic.yaml, Sources ve Resources klasörleri birlikte bulunmalı. Tüm outputs klasörünü depo kökü olarak yükleme; Molaqo klasörünün içeriğini kullan.

## İlk derleme: simulator

1. Codemagic uygulamasına GitHub deposunu bağla.
2. Native iOS / codemagic.yaml seç; main dalını tara.
3. `simulator` işini çalıştır. Apple sertifikası veya API anahtarı gerekmez.
4. Build ve XCTest loglarını kontrol et. Başarısız test veya derleme varsa imzalı işe geçme.
5. Artifacts içindeki TestResults.xcresult, ekran görüntüsü ve .app dosyasını incele. UI testi gerçek ekran görüntülerini xcresult eklerine alır; bunlar test verisi içerir ve mağaza görseli olarak otomatik onaylanmış değildir.

## İkinci derleme: testflight

Apple hesabında uygulama kaydı, benzersiz bundle ID ve dağıtım yetkileri hazır olmalı. Varsayılan bundle ID `com.statelyxx.molaqo`; Apple kaydı farklıysa project.yml ve codemagic.yaml birlikte değiştirilmeli.

Codemagic'te yetkili mevcut entegrasyonun adını YAML'daki `Molaqo App Store Connect` yerine yaz. App Store dağıtım sertifikası ve profile ihtiyaç var. Anahtar veya sertifika dosyalarını Git deposuna ekleme.

Bu ayarlar doğrulanınca `testflight` işi imzalı IPA oluşturup Apple'a yükler ve beta işleme/gönderimini ister. Beta grubuna erişim, Apple processing ve gerektiğinde beta review ayrı aşamalardır. Build numarası Codemagic BUILD_NUMBER ile artar; başka bir pipeline kullanıldıysa çakışmadığını kontrol et.

## CarPlay derlemesi

Önce docs/CARPLAY.md dosyasını oku. Yetki alındıktan sonra `PROJECT_SPEC` değerini `project-carplay.yml` yap. İmzalama profili `com.apple.developer.carplay-video` içermeli. İlk CarPlay build'ini simülatör ve gerçek uyumlu araçla ayrıca doğrula. Varsayılan simulator işi CarPlay sahnesini derlemez; CarPlay doğrulaması için proje üretim adımını aynı spec ile değiştir.

## Bu teslimde yapılmamış işlemler

GitHub hesabı tarayıcı erişim engeli nedeniyle doğrulanamadı. Depo oluşturulmadı ve push yapılmadı. Codemagic üzerinde bu işler çalıştırılmadı. TestFlight'a binary gönderilmedi. Windows'taki sözdizimi doğrulaması Apple SDK type-check, link veya runtime testi değildir.
