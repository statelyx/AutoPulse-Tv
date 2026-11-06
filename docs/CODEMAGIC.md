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

Önce docs/CARPLAY.md dosyasını oku. `carplay-compile` işi CarPlay projesini Xcode 27.1 ile imzasız derlemek için hazırlandı; henüz çalıştırılmadı. Bu iş alıcı bağlantısını test etmez ve TestFlight IPA üretmez. Yetki alındıktan sonra imzalı işte `PROJECT_SPEC` değerini `project-carplay.yml` yap ve uyumlu Xcode sürümünü seç. İmzalama profili `com.apple.developer.carplay-video` içermeli. Varsayılan simulator işi CarPlay sahnesini derlemez. Windows alıcı araştırması ve paket kontrolü: [test rehberi](WINDOWS-CARPLAY-TESTING.md).

## Bu teslimde yapılmamış işlemler

GitHub Actions'ın varsayılan simülatör build'i ve testleri doğrulandı. Kullanıcının paylaştığı Codemagic ekranında uygulama eklenmiş ve simulator işi seçilmiş durumda. Bildirilen uygulama kimliği `6aedac2730f39d49d7284dcf`; [ilk build](https://codemagic.io/app/6aedac2730f39d49d7284dcf/build/6aedac3f7bd3d716e2eb5412) sonucu burada doğrulanmadı. TestFlight'a binary gönderimi doğrulanmadı.

Resmi referans: https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/
