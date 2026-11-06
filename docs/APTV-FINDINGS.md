# APTV'den çıkan ürün ve mühendislik kararları

6 Kasım 2026. “Tüm internet tarandı” iddiası yoktur. Birincil belgeler, geliştirici güncellemeleri, GitHub sorunları ve haber aramaları incelendi. Kullanıcının iki X bağlantısı doğrudan erişimde 403 verdi; tweet içeriği okunmuş gibi kullanılmadı. Benzer isimli uygulamalar ve doğrulanmamış rehber siteleri ürünün resmi kaynağı sayılmadı.

## İki farklı kırılma

APTV'nin teknik açıklaması, eski CarPlay video yönteminin iOS 26.4'teki beklenmeyen izin davranışına dayandığını ve iOS 27.2'de kapatıldığını belirtiyor. Bu geliştirici açıklamasıdır; bağımsız yama analizi veya CVE kanıtı değildir. Molaqo'da aynı davranışın gizlenerek sürdürülmesi uygulanmadı.

Kaynak: https://docs.aptvapp.com/chang-jian-wen-ti/carplay-video-differences-en

Geliştiricinin 23 Ekim duyurusu ayrıca uygulamanın mağazadan kaldırıldığını ve mevcut CarPlay video işlevi kaldırılmadan geri dönemeyeceğini söylüyor. Bu duyuru, yalnız işletim sistemi güncellemesi açıklamasından ayrı bir dağıtım sorunu gösterir. Duyurudan bütün resmi CarPlay video uygulamalarının yasaklandığı sonucu çıkmaz.

Kaynak: https://aptvplayer.userjot.com/updates/p/important-notice

Issue #195'te kullanıcılar APTV 1.5.13'e geçince iOS 27.0 ve daha eski sistemlerde de tarayıcıyı kaybettiklerini bildiriyor. Bu gözlemler OS değişikliği ile uygulama sürümü değişikliğinin ayrı izlenmesi gerektiğini gösterir. Bildirilen tüm cihaz/sürüm eşleşmeleri bu çalışmada tekrar test edilmedi.

Kaynak: https://github.com/Kimentanm/aptv/issues/195

## APTV'nin gerçek kapsamı

Görünen resmi depo M3U/M3U8, program rehberi, arşiv oynatma, iCloud ve platform desteğini tanıtıyor. Tam uygulama kaynakları görünmediğinden iç mimariyi birebir bildiğimiz söylenemez. Molaqo sıfırdan yazıldı; APTV'nin ikili dosyası, özel API implementasyonu veya lisansı belirsiz kaynakları kopyalanmadı.

Kaynak: https://github.com/Kimentanm/aptv

## Sorundan karara

| Bulgu / risk | Molaqo'daki karar | Doğrulama durumu |
| --- | --- | --- |
| OS tarafından kapatılabilen gayriresmi video yolu | Resmi CarPlay video entitlement ve CPSessionConfiguration yetenek kontrolü | Kod var; Apple SDK / araç testi yok |
| Araç video desteğinin belirsizliği | Desteksiz alıcıya açıklama, ayrı CarPlay build spec | Araç üzerinde doğrulanmadı |
| Tarayıcının sürüm güncellemesinde kaybolması | Telefon WebKit tarayıcısı ile resmi CarPlay kataloğu ayrı katmanlar | Sözdizimi kontrol edildi; cihaz testi bekliyor |
| Oynatma zamanı ve ses atlaması bildirimi | Tek AVPlayer saat hattı; otomatik bekleme; hazır olmadan seek yapmama; canlı yayında eski konumu uygulamama | Bildirilen akışla karşılaştırma yapılmadı |
| Bozuk/boş listeler ve tekrarlı kaynaklar | Sınırlı boyutta M3U okuma, HTTPS doğrulama, duplicate ayıklama, hata mesajı | XCTest senaryoları yazıldı; çalıştırılmadı |
| Veri dosyasının bozulması | Atomik kayıt, bozuk dosyayı ezmeme, JSON yedekleme | XCTest senaryosu yazıldı; çalıştırılmadı |
| Uyumluluk anlaşılmadan ücret alınması | Önce ücretsiz uyumluluk denemesi, sonra doğrulanmış ek özellik için satın alma | Henüz ödeme sistemi yok |

## Ses/görüntü neden “kesin düzeldi” denemez?

Issue #173'te bir kullanıcı KSPlayer ile HLS/TS arşiv oynatımında ses atlaması bildiriyor; VLC karşılaştırması da kullanıcı beyanı. Zaman damgası sorununa ilişkin şüphe henüz kanıtlanmış kök neden değil. Molaqo AVPlayer kullanır; bu seçim tüm bozuk kaynaklarda aynı hatayı giderdiğimiz anlamına gelmez. Aynı akış ve donanımla uzun süreli ölçüm gerekir.

Kaynak: https://github.com/Kimentanm/aptv/issues/173

Apple'ın otomatik bekleme davranışı ağ kesilmelerinde buffer yönetimi içindir; sıfır gecikme taahhüdü değildir. Kod, bu özelliği açık tutar. Hız için ses/görüntü senkronizasyonu elle bozulmaz.

Kaynak: https://developer.apple.com/documentation/avfoundation/avplayer/automaticallywaitstominimizestalling

## Tarayıcı

WKWebView tabanlı telefon içi tarayıcı: adres alanı, ileri/geri, yenile/durdur, yüklenme durumu, popup'ın aynı görünümde açılması, hata ve web process kapanması bildirimi, Safari alternatifi. JavaScript ile medya adresi kazıma, koruma/DRM atlatma veya video kullanımını sistemden saklama yok. YouTube ve diğer sitelerin gömülü tarayıcıda giriş, video ve AirPlay kararları hizmete bağlıdır.

Kaynak: https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/allowsairplayformediaplayback

## Ticari doğrulama

Önce gerçek araç uyumluluğu ve başarılı video başlatma oranı. Ardından oynatma oturumu kararlılığı, yeniden kullanım ve iade nedenleri. İlk gelir deneyi, ücretsiz çekirdek üstüne tek seferlik Pro olabilir; abonelik için sürekli hizmet gerekçesi yoksa eklenmemeli. Reklam/analitik SDK'sı veya ödeme kodu henüz yok. Kullanıcının gelir ekranından pazar büyüklüğü veya garanti gelir çıkarılmadı.

## Yayın öncesi açık işler

İki build'in Xcode derlemesi; XCTest ve UI testleri; gerçek iPhone/iPad web video ve oturum akışları; CarPlay yetkisi; uyumlu yatay/dikey ekranlarda yerleşim; park/video uygunluğu değişimi; bağlantı kopması; HLS discontinuity ve canlı yayın; gerçek ekran görüntüleri; gizlilik/yaş formu; içerik hakları; StoreKit ürünü gerekiyorsa ayrı uygulama ve test.
