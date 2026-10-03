# Cep Arena 1.2.0 — doğrulama

Tarih: 3 Ekim 2026. Windows, Godot 4.7.2 stable. GPU: AMD Radeon RX 6600.

## Tamamlanan kontroller

- Godot proje içe aktarma ve GDScript derleme başarılı.
- **1470 simülasyon kontrolü, 0 başarısızlık:** 32 oyun, 2/3/4 oyuncu ve üç bot seviyesi; sonlu durum değerleri ve tam skor sıralaması, bomba kuralları, zıplama tamponu ve basılı tutarak tekrar zıplama dahil.
- **1586 mekanik/tam tur/durum paketi kontrolü, 0 başarısızlık:** 25 yeni oyunun farklı kuralları, 32 oyunun dört botla tam süreli maçları ve sıkıştırılmış durum paketlerinin 64 KiB sınırı. Dövüş kombosu ve gard, tank mermisi/kalkanı, bayrak teslimi, kısa basışla platforma ulaşma, coyote toleransı, basket, bowling, golf, hafıza ve tepki kuralları sınandı. Kontrol sayısı tekrarlanan durum denetimlerini de içerir.
- **26 arayüz kontrolü, 0 başarısızlık:** Godot'a gönderilen gamepad/klavye olaylarıyla menü odağı, kategori, arama, favoriler ve 32. oyuna erişip başlatma; A ile seçim, kaydırıcı/açılır menü, iç içe pencereler, maçtan B/Start/sistem geri ile menüye dönüş ve Çık düğmesiyle süreç kapanışı. Testler oyuncu ayarlarını kaydetmez.
- 2/3/4 oyuncu ve üç bot seviyesi kombinasyonları kısa simülasyonla; tam tur bitişi ayrıca her oyunda dört botla doğrulandı.
- Tek klavye girdisi diğer oyuncunun gamepad yuvasını hareket ettirmiyor; dokunmatik parmak kimlikleri birbirinden bağımsız.
- **Dört bağımsız ENet süreci:** bir oda sahibi + üç istemci, 32 oyuna katıldı, durum paketleri alındı, tüm süreçler başarıyla çıktı. UDP kanal ayarları ve sıkıştırılmış durum aktarımı doğrulandı.
- Menü ve 32 oyun, gerçek GPU'da render edildi; 33 ekran görüntüsü incelendi. Arayüz testleri ayrıca gerçek GPU ile çalıştırıldı.
- İmzalı Android APK üretildi; `apksigner verify` APK Signature v2 ve v3 doğrulamasından geçti.
- APK sürüm adı 1.2.0, kodu 3. ARMv7, ARM64 ve x86_64 kütüphaneleri APK'da. Minimum API 24 (Android 7.0), hedef API 36. INTERNET, ACCESS_NETWORK_STATE ve VIBRATE izinleri etkin.
- PCK gömülü Windows 64 bit EXE üretildi. Yayıncı sertifikası kullanılmıyor.
- Dokuz üçüncü taraf varlık lisansının hem APK hem gömülü Windows paketi içinde bulunduğu doğrulandı; Rubik yazı tipi lisansı ayrıca paketlenir.
- İndirme sayfası masaüstü ve 390 × 844 mobil tarayıcı görünümünde incelendi; indirme bağlantıları GitHub Releases'a gider.

## Fiziksel Xbox 360 tabanlı kontrolcü

Windows `Xbox 360 Controller`, Godot `XInput Controller` olarak algıladı. XInput yuvası 0, VID 045E / PID 028E. Sol çubuk hareketleri ve tuş değişimleri kaydedildi. Windows XInputSetState ile sol, sağ ve iki motorlu sinyaller gönderildi; kullanıcı küçük titreşimlerin geldiğini doğruladı.

Bu fiziksel test 1.0.0 geliştirilirken yapıldı. 1.2.0 menü gezinme testleri otomatik girdi olaylarıyla yapıldı; kullanıcının gamepad ile yeni menüyü denemesi ayrıca doğrulanmadı.

İlk Godot çağrılarında kullanıcı titreşim hissetmedi. Windows sürümüne, aynı XInput API'sini kullanan küçük bir yerel motor köprüsü eklendi. Klavye, dokunmatik ve gamepad girdileri Godot'ta kalır. Köprü yalnızca sınırlandırılmış motor komutlarını yerel stdin borusundan alır; ağ erişimi yoktur, oyun kapanınca motorları durdurup çıkar. EXE'ye gömülür ve çalışırken oyunun kullanıcı veri klasörüne çıkarılır. Android / XInput olmayan kontrolcüler Godot titreşim API'sini kullanır.

Üretilen 1.2.0 Windows EXE ayrıca Tank Düellosu ile çalıştırıldı: gömülü köprü açıldı, dört oyunculu maç başladı. Ses kanalları kapanıştan önce durdurulur ve mikserin aktif kaynakları bırakması beklenir; normal uygulama kapanışı başarıyla tamamlandı. Çalışma günlüğünde hata bulunmadı.

## Henüz doğrulanmayanlar

- Fiziksel Android telefonda APK kurulumu, dokunmatik ve Android gamepad/rumble.
- Fiziksel PS4 ve aynı anda iki farklı fiziksel gamepad. Atama ve cihaz kimliği ayrımı kodda mevcut; bağlı tek XInput kontrolcüyle donanım testi yapıldı.
- Dört ayrı fiziksel PC veya gerçek Radmin VPN üzerinden maç. Test, aynı bilgisayarda dört ayrı süreçle yapıldı.
- Farklı telefon/GPU performansı, uzun süreli bağlantı kaybı ve düşük kaliteli Wi-Fi.

Yerel loglar `qa/` ve `artifacts/` klasörlerindedir; her derlemeden sonra `SHA256SUMS.txt` yeniden üretilir. GitHub CI simülasyon, arcade kuralları/tam turlar, arayüz ve dört süreçli LAN testini tekrarlar.
