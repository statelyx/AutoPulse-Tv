# Doğrulama notları

- 2026-11-06: `CPSessionConfiguration.supportsVideoPlayback` adı Apple'ın resmi API belgesinde Swift `var supportsVideoPlayback: Bool { get }` olarak doğrulandı: https://developer.apple.com/documentation/carplay/cpsessionconfiguration/supportsvideoplayback
- Bu Windows ortamında Xcode/iOS 27 SDK header'ı bulunmadığından doğrudan iOS 27 `CPSessionConfiguration.h` doğrulaması yapılamadı. API adı değiştirilmedi; SDK header doğrulaması ve Apple SDK ile derleme bekliyor. Belge kontrolü header kontrolü yerine geçmez.
- macOS üzerinde kontrol: `SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)` ardından `rg -n 'supportsVideoPlayback|videoPlaybackSupported' "$SDKROOT/System/Library/Frameworks/CarPlay.framework/Headers/CPSessionConfiguration.h"`. `xcrun --sdk iphoneos --show-sdk-version` çıktısıyla SDK sürümü de kaydedilmeli.
