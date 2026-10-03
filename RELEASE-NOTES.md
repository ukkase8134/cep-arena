# Cep Arena 1.0.0

Android ve Windows için Türkçe, 2–4 kişilik mini oyun koleksiyonu.

- Üç 3D ve üç 2D oyun: Kristal Kapmaca, Renk Adası, Dönen Çember, Neon Hokey, Roket Ralli ve Meteor Yağmuru.
- Botlarla tek maç ve üç oyunluk turnuva; üç bot zorluğu.
- Aynı ağdaki ayrı cihazlardan LAN maçı. PC'ler aynı Radmin VPN ağı üzerinden oda sahibinin IP'siyle bağlanabilir.
- Aynı cihazda bir klavye/mouse veya dokunmatik oyuncusu ve ayrı gamepad'ler. Örneğin bir klavye + iki gamepad = üç kişi.
- Xbox / PlayStation tuş gösterimi, ölü bölge, titreşim ayarları ve test düğmesi.
- Windows XInput kontrolcüleri için yerel titreşim köprüsü; oyun olaylarında rumble ve elle titreşim testi.
- İmzalı Android APK ve PCK gömülü, tek dosyalı Windows EXE.

[İndirme sayfası ve LAN rehberi](https://ukkase8134.github.io/cep-arena/)

**Doğrulama:** 286 oyun/girdi kontrolü geçti. Bir oda sahibi ve üç bağımsız istemci süreciyle altı oyun sınandı. Menü ve oyunlar gerçek GPU'da incelendi. APK imzası doğrulandı; Windows EXE çalıştırıldı. Bağlı Xbox 360 tabanlı kontrolcüde giriş ve küçük titreşimler kullanıcı tarafından doğrulandı.

**Test kapsamı:** Fiziksel Android telefon, PS4, aynı anda iki fiziksel gamepad ve gerçek dört PC/Radmin ağı henüz denenmedi. Android gamepad/titreşim desteği kodda mevcut; cihaz üzerindeki sonuç sürücüye bağlıdır. Windows EXE yayıncı sertifikasıyla imzalanmamıştır. Ayrıntılar [QA.md](https://github.com/ukkase8134/cep-arena/blob/codex/cep-arena/QA.md).

GitHub, dosyaları ve indirme sayfasını barındırır. LAN maçlarında oyun sunucusu oda sahibinin cihazıdır.
