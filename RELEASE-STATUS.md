# Teslim durumu — 6 Kasım 2026

## Kimlik ve yer

- Ürün adı: AutoPulse TV
- Mağaza başlığı: AutoPulse TV: Video Oynatıcı
- Yerel kaynak proje: Masaüstü/AutoPulseTV
- Xcode proje / scheme: AutoPulseTV
- GitHub: https://github.com/statelyx/AutoPulse-Tv
- Dal: main; origin/main takip ediliyor.

## GitHub

Kullanıcının mevcut Git Credential Manager oturumu üzerinden GitHub hesabı statelyx olarak doğrulandı. Önceden oluşturulmuş herkese açık AutoPulse-Tv deposu bulundu. Uzak deponun başlangıç README commit'i yerel geçmişle birleştirildi ve normal push başarılı oldu. Force push yapılmadı. Yerel .local arşivi Git dışında tutulur.

## Doğrulama

Dokuz Swift dosyasının yerel sözdizimi ve YAML/plist/JSON kontrolleri geçti. GitHub Actions run 42200973648 içinde varsayılan iOS simülatör build'i, 6 birim testi ve 1 UI testi başarıyla tamamlandı. Kaynak commit: 2d9be98. Gerçek ekran görüntüsü docs/images/library-iphone.png, yapılandırılmış kanıt docs/verification/2026-11-06-ci.json içindedir.

Gerçek iPhone/araç testleri, ayrı CarPlay build'i, imzalı IPA, TestFlight ve App Store yayını henüz doğrulanmadı. VALIDATION.json yerel statik kontrolle sınırlıdır.

## Codemagic

YAML ve kurulum rehberi GitHub'da hazır. Codemagic hesabında depo bağlantısı ve ilk build başlatılamadı; mevcut sekmeye erişim kayıtlı izin/yönetilen politika kapısında reddedildi. Bu projeye ait Codemagic app_id veya build ID yoktur.

## Sonraki adım

Codemagic'te bu depoyu bağlayıp önce simulator işini çalıştır. docs/CODEMAGIC.md içindeki adımları kullan. CarPlay video yetkisi ve gerçek araç doğrulaması sonrasında project-carplay.yml tercih edilebilir. Telefon WebKit tarayıcısı mevcuttur; resmi CarPlay video entegrasyonu ayrı ve henüz test edilmemiştir.
