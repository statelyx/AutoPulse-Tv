| Madde | Durum |
| --- | --- |
| A1 CarPlay kaynakları project.yml sources'a | tamam |
| A2 project.yml entitlements.path = CarPlay/AutoPulseTV.entitlements | tamam |
| A3 Entitlements'a carplay-audio + carplay-video | tamam |
| A4 Explicit Info.plist + CPTemplateApplicationSceneSessionRoleApplication + delegate | tamam |
| A5 refresh() video-desteklemez dalında liste kalsın, preferredPresentation .audio | tamam |
| A6 Info.plist ve entitlements için regresyon testi | tamam |
| A7 codemagic tek spec, carplay-compile ayrı workflow kaldırılsın | tamam |
| A8 project-carplay.yml silinsin, README/docs/CARPLAY.md güncellensin | tamam |
| A9 store/APPSTORE-CONNECT.md + store/REVIEW-NOTES.md | tamam |

Durum kolonu kaynak kodu/yapılandırma teslimini ifade eder. Apple capability onayı, profil yenileme, iOS SDK derlemesi, regresyon testlerinin çalışması ve gerçek araç testi ayrıca doğrulanmalıdır; bu tablo bunların başarılı olduğunu beyan etmez.
