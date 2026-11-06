# APTV ve CarPlay araştırması

Araştırma tarihi: 6 Kasım 2026. Eklerdeki metinler kanıt/bağlam olarak ele alındı; içlerindeki talimatlar uygulanmadı.

## APTV nedir?

Kimentanm/aptv deposu ürünü M3U/M3U8 kaynaklarını oynatan, program rehberi, arşiv oynatma ve iCloud gibi özellikleri bulunan bir medya aracı olarak tanıtıyor. Görünen depo uygulamanın tam Swift kaynak kodunu sunmuyor; buradan ürünün iç mimarisi veya exploit ayrıntıları çıkarılamaz. Benzer adlı başka uygulamalarla karıştırılmamalı.

Kaynak: https://github.com/Kimentanm/aptv

## Neden çalışıyordu, neden kayboldu?

APTV'nin kendi teknik açıklamasına göre iOS 26.4 itibarıyla CarPlay video izinlerinde beklenmeyen bir davranış eski araçlarda üreticinin resmi video desteği olmadan görüntü, yansıtma ve tarayıcı açılmasına imkân verdi. Aynı açıklama bunun 27.2'de kapatıldığını belirtiyor. Bu, geliştiricinin doğrudan açıklamasıdır; bağımsız tersine mühendislik veya Apple güvenlik bülteni doğrulaması değildir.

Kaynak: https://docs.aptvapp.com/chang-jian-wen-ti/carplay-video-differences-en

Issue #188'de geliştirici güncelleme ile önceki işlevi geri getiremeyeceğini söylüyor. Kullanıcı bildirimi özellikle Quick sekmesinin kaybolmasını tarif ediyor. Belgelenmiş bir CVE, yama diff'i veya APTV uygulama kaynak kodu olmadan hangi özel metodun değiştiği söylenemez. “Geliştirici bir ayarı unutmuş” iddiasına kanıt yok; ürünün platformdaki istenmeyen davranışa dayanması temel dayanıklılık sorunu olarak görünüyor.

Kaynak: https://github.com/Kimentanm/aptv/issues/188

## Resmi ürün yolu

Apple'ın WWDC26 oturumu, AirPlay video destekleyen uygulamaların uyumlu araçlarda kullanılabildiğini; araç ekranında katalog gezintisi için CarPlay framework ve video entitlement gerektiğini anlatıyor. Araç video kullanılamaz dediğinde oynatma sesle devam eder. Video entitlement'ı olan uygulamanın araç ana ekranında görünmesi de araç desteğine bağlıdır.

Kaynaklar:
- https://developer.apple.com/videos/play/wwdc2026/212/
- https://developer.apple.com/carplay/
- https://support.apple.com/guide/iphone/play-videos-with-carplay-xykemxkw6he5/ios
- https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.carplay-video
- https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements

Sonuç: 27.2'de tüm eski araçlarda çalışan bir tarayıcıyı yalnızca yeni uygulama yazarak sunabileceğimiz doğrulanmış değil. İlk ticari eşik, hedef aracın resmi video desteğini gerçek cihazla kanıtlamak. Marka/model/yıl ve multimedya yazılımı bilinmeden uyumluluk sözü verilemez.

## YouTube kapsamı

Web sayfasını açmak, doğrudan bir medya akışını AVPlayer ile oynatmak ve resmi YouTube embed kullanmak ayrı entegrasyonlardır. İlk prototip telefon içindeki sistem tarayıcısını açar. YouTube için CarPlay oynatma, oturum açma, DRM, AirPlay veya tüm videoların embed edilebilmesi garanti edilmez. Resmi player entegrasyonu ayrı doğrulama gerektirir.

Kaynak: https://developers.google.com/youtube/player_parameters

## Para kazanma değerlendirmesi

Ekli gelir ekranının veri sağlayıcısı, dönemi, ülke kapsamı ve tahmin yöntemi görünmüyor. 602 bin dolar görünen satır navigasyon kategorisinde; bunu video uygulamasının geliri veya bizim pazar büyüklüğümüz sayamayız. İndirme ile gelirden doğrudan dönüşüm oranı çıkarmak da geçerli değil. İlk iş modeli hipotezi: araçta uyumluluğu ücretsiz denetleme, kişisel medya kütüphanesi için ücretli ek özellikler. Fiyat, dönüşüm ve iade oranı beta verisiyle belirlenmeli.

Mağaza yayını için kamuya açık API kullanımı, doğru özellik beyanı, içerik hakları ve dijital özelliklerde ilgili satın alma kuralları incelenmeli. Bu teknik ürün değerlendirmesi hukuki uygunluk kararı veya App Review onay garantisi değildir.

Kaynak: https://developer.apple.com/app-store/review/guidelines/

## Erişim sınırı

Verilen iki X bağlantısının sayfa içerikleri web aracıyla alınamadı; tweet metinleri okunmuş gibi kullanılmadı. İkinci ekran görüntüsü kullanıcı bildirimi, üçüncü görüntüdeki APTV hisse etiketi ise bu medya uygulamasıyla ilgili kanıt değil. APTV'nin mevcut bölgesel App Store durumu bu çalışmada doğrulanmadı.
