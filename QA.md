# Cep Arena 1.1.0 — doğrulama

Tarih: 3 Ekim 2026. Windows, Godot 4.7.2 stable. GPU: AMD Radeon RX 6600.

## Tamamlanan kontroller

- Godot proje içe aktarma ve GDScript derleme başarılı.
- **340 simülasyon kontrolü, 0 başarısızlık:** yedi oyun, 2/3/4 oyuncu ve üç bot seviyesi; bomba koyma, tutulan tuşun tekrar bomba üretmemesi, sandık/duvar engellemesi, puan kredisi, yeniden doğma koruması ve zincirleme patlama dahil.
- **21 arayüz kontrolü, 0 başarısızlık:** Godot'a gönderilen gamepad/klavye olaylarıyla gerçek menü odağı, çubuk/D-pad, A ile seçim, onay kutusu, kaydırıcı, açılır menü, iç içe pencereler, geri dönünce odağın korunması, maçtan B/Start/sistem geri ile menüye dönüş ve son adımda Çık düğmesiyle süreç kapanışı. Arayüz testleri oyuncu ayarlarını kaydetmez.
- Her oyun 2, 3 ve 4 oyuncuyla üç farklı bot seviyesinde tamamlanıyor; durum değerleri sonlu, skor sıralaması tam.
- Tek klavye girdisi diğer oyuncunun gamepad yuvasını hareket ettirmiyor; dokunmatik parmak kimlikleri birbirinden bağımsız.
- **Dört bağımsız ENet süreci:** bir oda sahibi + üç istemci, yedi oyuna katıldı, durum paketleri alındı, tüm süreçler başarıyla çıktı. UDP kanal ayarları ve sıkıştırılmış durum aktarımı doğrulandı.
- Oyun menüsü ve yedi oyun, gerçek GPU'da render edildi ve ekran görüntüleri incelendi. Arayüz testleri ayrıca gerçek GPU ile çalıştırıldı.
- İmzalı Android APK üretildi; `apksigner verify` APK Signature v2 ve v3 doğrulamasından geçti.
- ARMv7, ARM64 ve x86_64 kütüphaneleri APK'da. Android minimum API 24 (Android 7.0). INTERNET, ACCESS_NETWORK_STATE ve VIBRATE izinleri etkin.
- PCK gömülü Windows 64 bit EXE üretildi. Yayıncı sertifikası kullanılmıyor.
- Dört üçüncü taraf varlık lisansının hem APK hem gömülü Windows paketi içinde bulunduğu doğrulandı.
- İndirme sayfası masaüstü ve 390 × 844 mobil tarayıcı görünümünde incelendi; indirme bağlantıları GitHub Releases'a gider.

## Fiziksel Xbox 360 tabanlı kontrolcü

Windows `Xbox 360 Controller`, Godot `XInput Controller` olarak algıladı. XInput yuvası 0, VID 045E / PID 028E. Sol çubuk hareketleri ve tuş değişimleri kaydedildi. Windows XInputSetState ile sol, sağ ve iki motorlu sinyaller gönderildi; kullanıcı küçük titreşimlerin geldiğini doğruladı.

Bu fiziksel test 1.0.0 geliştirilirken yapıldı. 1.1.0 menü gezinme testleri otomatik girdi olaylarıyla yapıldı; kullanıcının gamepad ile yeni menüyü denemesi ayrıca doğrulanmadı.

İlk Godot çağrılarında kullanıcı titreşim hissetmedi. Windows sürümüne, aynı XInput API'sini kullanan küçük bir yerel motor köprüsü eklendi. Klavye, dokunmatik ve gamepad girdileri Godot'ta kalır. Köprü yalnızca sınırlandırılmış motor komutlarını yerel stdin borusundan alır; ağ erişimi yoktur, oyun kapanınca motorları durdurup çıkar. EXE'ye gömülür ve çalışırken oyunun kullanıcı veri klasörüne çıkarılır. Android / XInput olmayan kontrolcüler Godot titreşim API'sini kullanır.

Üretilen 1.1.0 Windows EXE ayrıca Bomba Arenası ile çalıştırıldı: gömülü köprü açıldı ve bağlı kontrolcü algılandı. Süreç başarıyla kapandı; çalışma günlüğünde hata bulunmadı.

## Henüz doğrulanmayanlar

- Fiziksel Android telefonda APK kurulumu, dokunmatik ve Android gamepad/rumble.
- Fiziksel PS4 ve aynı anda iki farklı fiziksel gamepad. Atama ve cihaz kimliği ayrımı kodda mevcut; bağlı tek XInput kontrolcüyle donanım testi yapıldı.
- Dört ayrı fiziksel PC veya gerçek Radmin VPN üzerinden maç. Test, aynı bilgisayarda dört ayrı süreçle yapıldı.
- Farklı telefon/GPU performansı, uzun süreli bağlantı kaybı ve düşük kaliteli Wi-Fi.

Yerel loglar `qa/` ve `artifacts/` klasörlerindedir; her derlemeden sonra `SHA256SUMS.txt` yeniden üretilir. GitHub CI simülasyon, arayüz ve dört süreçli LAN testini tekrarlar.
