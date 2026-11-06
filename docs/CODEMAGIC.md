# Codemagic başlangıcı

Depo: https://github.com/statelyx/AutoPulse-Tv

Dal: `main` · Proje türü: native iOS / XcodeGen · YAML: depo kökündeki `codemagic.yaml` · Scheme: `AutoPulseTV`.

Kod ayrıca dosya yükleyerek taşınmaz; Codemagic bu GitHub deposunu klonlar. Hesapta uygulama kaydı eklemek, yalnız YAML dosyasını GitHub'a göndermekten ayrı bir adımdır.

Varsayılan iOS projesi GitHub Actions'ta derlendi; 6 birim + 1 UI testi geçti. [Doğrulanmış çalışma](https://github.com/statelyx/AutoPulse-Tv/actions/runs/42200973648). Bu sonuç Codemagic hesabında uygulamanın eklenmiş veya derlenmiş olduğu anlamına gelmez.

## İlk derleme: simulator

1. Codemagic Applications sayfasında Add application adımından `statelyx/AutoPulse-Tv` deposunu seç. Mevcut GitHub bağlantısını kullan; farklı bir uygulamanın kayıtlı app_id değerini yeniden kullanma.
2. Native iOS / codemagic.yaml seç; main dalını tara.
3. `simulator` işini çalıştır. Apple sertifikası veya API anahtarı gerekmez.
4. Build ve XCTest loglarını kontrol et. Başarısız test veya derleme varsa imzalı işe geçme.
5. Artifacts içindeki TestResults.xcresult, ekran görüntüsü ve .app dosyasını incele. UI testi gerçek ekran görüntülerini xcresult eklerine alır; bunlar test verisi içerir ve mağaza görseli olarak otomatik onaylanmış değildir.

## İkinci derleme: testflight

Apple hesabında uygulama kaydı, benzersiz bundle ID ve dağıtım yetkileri hazır olmalı. Varsayılan bundle ID `com.statelyxx.autopulsetv`; Apple kaydı farklıysa project.yml ve codemagic.yaml birlikte değiştirilmeli.

Codemagic'te yetkili mevcut entegrasyonun adını YAML'daki `AutoPulseTV App Store Connect` yerine yaz. App Store dağıtım sertifikası ve profile ihtiyaç var. Anahtar veya sertifika dosyalarını Git deposuna ekleme.

Bu ayarlar doğrulanınca `testflight` işi imzalı IPA oluşturup Apple'a yükler ve beta işleme/gönderimini ister. Beta grubuna erişim, Apple processing ve gerektiğinde beta review ayrı aşamalardır. Build numarası Codemagic BUILD_NUMBER ile artar; başka bir pipeline kullanıldıysa çakışmadığını kontrol et.

## CarPlay derlemesi

Önce docs/CARPLAY.md dosyasını oku. Yetki alındıktan sonra `PROJECT_SPEC` değerini `project-carplay.yml` yap. İmzalama profili `com.apple.developer.carplay-video` içermeli. İlk CarPlay build'ini simülatör ve gerçek uyumlu araçla ayrıca doğrula. Varsayılan simulator işi CarPlay sahnesini derlemez; CarPlay doğrulaması için proje üretim adımını aynı spec ile değiştir.

## Bu teslimde yapılmamış işlemler

GitHub hesabı mevcut Git Credential Manager oturumuyla statelyx olarak doğrulandı ve kaynak kodu main dalına push edildi. GitHub Actions'ın varsayılan simülatör build'i ve testleri doğrulandı. Codemagic üzerinde uygulama ekleme veya build başlatma henüz yapılamadı: 6 Kasım 2026 tarihinde mevcut Codemagic sekmesine erişim kayıtlı izin/yönetilen politika kapısında reddedildi. Bu uygulama için Codemagic app_id veya build ID elde edilmedi. TestFlight'a binary gönderilmedi.

Resmi referans: https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/
