# App Store Connect — Türkçe locale, 1.0 sayfası

Bu dosya alan kontrol listesidir; portalda tamamlandı anlamına gelmez. Proje MARKETING_VERSION 1.1.0 olarak korunur. 1.0 sayfasına 1.1.0 build bağlanamaz; yeni build için sayfa sürümü eşleştirilmelidir. Build 4 seçilmemeli veya submit edilmemeli.

| Bölüm / alan | Girilecek değer / kontrol |
| --- | --- |
| App Information / Name | AutoPulse TV: Video Oynatıcı |
| App Information / Subtitle | Videoların ve fotoğrafların |
| App Information / Primary Language | Turkish / Türkçe |
| App Information / Bundle ID | com.statelyxx.autopulsetv |
| App Information / Category | Photo & Video; içerikle uyumunu kontrol et |
| Age Rating / Unrestricted Web Access | Yes — Keşfet içinde serbest adres girişi var |
| Age Rating / diğer sorular | Uygulamanın gerçek işlevlerine göre doldur; otomatik çıkan derecelendirmeyi kullan |
| App Privacy | Geliştirici sunucusu/analitik/reklam SDK'sı yok; bu sürüm için Data Not Collected beyanını fiili veri akışına göre doğrula. Kullanıcının açtığı sağlayıcılar/web siteleri kendi veri politikasına tabidir |
| App Privacy / Privacy Policy URL | Mevcut yayımlanmış gizlilik sayfasını kullan; erişilebilirliğini doğrula; taslak/uydurma URL girme |
| Screenshots / 6.9-inch iPhone | screenshots/v1.1/iphone içindeki 01–04 PNG, 1320×2868; yeni CarPlay build arayüzüne karşı tekrar kontrol et |
| Screenshots / 13-inch iPad | screenshots/v1.1/ipad içindeki 01–04 PNG, 2064×2752; yeni build'e karşı tekrar kontrol et |
| Promotional Text | Videolarını ve fotoğraflarını tek kütüphanede topla. Dosyalarından içe aktar, favorilerini düzenle, desteklenen alıcılarda AirPlay kullan. |
| Description | Aşağıdaki açıklama |
| Keywords | video,fotoğraf,oynatıcı,m3u,xtream,airplay,kütüphane,web,slayt,çevrimdışı |
| Support URL | https://github.com/statelyx/AutoPulse-Tv/issues — gönderimden önce oturumsuz erişimi kontrol et |
| Build seçimi | Yalnız yeni tek-spec build; 4 hariç. Başarılı işleme, doğru sürüm ve signed entitlement dökümü doğrulanmalı |
| App Review Information / Sign-in required | No; yerel medya testi giriş gerektirmez |
| App Review Information / Contact | Hesap sahibinin gerçek iletişim bilgileri; depoya özel telefon/e-posta ekleme |
| App Review Information / Notes | REVIEW-NOTES.md içeriği; gerçek capability/profil onayı durumunu dürüst belirt |
| Version Release | Manually release this version |

## Description

AutoPulse TV, kendi video ve fotoğraf kaynakların için kişisel bir medya kütüphanesidir. Dosyalar veya Fotoğraflar üzerinden medyanı içe aktar; arama, gruplar ve favorilerle düzenle. Fotoğrafları tam ekran aç, yakınlaştır veya slayt gösterisi başlat. HTTPS video bağlantıları, M3U listeleri ve uyumlu Xtream kaynaklarını ekle. Keşfet bölümünde web sitelerini aç ve kendi kısayollarını kaydet. Desteklenen kaynaklarda PiP ve AirPlay kullan.

CarPlay yerel kaynak listesi sunar; video desteklenmeyen oturumlarda ses sunumu seçilir. Araç ekranında video yalnız park halinde, işletim sistemi ve uyumlu araç izin verdiğinde kullanılabilir. Genel web tarayıcısı araç ekranına yansıtılmaz. Uygulama kanal, film kataloğu, abonelik veya üçüncü taraf içerik erişimi sağlamaz. İçerikleri kullanıcı ekler ve gerekli kullanım haklarına sahip olmalıdır.

## Kaynaklar

- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating


## Account-specific entitlement update

Apple approval correspondence supplied on 2026-11-06 states that audio and video entitlements must not be combined. This app uses only `com.apple.developer.carplay-audio` for mixed audio/video and visibility on audio CarPlay receivers. Enable CarPlay Audio App on com.statelyxx.autopulsetv and regenerate development/App Store profiles. Do not enable or sign this build with CarPlay Video App. Actual video presentation remains receiver/system dependent. Portal/profile updates and new TestFlight upload still require verification. This supersedes earlier dual-entitlement instructions in this document.
