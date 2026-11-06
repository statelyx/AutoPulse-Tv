# Doğrulama matrisi

Yerel sözdizimi kontrolü VALIDATION.json içindedir. GitHub Actions'ın Apple SDK derleme/test sonucu ayrı olarak [CI kanıtında](verification/2026-11-06-ci.json) kaydedilir.

6 Kasım 2026'da `2d9be98` commit'i için varsayılan iOS simülatör derlemesi, aşağıdaki 6 birim testi ve 1 UI testi geçti. Gerçek cihaz ve opsiyonel CarPlay testleri hâlâ bekliyor.

## Otomatik XCTest senaryoları

- M3U içinde tırnaklı virgül, grup, göreli HTTPS adresi ve tekrarlı kaynağı ayıklama.
- HLS manifestini video kaynağı olarak tutma; segmentleri kanal diye kaydetmeme.
- Güvensiz/boş adres ve büyük dosya reddi.
- Canlı, geçersiz süreli ve bitmiş videoda yanlış devam konumu kullanmama.
- Favori ve izleme konumunu yeniden açılışta geri getirme; duplicate eklememe.
- Bozuk kayıt dosyasını yeni bir kayıtla ezmeme.
- UI üzerinden kaynak ekleme, yeniden açılış, bilgi ekranı ve yön değişiminde ekran görüntüsü.

## Gerçek cihaz kabul testleri

| Test | Beklenen davranış | Durum |
| --- | --- | --- |
| MP4 / VOD HLS | Başlat, duraklat, seek, tam ekran, kapanış | Çalıştırılmadı |
| Canlı HLS | Eski kayıt konumuna atlamadan oynat | Çalıştırılmadı |
| Ağ kesilmesi / geri gelmesi | Bekleme veya anlaşılır hata; sessizce kaynak değiştirmeme | Çalıştırılmadı |
| YouTube / başka HTTPS site | Gezinme, kullanıcı dokunuşuyla video, hata bildirimi | Çalıştırılmadı |
| Gömülü tarayıcıda hesap girişi | Site izin veriyorsa giriş; aksi durumda Safari alternatifi | Çalıştırılmadı |
| Web video tam ekran | Sayfanın yerel WebKit medya kontrolleri | Çalıştırılmadı |
| Web process kapanması | Yenileme için hata mesajı | Çalıştırılmadı |
| JSON yedekleme / dosyadan geri alma | Geçerli kaynaklar, URL tekrarı olmadan birleşme | Çalıştırılmadı |
| CarPlay yetkili build | Uygun araçta katalog ve video | Çalıştırılmadı |
| Desteksiz araç | Video desteği varmış gibi davranmama | Çalıştırılmadı |
| Araç video uygunluğu değişimi | Sistem video/ses davranışını koruma | Çalıştırılmadı |
| Yatay/dikey CarPlay ekranı | Sistem şablonlarının doğru yerleşimi; kırpma olmaması | Çalıştırılmadı |
| Araç bağlantısı kopması | Pozisyon kaydı ve oturumun durması | Çalıştırılmadı |
| 30+ dk A/V senkronizasyonu | Gözlenen drift, drop ve kesilme sayısını raporlama | Çalıştırılmadı |

Ölçüm raporuna araç/ana ünite firmware, iPhone modeli, iOS sürümü, uygulama commit'i, kablolu/kablosuz bağlantı ve kullanılan test kaynağı eklenmeli. Özel veya token içeren adresler kamuya açık loglara konmamalı.
