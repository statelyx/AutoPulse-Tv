# Molaqo

Yerel iPhone/iPad video kütüphanesi ve isteğe bağlı resmi CarPlay video entegrasyonu. Kaynak kodu teslimidir; Apple SDK ile derlendiği veya gerçek araçta çalıştığı henüz doğrulanmadı.

## Özellikler

- Koyu tema, arama, favoriler, yatay/dikey SwiftUI yerleşimi.
- HTTPS doğrudan medya kaynakları, AVPlayer oynatımı, tam ekran görünümü ve AirPlay hedef seçimi.
- Kaydedilen izleme konumundan devam etme.
- HTTPS üzerinden veya yerel dosyadan M3U içe aktarma; grup bilgisi ve yinelenen kaynak kontrolü.
- HLS manifestlerini kanal listesiyle karıştırmayan ayrıştırıcı.
- JSON kütüphane dışa aktarma ve geri yükleme.
- Atomik yerel kayıt; bozuk dosyayı sessizce ezmeme.
- iPhone/iPad üzerinde WebKit tarayıcı, ileri/geri, yenileme, adres alanı ve YouTube kısayolu.
- Ayrı CarPlay konfigürasyonunda yerel CPListTemplate kataloğu ve resmi video oynatma tercihi.
- 1024px opak ikon, gizlilik manifesti, XCTest ve UI testleri, Codemagic ve GitHub Actions yapılandırması.

## Derleme

Mac üzerinde Xcode ve XcodeGen ile:

```sh
xcodegen generate
open Molaqo.xcodeproj
```

Xcode'da Team ve kullanılabilir bundle ID seç. Scheme: Molaqo. Testleri Xcode Product > Test ile veya `bash scripts/simulator.sh` komutuyla çalıştır.

CarPlay yetkisi alındıktan sonraki ayrı derleme:

```sh
xcodegen generate --spec project-carplay.yml
```

Bu spec iOS 27 ve Apple'ın CarPlay video entitlement yetkisini gerektirir. Sadece entitlement dosyası eklemek yetki sağlamaz. CarPlay video oynatımı henüz doğrulanmadı. Varsayılan iPhone derlemesi CarPlay ana ekranında görünmez.

## Teknik sınırlar

Ekran yansıtma, ReplayKit, sistemden video gizleme veya hareket kısıtlamasını aşma kodu yoktur. CarPlay ekranındaki yerleşimi sistem şablonları yönetir. Genel web tarayıcısı yalnız telefondadır. Tüm araçlarda video, sıfır gecikme, YouTube harici oynatma veya DRM uyumluluğu vaat edilmez. Gerçek ekran görüntüleri CI/Simulator çalıştırılınca üretilecektir.

Tam ekran sunum, görüntü oranı, A/V senkronizasyonu ve araç ekranının yönüne uyum gerçek donanımda ölçülmelidir. Kaynaklar kullanıcı tarafından sağlanır; uygulama kanal veya film kataloğu içermez.

## Dosyalar

- docs/CODEMAGIC.md: sonraki Codemagic adımları.
- docs/CARPLAY.md: resmi CarPlay entegrasyonu ve doğrulama kapsamı.
- Tests / UITests: ayrıştırma, kayıt koruma, devam konumu ve kullanıcı akışı testleri.
- VALIDATION.json: bu ortamda yapılan kontrolün sonucu.
- store/: mağaza metinleri ve henüz yayınlanmamış gizlilik taslağı.
- ARASTIRMA.md: APTV araştırması ve kaynaklar.
- docs/APTV-FINDINGS.md: mağazadan kaldırılma, sürüm kırılmaları ve mühendislik kararları.
- docs/NAME.md: isim ve teknik kimlikler.

Yerel statik kontrol (Xcode derlemesi değildir):

```sh
python -m pip install -r scripts/requirements-dev.txt
python scripts/validate.py
```

## Henüz tamamlanmayan yayın işleri

GitHub push, Xcode derlemesi, XCTest çalıştırma, CarPlay cihaz testi, imzalama, TestFlight ve App Store yayını yapılmadı. Destek/gizlilik sayfaları ve inceleme iletişim bilgileri de hesap erişimiyle tamamlanmalı. Mevcut mağaza metinleri varsayılan iPhone derlemesini tanımlar; CarPlay sürümüne geçince güncellenmeli.
